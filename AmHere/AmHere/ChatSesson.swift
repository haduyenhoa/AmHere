//
//  ChatSesson.swift
//  AmHere
//
//  Created by Duyen Hoa Ha on 30/04/2015.
//  Copyright (c) 2015 Duyen-Hoa HA. All rights reserved.
//

import Foundation

class ChatSession : NSObject {
    var userId : String?
    
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
    
    
    
}