//
//  BLECentralManager.swift
//  AmHere
//
//  Created by Duyen Hoa Ha on 29/04/2015.
//  Copyright (c) 2015 Duyen-Hoa HA. All rights reserved.
//

import Foundation
import CoreBluetooth

class BLECentralManager : NSObject, CBCentralManagerDelegate {
    var bluetoothManager : CBCentralManager?
    
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
    
    func startSearching() {
        var dict = [NSObject : AnyObject]()
        
        dict.updateValue("applicationId", forKey: CBPeripheralManagerOptionRestoreIdentifierKey)
        self.bluetoothManager = CBCentralManager(delegate: self, queue: nil, options: dict)
    }
    
    //MARK: central update
    func centralManagerDidUpdateState(central: CBCentralManager!) {
        //        NSLog("\(__FUNCTION__) New state: \(central.state)")
        
        switch (central.state)
        {
        case .Unsupported:
            NSLog("State: Unsupported")
            break
            
        case .Unauthorized:
            NSLog("State: Unauthorized")
            break
            
        case .PoweredOff:
            NSLog("State: Powered Off")
            break
            
        case .PoweredOn:
            NSLog("State: Powered On. Scan for bluetooth peripheral now")
            self.bluetoothManager?.scanForPeripheralsWithServices(nil , options: nil )
            break
            
        case .Unknown:
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
        NSLog("Discovered: \(peripheral)")
    }
    
    func centralManager(central: CBCentralManager!, didConnectPeripheral peripheral: CBPeripheral!) {
        NSLog("Perif: \(peripheral.identifier.UUIDString)")
        
    }
    
    func centralManager(central: CBCentralManager!, willRestoreState dict: [NSObject : AnyObject]!) {
        NSLog("willRestoreState")
    }
}