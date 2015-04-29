//
//  BLEPeripheralManager.swift
//  AmHere
//
//  Created by Duyen Hoa Ha on 29/04/2015.
//  Copyright (c) 2015 Duyen Hoa Ha. All rights reserved.
//

import Foundation
import CoreBluetooth
class BLEPeripheralManager : NSObject, CBPeripheralManagerDelegate {
    //private use
    var canBroadcast : Bool = false
    var isBroadcasting : Bool = false
    
    var myBTManager : CBPeripheralManager? = nil
    
    let TRANSFER_SERVICE_UUID = CBUUID(string: "110e8400-e29b-11d4-a716-446655440000")
    let CB_CHARACTERISTIC = CBUUID(string: "110e8400-e29b-11d4-a716-446655440001")
    
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
    
    override init() {
        //create boardcast reagion &
        super.init()
    }
    //MARK Peripheral Manager
    func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager!) {
        println(__FUNCTION__)
        if peripheral.state == CBPeripheralManagerState.PoweredOn {
            println("Broadcasting...")
            var transferService  = CBMutableService(type: TRANSFER_SERVICE_UUID, primary: true)
            
            var myCharacterristic = CBMutableCharacteristic(type: CB_CHARACTERISTIC, properties: CBCharacteristicProperties.Write | CBCharacteristicProperties.Notify, value: nil, permissions: CBAttributePermissions.Writeable)
            transferService.characteristics = [myCharacterristic]
            
            self.myBTManager?.addService(transferService)
            self.myBTManager?.startAdvertising([CBAdvertisementDataServiceUUIDsKey:[TRANSFER_SERVICE_UUID]]
            )
            
        } else if peripheral.state == CBPeripheralManagerState.PoweredOff {
            println("Stopped")
            
            myBTManager!.stopAdvertising()
        } else if peripheral.state == CBPeripheralManagerState.Unsupported {
            println("Unsupported")
        } else if peripheral.state == CBPeripheralManagerState.Unauthorized {
            println("This option is not allowed by your application")
        }
    }
    
    func peripheralManager(peripheral: CBPeripheralManager!, willRestoreState dict: [NSObject : AnyObject]!) {
        println("willRestoreState")
    }
    
    func peripheralManager(peripheral: CBPeripheralManager!, didReceiveReadRequest request: CBATTRequest!) {
        println("didReceiveReadRequest")
    }
    
    func peripheralManager(peripheral: CBPeripheralManager!, didReceiveWriteRequests requests: [AnyObject]!) {
        println("didReceiveWriteRequests: \(requests)")
        
        if let _request = requests as? [CBATTRequest] where _request.count > 0, let aR = requests[0] as? CBATTRequest {
            let msg = NSString(data: aR.value, encoding: NSUTF8StringEncoding) as! String
            println("Received: \(msg)")
        }
    }
    
    //public function
    func enableBroadcast(shouldEnabled:Bool) {
        if (shouldEnabled) {
            self.myBTManager = CBPeripheralManager(delegate: self, queue: nil, options: nil)
        } else {
            self.myBTManager?.stopAdvertising()
            self.myBTManager = nil
        }
        
    }
}