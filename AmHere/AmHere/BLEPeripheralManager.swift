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


public let SERVICE_TRANSFER_CBUUID = CBUUID(string: "110e8400-e29b-11d4-a716-446655440000")

public let AVATAR_CBUUID = CBUUID(string: "110e8400-e29b-11d4-a716-446655440001")
public let USER_ID_CBUUID = CBUUID(string: "110e8400-e29b-11d4-a716-446655440002")
public let EXCHANGE_DATA_CBUUID = CBUUID(string: "110e8400-e29b-11d4-a716-446655440003") //use for delivery a chat message or an image

@objc protocol PeripheralDelegate {
    optional func receiveMessage(msg: String!)
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
    }
    //MARK Peripheral Manager
    func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager!) {
        println(__FUNCTION__)
        if peripheral.state == CBPeripheralManagerState.PoweredOn {
            println("Broadcasting...")
            var transferService  = CBMutableService(type: SERVICE_TRANSFER_CBUUID, primary: true)
            
            //add characteristic
            if let _userId = ChatSession.SharedInstance().userId{
                let userIdChar = CBMutableCharacteristic(type: USER_ID_CBUUID, properties: CBCharacteristicProperties.Read
                    , value: _userId.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true), permissions: CBAttributePermissions.Readable)
                let exchangeDataChar = CBMutableCharacteristic(type: EXCHANGE_DATA_CBUUID, properties: CBCharacteristicProperties.Write | CBCharacteristicProperties.Notify
                    , value: nil, permissions: CBAttributePermissions.Writeable)
                
                transferService.characteristics = [userIdChar, exchangeDataChar]
                
                self.myBTManager?.addService(transferService)
                self.myBTManager?.startAdvertising([CBAdvertisementDataServiceUUIDsKey:[SERVICE_TRANSFER_CBUUID]])

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
        println("didReceiveWriteRequests: \(requests)")
        
        if let _request = requests as? [CBATTRequest] where _request.count > 0, let aR = requests[0] as? CBATTRequest {
            let msg = NSString(data: aR.value, encoding: NSUTF8StringEncoding) as! String
            
            println("Received: \(msg)")

            self.delegate?.receiveMessage?(msg) //call delegate if possible
            
//            var localNotification = UILocalNotification()
//            localNotification.fireDate = NSDate()
//            localNotification.alertBody = "Hey, you must go shopping, remember?"
//            localNotification.alertAction = "View List"
//            
//            UIApplication.sharedApplication().scheduleLocalNotification(localNotification)
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