//
//  BLEPeripheralManager.swift
//  AmHere
//
//  Created by Duyen Hoa Ha on 29/04/2015.
//  Copyright (c) 2015 Duyen-Hoa HA. All rights reserved.
//

import Foundation
import CoreBluetooth


class BLEPeripheralManager : NSObject, CBPeripheralManagerDelegate {
    
    var bluetoothManager : CBPeripheralManager?

    class func SharedInstance() -> BLEPeripheralManager {
        struct Static {
            static var instance: BLEPeripheralManager? = nil
            static var onceToken: dispatch_once_t = 0
        }
        
        dispatch_once(&Static.onceToken, {
            Static.instance = BLEPeripheralManager()
        })
        
        return Static.instance!
    }
    

    /*
        enable advertising to notify bluetooth service
    */
    func enableAdvertising() {
        var dict = [NSObject : AnyObject]()
        
        self.bluetoothManager = CBPeripheralManager(delegate: self, queue: nil, options:dict)
    }
    
    
    //MARK: Peripheral Manager Delegate
    func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager!) {
        switch (peripheral.state)
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
            NSLog("State: Powered On, Start Advertising now")
            self.bluetoothManager?.startAdvertising(nil);
            break
            
        case .Unknown:
            NSLog("State: Unknown")
            break
            
        default:
            
            break
        }
    }
}