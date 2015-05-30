//
//  BLECentralManager.swift
//  AmHere
//
//  Created by Duyen Hoa Ha on 29/04/2015.
//  Copyright (c) 2015 Duyen Hoa Ha. All rights reserved.
//

import Foundation
import CoreBluetooth

@objc protocol BLECentralManagerDelegate {
    optional func peripheralsUpdated()
    
    optional func servicesUpdated(peripheral : CBPeripheral!)
}

/**
The Receiver
*/
class BLECentralManager : NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    var bluetoothManager : CBCentralManager?
    var delegate : BLECentralManagerDelegate?

//    var currentChatCBCharacteristic : CBCharacteristic?
//    var currentExchangeDataCBCharacteristic : CBCharacteristic?
    
    var dicPeripheral = [String : (CBPeripheral, [NSObject : AnyObject])]()
    
//    var nearbyPeripherals  : [CBPeripheral]?
    var nearbyExchangeCBCharacteristic : [CBCharacteristic]?
    
//    
    var currentCBPeripheral : CBPeripheral? //current friend in chat

    class func SharedInstance() -> BLECentralManager {
        struct Static {
            static var instance: BLECentralManager? = nil
            static var onceToken: dispatch_once_t = 0
        }
        
        dispatch_once(&Static.onceToken, {
            Static.instance = BLECentralManager()
        })
        
        return Static.instance!
    }
    
    func enableLE(shouldEnable : Bool) {
        if (shouldEnable) {
            var _options = [NSObject : AnyObject]()
            _options.updateValue("identifier", forKey: CBCentralManagerOptionRestoreIdentifierKey)
            self.bluetoothManager = CBCentralManager(delegate: self, queue: nil, options:nil)
            
        } else {
            self.bluetoothManager?.stopScan()
            
            //TODO: logout current session
            
            
            //then, cancel currentCBPeripheral
            self.bluetoothManager?.cancelPeripheralConnection(ChatSession.SharedInstance().currentPeripheral)
            
            self.bluetoothManager = nil
        }
    }
    
