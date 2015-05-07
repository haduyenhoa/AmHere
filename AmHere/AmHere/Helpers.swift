//
//  Helpers.swift
//  AmHere
//
//  Created by Duyen Hoa Ha on 05/05/2015.
//  Copyright (c) 2015 Duyen-Hoa HA. All rights reserved.
//

import Foundation
import CoreBluetooth

//CBService
public let SERVICE_TRANSFER_CBUUID = CBUUID(string: "110e8400-e29b-11d4-a716-446655440000")

//CBCharacteristic
public let AVATAR_CBUUID = CBUUID(string: "110e8400-e29b-11d4-a716-446655440001")
public let USER_ID_CBUUID = CBUUID(string: "110e8400-e29b-11d4-a716-446655440002")
public let EXCHANGE_DATA_CBUUID = CBUUID(string: "110e8400-e29b-11d4-a716-446655440003") //use for delivery a chat message or an image
public let RECONNECT_CBUUID = CBUUID(string:"110e8400-e29b-11d4-a716-446655440004") //use for requesting re-connect a session
public let END_CHAT_SESSION_CBUUID = CBUUID(string:"110e8400-e29b-11d4-a716-446655440005") //use for requesting end chat session

extension CBUUID {
    func getName() -> String {
        switch (self) {
        case SERVICE_TRANSFER_CBUUID:
            return "Transfer Service"
            
        case USER_ID_CBUUID:
            return "UserID Characteristic"
            
        case AVATAR_CBUUID:
            return "Avatar Characteristic"
            
        case EXCHANGE_DATA_CBUUID:
            return "Exchange Characteristic"
        case END_CHAT_SESSION_CBUUID:
            return "End chat session Characteristic"
        case RECONNECT_CBUUID:
            return "Reconnect Characteristic"
        default:
            break
        }
        
        return self.UUIDString
    }
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
    
    func getEndChatSessionCharacteristic() -> CBCharacteristic? {
        if let _chars = self.characteristics {
            let result = _chars.filter() {
                return ($0 as! CBCharacteristic).UUID == END_CHAT_SESSION_CBUUID
            }
            return result.first as? CBCharacteristic
        }
        
        return nil
    }
    
    func getReconnectCharacteristic() -> CBCharacteristic? {
        if let _chars = self.characteristics {
            let result = _chars.filter() {
                return ($0 as! CBCharacteristic).UUID == RECONNECT_CBUUID
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