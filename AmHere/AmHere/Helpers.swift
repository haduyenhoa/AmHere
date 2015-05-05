//
//  Helpers.swift
//  AmHere
//
//  Created by Duyen Hoa Ha on 05/05/2015.
//  Copyright (c) 2015 Duyen-Hoa HA. All rights reserved.
//

import Foundation
import CoreBluetooth

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
            
        default:
            break
        }
        
        return self.UUIDString
    }
}