//    func nearbyFriends() -> [CBPeripheral] {
//        return _nearbyPeripherals
//    }
    
    //MARK: Central Manager
    func centralManagerDidUpdateState(central: CBCentralManager!) {
        //        NSLog("\(__FUNCTION__) New state: \(central.state)")
        
        switch (central.state)
        {
        case CBCentralManagerState.Unsupported:
            NSLog("State: Unsupported")
            break
            
        case CBCentralManagerState.Unauthorized:
            NSLog("State: Unauthorized")
            break
            
        case CBCentralManagerState.PoweredOff:
            NSLog("State: Powered Off")
            break
            
        case CBCentralManagerState.PoweredOn:
            NSLog("State: Powered On. Start scanning peripherals")
            self.bluetoothManager?.scanForPeripheralsWithServices([SERVICE_TRANSFER_CBUUID], options: nil)
            break
            
        case CBCentralManagerState.Unknown:
            NSLog("State: Unknown")
            break
            
        default:
            
            break
        }
    }
    
    func centralManager(central: CBCentralManager!, didRetrievePeripherals peripherals: [AnyObject]!) {
        println("\(__FUNCTION__)")
        println("didRetrievePeripherals")
//
//        for perif in peripherals as! [CBPeripheral] {
//            println("Perif: \(perif.identifier.UUIDString)")
//            
//            for service in perif.services as! [CBService] {
//                println("service : \(service.description)")
//            }
//        }
    }
    
    func centralManager(central: CBCentralManager!, didDiscoverPeripheral peripheral: CBPeripheral!, advertisementData: [NSObject : AnyObject]!, RSSI: NSNumber!) {
        
        println("\(__FUNCTION__): Discovered: \(peripheral)")

        let isConnectable:Bool = advertisementData[CBAdvertisementDataIsConnectable] as! Bool
        
        let generatedDeviceUUIDIdentifier = advertisementData[CBAdvertisementDataLocalNameKey] as? String
        
        println("Generated Device UUID: \(generatedDeviceUUIDIdentifier)")
        
        let exitArrays = dicPeripheral.values.array.filter() {
            var advData = $0.1 as [NSObject : AnyObject]
            return advData[CBAdvertisementDataLocalNameKey] as? String == generatedDeviceUUIDIdentifier
        }
        
        if exitArrays.count > 0 {
            println("This perif is already added \(peripheral.identifier.UUIDString)")
            
            //disconnect then reconnect?
        } else {
            if let _deviceUUID = generatedDeviceUUIDIdentifier {
                peripheral.delegate = self
                

                println("Add/update for vendor : \(_deviceUUID)")
                dicPeripheral.updateValue((peripheral, advertisementData), forKey: _deviceUUID)
                
                //discovery service
                self.bluetoothManager?.connectPeripheral(peripheral, options: nil)
            } else {
                
            }
        }
    }
    
    func centralManager(central: CBCentralManager!, didConnectPeripheral peripheral: CBPeripheral!) {
        println("\(__FUNCTION__):Perif: \(peripheral.identifier.UUIDString)")

        peripheral.delegate = self
        peripheral.discoverServices([SERVICE_TRANSFER_CBUUID])
    }
    
    func centralManager(central: CBCentralManager!, willRestoreState dict: [NSObject : AnyObject]!) {
        println("\(__FUNCTION__):%@", dict)
    }
    
    //MARK: Peripheral
    func peripheral(peripheral: CBPeripheral!, didDiscoverIncludedServicesForService service: CBService!, error: NSError!) {
        println("\(__FUNCTION__): service : \(service.description)")
    }
    
    func peripheral(peripheral: CBPeripheral!, didDiscoverServices error: NSError!) {
        for service in peripheral.services {
            if let _service = service as? CBService {
                NSLog("service : \(_service.UUID.getName())")
                peripheral.discoverCharacteristics([USER_ID_CBUUID, EXCHANGE_DATA_CBUUID, AVATAR_CBUUID, END_CHAT_SESSION_CBUUID, RECONNECT_CBUUID,BEGIN_CHAT_SESSION_CBUUID], forService: _service)
                //TODO: move EXChange service to ChatRoom
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral!, didDiscoverDescriptorsForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {
        println("\(__FUNCTION__)")
        
//        NSLog("peripheral : \(peripheral.description)")
//        NSLog("characters : \(characteristic)")
    }
    
    func peripheral(peripheral: CBPeripheral!, didDiscoverCharacteristicsForService service: CBService!, error: NSError!) {
        println("\(__FUNCTION__)")
//        NSLog("service : \(service.description)")
        
        for cb : CBCharacteristic in service.characteristics as! [CBCharacteristic] {
            println("character : \(cb.UUID.getName())")
            
            //detect if writable if want to write
            if (cb.UUID == USER_ID_CBUUID) {
                //request read value
//                currentChatCBCharacteristic = cb;
                peripheral.readValueForCharacteristic(cb)
                peripheral.setNotifyValue(true, forCharacteristic: cb);
            } else if (cb.UUID == EXCHANGE_DATA_CBUUID) {
//                currentExchangeDataCBCharacteristic = cb;
                if (self.nearbyExchangeCBCharacteristic == nil) {
                    self.nearbyExchangeCBCharacteristic = [CBCharacteristic]()
                }
                
//                self.nearbyExchangeCBCharacteristic?.removeAtIndex(find(self.nearbyExchangeCBCharacteristic, cb))
                self.nearbyExchangeCBCharacteristic?.append(cb)
//                self.nearbyExchangeCBCharacteristic = uniq(self.nearbyExchangeCBCharacteristic)
                
                peripheral.setNotifyValue(true, forCharacteristic: cb)
            } else if (cb.UUID == AVATAR_CBUUID) {
                //updated avatar
                println("avatar updated")
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral!, didWriteValueForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {
        println("\(__FUNCTION__): didWriteValueForCharacteristic")
        
        if characteristic.UUID == BEGIN_CHAT_SESSION_CBUUID
            && error == nil {
                //can begin chat session now
                println("Can begin chat room now")
        }
        
        if (error != nil) {
            NSLog("Error writing characteristic value: \(error.localizedDescription)")
        }
    }
    
    func peripheral(peripheral: CBPeripheral!, didUpdateValueForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {
//        NSLog("characteristic value : \(characteristic.value)")
        if let _data = characteristic.value {
            //update peripherals cause we can see name
            self.delegate?.peripheralsUpdated!()
        }
    }
    
    //MARK Helpers
    func updateAvatar(perif : CBPeripheral) {
        if let _cbService = perif.getTransferService() {
            perif.discoverCharacteristics([AVATAR_CBUUID], forService: _cbService)
        } else {
            println("this perif does not have transfer service to get avatar characteristicf")
        }
        
    }
    
    func updateExchangeService(perif : CBPeripheral) {
        if let _cbService = perif.getTransferService() {
            perif.discoverCharacteristics([EXCHANGE_DATA_CBUUID], forService: _cbService)
        } else {
            println("this perif does not have transfer service to start exchange characteristic")
        }
    }
    
    func uniq<S : SequenceType, T : Hashable where S.Generator.Element == T>(source: S) -> [T] {
        var buffer = [T]()
        var added = Set<T>()
        for elem in source {
            if !added.contains(elem) {
                buffer.append(elem)
                added.insert(elem)
            }
        }
        return buffer
    }
}