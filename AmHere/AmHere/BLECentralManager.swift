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
    func peripheralsUpdated()
    
    optional func servicesUpdated(peripheral : CBPeripheral!)
}

/**
The Receiver
*/
class BLECentralManager : NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    var bluetoothManager : CBCentralManager?
    var delegate : BLECentralManagerDelegate?

    var currentChatCBCharacteristic : CBCharacteristic?
    
    var nearbyPeripherals  : [CBPeripheral]?
    var nearbyCBServices : [CBService]?
    
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
//            var _options = [NSObject : AnyObject]()
//            _options.updateValue("identifier", forKey: CBCentralManagerOptionRestoreIdentifierKey)
            self.bluetoothManager = CBCentralManager(delegate: self, queue: nil, options:nil)
            
        } else {
            self.bluetoothManager?.stopScan()
            self.bluetoothManager?.cancelPeripheralConnection(currentCBPeripheral)
            
            self.bluetoothManager = nil
        }
    }
    
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
            self.bluetoothManager?.scanForPeripheralsWithServices([SERVICE_TRANSFER_CUUID], options: nil)
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
        currentCBPeripheral = peripheral
        
        let isConnectable:Bool = advertisementData["kCBAdvDataIsConnectable"] as! Bool
        
        //        currentCBPeripheral?.discoverServices([TRANSFER_SERVICE_UUID])
        
        
        //        currentCBPeripheral?.writeValue(dataP, forCharacteristic: CBCharacteristic(), type: CBCharacteristicWriteType.WithResponse)
        
        if (self.nearbyPeripherals == nil) {
            self.nearbyPeripherals = [CBPeripheral]()
        }
        
        peripheral.delegate = self
        
        //add to nearbyPeripherals
        self.nearbyPeripherals?.append(peripheral)
        
        self.bluetoothManager?.connectPeripheral(peripheral, options: nil)
    }
    
    func centralManager(central: CBCentralManager!, didConnectPeripheral peripheral: CBPeripheral!) {
        NSLog("Perif: \(peripheral.identifier.UUIDString)")
        
        currentCBPeripheral = peripheral
        currentCBPeripheral?.delegate = self
        currentCBPeripheral?.discoverServices([SERVICE_TRANSFER_CUUID])
    }
    
    func centralManager(central: CBCentralManager!, willRestoreState dict: [NSObject : AnyObject]!) {
        NSLog("%@", dict)
    }
    
    //MARK: Peripheral
    func peripheral(peripheral: CBPeripheral!, didDiscoverIncludedServicesForService service: CBService!, error: NSError!) {
        NSLog("service : \(service.description)")
    }
    
    func peripheral(peripheral: CBPeripheral!, didDiscoverServices error: NSError!) {
        for service in peripheral.services as! [CBService] {
            
            NSLog("service : \(service.description)")
            currentCBPeripheral?.discoverCharacteristics([USER_ID_CUUID], forService: service)
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
            if (cb.UUID == USER_ID_CUUID) {
                //request read value
                currentChatCBCharacteristic = cb;
                currentCBPeripheral?.readValueForCharacteristic(cb)
                currentCBPeripheral?.setNotifyValue(true, forCharacteristic: cb);
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
        NSLog("characteristic value : \(characteristic.value)")
        if let _data = characteristic.value {
            //update peripherals cause we can see name
            self.delegate?.peripheralsUpdated()
            
            print("Got value: \(NSString(data: _data, encoding: NSUTF8StringEncoding) as? String)) from characteristic \(characteristic.UUID.UUIDString)")
        }
    }
}