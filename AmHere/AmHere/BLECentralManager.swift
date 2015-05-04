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


extension CBPeripheral {
    /*
    Get transfer CBService of a peripheral. This function can return nul if it does not have that service or the service
    has not been discovered
    */
    func getTransferService() -> CBService? {
        if let _services = self.services {
            let result = _services.filter() {
                return ($0 as! CBService).UUID == SERVICE_TRANSFER_CBUUID
            }
            return result.first as? CBService
        }
        
        return nil
    }
    
    func isAvatarAvailable() -> Bool {
        return self.getTransferService()?.getAvatarCharacteristic() != nil
    }
    
    func isUserIdUpdated() -> Bool {
        return self.getTransferService()?.getUserIdCharacteristic()?.value != nil
    }
    
    func isExchangeCharacteristicReady() -> Bool {
        if let _char = self.getTransferService()?.getExchangCharacteristic() {
            return _char.isWritable()
        } else {
            return false
        }
    }
}

extension CBService {
    /**
    Get transfer UserId-Characteristic of a service. This function can return nul if it does not have that Characteristic or the Characteristic has not been discovered
    */
    func getUserIdCharacteristic() -> CBCharacteristic? {
        if let _chars = self.characteristics {
            let result = _chars.filter() {
                return ($0 as! CBCharacteristic).UUID == USER_ID_CBUUID
            }
            return result.first as? CBCharacteristic
        }
        
        return nil
    }
    
    func getAvatarCharacteristic() -> CBCharacteristic? {
        if let _chars = self.characteristics {
            let result = _chars.filter() {
                return ($0 as! CBCharacteristic).UUID == AVATAR_CBUUID
            }
            return result.first as? CBCharacteristic
        }
        
        return nil
    }
    
    func getExchangCharacteristic() -> CBCharacteristic? {
        if let _chars = self.characteristics {
            let result = _chars.filter() {
                return ($0 as! CBCharacteristic).UUID == EXCHANGE_DATA_CBUUID
            }
            return result.first as? CBCharacteristic
        }
        
        return nil
    }
}

extension CBCharacteristic {
    func isWritable() -> Bool {
        let result = self.properties & CBCharacteristicProperties.Write
        return result.rawValue != 0
    }
}


/**
The Receiver
*/
class BLECentralManager : NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    var bluetoothManager : CBCentralManager?
    var delegate : BLECentralManagerDelegate?

//    var currentChatCBCharacteristic : CBCharacteristic?
//    var currentExchangeDataCBCharacteristic : CBCharacteristic?
    
    var nearbyPeripherals  : [CBPeripheral]?
    var nearbyExchangeCBCharacteristic : [CBCharacteristic]?
    
//    
//    var currentCBPeripheral : CBPeripheral? //current friend in chat

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
//            var _options = [NSObject : AnyObject]()
//            _options.updateValue("identifier", forKey: CBCentralManagerOptionRestoreIdentifierKey)
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
        NSLog("\(__FUNCTION__)")

        for perif in peripherals as! [CBPeripheral] {
            NSLog("Perif: \(perif.identifier.UUIDString)")
            
            for service in perif.services as! [CBService] {
                NSLog("service : \(service.description)")
            }
        }
    }
    
    func centralManager(central: CBCentralManager!, didDiscoverPeripheral peripheral: CBPeripheral!, advertisementData: [NSObject : AnyObject]!, RSSI: NSNumber!) {
        
        var parameter = NSInteger(45)
        let dataP = NSData(bytes: &parameter, length: 1)
        
        NSLog("Discovered: \(peripheral)")
        
        let data = advertisementData[CBAdvertisementDataManufacturerDataKey] as? NSData
        let isConnectable:Bool = advertisementData["kCBAdvDataIsConnectable"] as! Bool
        
        //        currentCBPeripheral?.discoverServices([TRANSFER_SERVICE_UUID])
        
        
        //        currentCBPeripheral?.writeValue(dataP, forCharacteristic: CBCharacteristic(), type: CBCharacteristicWriteType.WithResponse)
        
        if (nearbyPeripherals == nil) {
            nearbyPeripherals = [CBPeripheral]()
        }
        
        peripheral.delegate = self
        
        
        
        let exitArrays = self.nearbyPeripherals?.filter() {
            return ($0 as CBPeripheral).identifier == peripheral.identifier
        }
        
        if exitArrays != nil && exitArrays?.count > 0 {
            println("This perif is already added \(peripheral.identifier.UUIDString)")
        } else {
            //add to nearbyPeripherals
            nearbyPeripherals?.append(peripheral)
        }
        
        self.bluetoothManager?.connectPeripheral(peripheral, options: nil)
    }
    
    func centralManager(central: CBCentralManager!, didConnectPeripheral peripheral: CBPeripheral!) {
        NSLog("Perif: \(peripheral.identifier.UUIDString)")

        peripheral.delegate = self
        peripheral.discoverServices([SERVICE_TRANSFER_CBUUID])
    }
    
    func centralManager(central: CBCentralManager!, willRestoreState dict: [NSObject : AnyObject]!) {
        NSLog("%@", dict)
    }
    
    //MARK: Peripheral
    func peripheral(peripheral: CBPeripheral!, didDiscoverIncludedServicesForService service: CBService!, error: NSError!) {
        NSLog("service : \(service.description)")
    }
    
    func peripheral(peripheral: CBPeripheral!, didDiscoverServices error: NSError!) {
        for service in peripheral.services {
            if let _service = service as? CBService {
                NSLog("service : \(_service.description)")
                peripheral.discoverCharacteristics([USER_ID_CBUUID, EXCHANGE_DATA_CBUUID, AVATAR_CBUUID], forService: _service)
                //TODO: move EXChange service to ChatRoom
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral!, didDiscoverDescriptorsForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {
        NSLog("peripheral : \(peripheral.description)")
        NSLog("characters : \(characteristic)")
    }
    
    func peripheral(peripheral: CBPeripheral!, didDiscoverCharacteristicsForService service: CBService!, error: NSError!) {
        NSLog("service : \(service.description)")
        
        for cb : CBCharacteristic in service.characteristics as! [CBCharacteristic] {
            NSLog("character : \(cb)")
            
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
        NSLog("didWriteValueForCharacteristic : \(characteristic)")
        
        if (error != nil) {
            NSLog("Error writing characteristic value: \(error.localizedDescription)")
        }
    }
    
    func peripheral(peripheral: CBPeripheral!, didUpdateValueForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {
//        NSLog("characteristic value : \(characteristic.value)")
        if let _data = characteristic.value {
            //update peripherals cause we can see name
            self.delegate?.peripheralsUpdated!()
            
//            println("Got value: \(NSString(data: _data, encoding: NSUTF8StringEncoding) as? String)) from characteristic \(characteristic.UUID.UUIDString)")
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