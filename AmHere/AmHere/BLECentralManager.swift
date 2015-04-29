//
//  BLECentralAgent.swift
//  AmHere
//
//  Created by Duyen Hoa Ha on 29/04/2015.
//  Copyright (c) 2015 Duyen Hoa Ha. All rights reserved.
//

import Foundation
import CoreBluetooth

protocol LEBluetoothManagerDelegate {
    func peripheralsUpdated()
    func servicesUpdated(peripheral : CBPeripheral!)
}

class BLECentralManager : NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    var bluetoothManager : CBCentralManager?
    var delegate : LEBluetoothManagerDelegate?
    var currentCBPeripheral : CBPeripheral?
    let TRANSFER_SERVICE_UUID = CBUUID(string: "110e8400-e29b-11d4-a716-446655440000")
    let CB_CHARACTERISTIC = CBUUID(string: "110e8400-e29b-11d4-a716-446655440001")
    
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
            self.bluetoothManager = CBCentralManager(delegate: self, queue: nil, options:_options)
            
        } else {
            self.bluetoothManager?.stopScan()
            self.bluetoothManager?.cancelPeripheralConnection(currentCBPeripheral)
            
            self.bluetoothManager = nil
        }
    }
    
    
    //MARK: Core Bluetooth
    func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager!) {
        NSLog("\(__FUNCTION__)")
        
        
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
            self.bluetoothManager?.scanForPeripheralsWithServices([TRANSFER_SERVICE_UUID], options: nil)
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
        currentCBPeripheral?.delegate = self
        let isConnectable:Bool = advertisementData["kCBAdvDataIsConnectable"] as! Bool
        
        //        currentCBPeripheral?.discoverServices([TRANSFER_SERVICE_UUID])
        
        
        //        currentCBPeripheral?.writeValue(dataP, forCharacteristic: CBCharacteristic(), type: CBCharacteristicWriteType.WithResponse)
        
        self.bluetoothManager?.connectPeripheral(peripheral, options: nil)
    }
    
    func centralManager(central: CBCentralManager!, didConnectPeripheral peripheral: CBPeripheral!) {
        NSLog("Perif: \(peripheral.identifier.UUIDString)")
        
        currentCBPeripheral = peripheral
        currentCBPeripheral?.delegate = self
        currentCBPeripheral?.discoverServices([TRANSFER_SERVICE_UUID])
        
        
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
            currentCBPeripheral?.discoverCharacteristics([CB_CHARACTERISTIC], forService: service)
        }
    }
    
    func peripheral(peripheral: CBPeripheral!, didDiscoverDescriptorsForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {
        NSLog("peripheral : \(peripheral.description)")
        NSLog("characters : \(characteristic)")
        
        
        
        
    }
    
    func peripheral(peripheral: CBPeripheral!, didDiscoverCharacteristicsForService service: CBService!, error: NSError!) {
        NSLog("service : \(service.description)")
        NSLog("characters : \(service.characteristics)")
        
        if let _first = service.characteristics.first as? CBCharacteristic {
            var parameter = "Hello, My name is Hoa"
            let dataP = parameter.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
            
            currentCBPeripheral?.writeValue(dataP, forCharacteristic: _first, type: CBCharacteristicWriteType.WithResponse)
            
            //            currentCBPeripheral?.readValueForCharacteristic(_first)
        }
    }
    
    func peripheral(peripheral: CBPeripheral!, didWriteValueForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {
        NSLog("didWriteValueForCharacteristic : \(characteristic)")
        
        if (error != nil) {
            NSLog("Error writing characteristic value: \(error.localizedDescription)")
        }
    }
    
    func peripheral(peripheral: CBPeripheral!, didUpdateValueForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {
        
        NSLog("descriptors : \(characteristic.properties)")
        
        
        if let descriptors = characteristic.descriptors {
            NSLog("descriptors : \(descriptors)")
        }
        
        NSLog("characteristic value : \(characteristic.value)")
    }
    
    
    
    
}