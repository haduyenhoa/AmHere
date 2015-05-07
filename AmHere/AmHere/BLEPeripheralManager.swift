//
//  BLEPeripheralManager.swift
//  AmHere
//
//  Created by Duyen Hoa Ha on 29/04/2015.
//  Copyright (c) 2015 Duyen Hoa Ha. All rights reserved.
//

import Foundation
import CoreBluetooth
import UIKit



@objc protocol PeripheralDelegate {
    optional func receiveMessage(msg: String!, cb : CBCharacteristic)
}

class BLEPeripheralManager : NSObject, CBPeripheralManagerDelegate {
    //private use
    var canBroadcast : Bool = false
    var isBroadcasting : Bool = false
    
    var myBTManager : CBPeripheralManager? = nil
    var delegate : PeripheralDelegate?
    
    
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
        
        let a: CGFloat = 3.141592
        let b: CGFloat = 3.141593
        
        let c : Bool  = a.distanceTo(b) < 0.0001
    }
    //MARK Peripheral Manager
    func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager!) {
        println(__FUNCTION__)
        if peripheral.state == CBPeripheralManagerState.PoweredOn {
            println("Broadcasting...")
            var transferService  = CBMutableService(type: SERVICE_TRANSFER_CBUUID, primary: true)
            
            //add characteristic
            if let _userId = ChatSession.SharedInstance().userId {
                //Create CBCharacteristics
                let userIdChar = CBMutableCharacteristic(type: USER_ID_CBUUID, properties: CBCharacteristicProperties.Read
                    , value: _userId.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true), permissions: CBAttributePermissions.Readable)
                let exchangeDataChar = CBMutableCharacteristic(type: EXCHANGE_DATA_CBUUID, properties: CBCharacteristicProperties.Write | CBCharacteristicProperties.Notify, value: nil, permissions: CBAttributePermissions.Writeable)
                let endSessionChar = CBMutableCharacteristic(type: END_CHAT_SESSION_CBUUID, properties: CBCharacteristicProperties.Write | CBCharacteristicProperties.Notify, value: nil, permissions: CBAttributePermissions.Writeable)
                let reconnectChar = CBMutableCharacteristic(type: RECONNECT_CBUUID, properties: CBCharacteristicProperties.Write | CBCharacteristicProperties.Notify, value: nil, permissions: CBAttributePermissions.Writeable)
                
                transferService.characteristics = [userIdChar, exchangeDataChar, endSessionChar, reconnectChar]
                
                self.myBTManager?.addService(transferService)
                self.myBTManager?.startAdvertising([CBAdvertisementDataServiceUUIDsKey:[SERVICE_TRANSFER_CBUUID], CBAdvertisementDataLocalNameKey : (UIApplication.sharedApplication().delegate as! AppDelegate).UUIDString])

            } else {
                //do nothing
                println("This session is not start, just do nothing")
                self.myBTManager?.stopAdvertising() //to be sure, stop advertising
            }
        } else if peripheral.state == CBPeripheralManagerState.PoweredOff {
            println("Stopped")
            self.myBTManager?.stopAdvertising()
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
        println("didReceiveWriteRequests")
        
        for _request in requests as! [CBATTRequest] {
            let msg = NSString(data: _request.value, encoding: NSUTF8StringEncoding) as! String
            
            if let _perif = _request.characteristic.service.peripheral {
                println("received request <\(msg)> from cb <\(_request.characteristic.UUID.UUIDString)>, perif <\(_perif.name)>")
            } else {
                println("received request <\(msg)> from cb <\(_request.characteristic.UUID.UUIDString)>, of unknown perif")
            }
            
            //responds to sender
            self.myBTManager?.respondToRequest(_request, withResult: CBATTError.Success)
            self.delegate?.receiveMessage?(msg, cb: _request.characteristic) //call delegate if possible
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