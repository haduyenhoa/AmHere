//
//  ChatSesson.swift
//  AmHere
//
//  Created by Duyen Hoa Ha on 30/04/2015.
//  Copyright (c) 2015 Duyen-Hoa HA. All rights reserved.
//

import Foundation
import CoreBluetooth

enum ChatSessionState {
    
}

class ChatSession : NSObject {
    var userId : String?
    var sessionStarted : Bool = false
    var friendId : String?
    var isHost : Bool = false
    
    var currentPeripheral : CBPeripheral?
    var currentExchangeCharacteristic : CBCharacteristic?
    var currentAvatarCharacteristic : CBCharacteristic?
    
    class func SharedInstance() -> ChatSession {
        struct Static {
            static var instance: ChatSession? = nil
            static var onceToken: dispatch_once_t = 0
        }
        
        dispatch_once(&Static.onceToken, {
            Static.instance = ChatSession()
        })
        
        return Static.instance!
    }
    
    func beginChat(isHost : Bool, friendUserId : String, perif : CBPeripheral, exchangeCharacteristic : CBCharacteristic?) {
        self.friendId = friendUserId
        sessionStarted = true
        
        self.currentPeripheral = perif
        self.currentExchangeCharacteristic = exchangeCharacteristic
        
        NSUserDefaults.saveIncomingAvatarSetting(true)
        NSUserDefaults.saveOutgoingAvatarSetting(true)
        
        BLECentralManager.SharedInstance().bluetoothManager?.stopScan()
        
        //ask to chat, send request
        
        //send to Peripheral
        if let _cb = self.currentPeripheral?.getTransferService()?.getBeginChatSessionCharacteristic()
        {
            self.currentPeripheral!.writeValue("***BEGIN_CHAT***".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true), forCharacteristic: _cb, type: CBCharacteristicWriteType.WithResponse)
        } else {
            //TODO: refresh peripherif to get begin chat session
            println("Have to discover begin chat Characteristic again")
            self.currentPeripheral?.discoverCharacteristics([BEGIN_CHAT_SESSION_CBUUID, EXCHANGE_DATA_CBUUID], forService: self.currentPeripheral?.getTransferService())
        }
    }
    
    func stopChat() {
        sessionStarted = false
        isHost = false
    }
    
    
}