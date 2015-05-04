//
//  ChatRoomViewController.swift
//  AmHere
//
//  Created by Duyen Hoa Ha on 03/05/2015.
//  Copyright (c) 2015 Duyen-Hoa HA. All rights reserved.
//

import Foundation
import UIKit
import CoreBluetooth

class ChatRoomViewController: JSQMessagesViewController, PeripheralDelegate {
    var demoData : DemoModelData?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.demoData = DemoModelData()
        
        self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeMake(30.0, 30.0)
        self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeMake(30.0, 30.0)
        
        
        self.showLoadEarlierMessagesHeader = true
        
        //TEMP
        NSUserDefaults.saveIncomingAvatarSetting(true)
        NSUserDefaults.saveOutgoingAvatarSetting(true)
        
        if (ChatSession.SharedInstance().currentExchangeCharacteristic == nil) {
            //TODO: ask to wait and updating this Characteristic
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        self.senderId = ChatSession.SharedInstance().userId
//        self.senderId = "053496-4509-289"
        self.senderDisplayName = "Name: " + ChatSession.SharedInstance().userId!
        
        BLEPeripheralManager.SharedInstance().delegate = self
        
        super.viewWillAppear(animated)
    }
    
    //MARK JSQMessageViewController
    override func didPressSendButton(button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: NSDate!) {
        let msg = JSQMessage(senderId: senderId, displayName: senderDisplayName, text: text)
        
        let sendData = NSKeyedArchiver.archivedDataWithRootObject(msg)
        
        self.demoData?.messages.addObject(msg)
        
        //send to Peripheral
        if let _cb = ChatSession.SharedInstance().currentPeripheral?.getTransferService()?.getExchangCharacteristic()
        , let _peripheral = ChatSession.SharedInstance().currentPeripheral
        {
            if (_peripheral.services == nil) { //or another technic
                //alert disconnected
                let alert = UIAlertController(title: "Error", message: "Device disconnected", preferredStyle: UIAlertControllerStyle.Alert)
                let okButton = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil)
                
                alert.addAction(okButton)
                
                self.presentViewController(alert, animated: true, completion: nil)
            } else {
                _peripheral.writeValue(text.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true), forCharacteristic: _cb, type: CBCharacteristicWriteType.WithResponse)
            }
            
        }
        
        self.finishSendingMessageAnimated(true)
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageData! {
        return self.demoData?.messages[indexPath.item] as! JSQMessageData
    }
    

    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.demoData?.messages.count ?? 0
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        var cell = super.collectionView(collectionView, cellForItemAtIndexPath: indexPath) as! JSQMessagesCollectionViewCell
        //modify cell
        let msg = self.demoData?.messages[indexPath.row] as! JSQMessage
        
        if (!msg.isMediaMessage) {
            if (msg.senderId.compare(self.senderId, options: NSStringCompareOptions.allZeros, range: nil, locale: nil) == NSComparisonResult.OrderedSame) {
                cell.textView.textColor = UIColor.blackColor()
            } else {
                cell.textView.textColor = UIColor.whiteColor()
            }
            
        }
        
        //add swipe gesture
        let swipe = UISwipeGestureRecognizer(target: self, action: "handleSwipeLeft:")
        swipe.direction = UISwipeGestureRecognizerDirection.Left
        
        cell.addGestureRecognizer(swipe)
        return cell
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageAvatarImageDataSource! {
        let msg = self.demoData?.messages[indexPath.row] as! JSQMessage
        
        
        if (msg.senderId.compare(self.senderId, options: NSStringCompareOptions.allZeros, range: nil, locale: nil) == NSComparisonResult.OrderedSame) {
            if (!NSUserDefaults.outgoingAvatarSetting()) {
                return nil
            }
        } else {
            if (!NSUserDefaults.incomingAvatarSetting()) {
                return nil
            }
        }
        
        return self.demoData?.avatars?[msg.senderId] as? JSQMessageAvatarImageDataSource
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageBubbleImageDataSource! {
       
        let msg = self.demoData?.messages[indexPath.row] as! JSQMessage
        
        if (msg.senderId.compare(self.senderId, options: NSStringCompareOptions.allZeros, range: nil, locale: nil) == NSComparisonResult.OrderedSame) {
            return self.demoData?.outgoingBubbleImageData
        } else {
            return self.demoData?.incomingBubbleImageData
        }
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForMessageBubbleTopLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString! {

        let msg = self.demoData?.messages[indexPath.item] as! JSQMessage
        
//        if (indexPath.item - 1 > 0) {
//           //do not show sender id for previous message from me
//            let previousMsg = self.demoData?.messages[indexPath.item - 1] as! JSQMessage
//            if (previousMsg.senderId.compare(self.senderId, options: NSStringCompareOptions.allZeros, range: nil, locale: nil) == NSComparisonResult.OrderedSame) {
//                return nil
//            }
//        }
        
        return NSAttributedString(string: msg.senderId)
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForMessageBubbleTopLabelAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        return kJSQMessagesCollectionViewCellLabelHeightDefault
    }
    
    override func didPressAccessoryButton(sender: UIButton!) {
        //do nothing for now
    }
    
    
    
    //MARK: BLEPeripheralManager Delegate
    func receiveMessage(msg: String!) {
        let msg = JSQMessage(senderId: ChatSession.SharedInstance().friendId ?? "[Unknown]", displayName: senderDisplayName, text: msg)
        
        self.demoData?.messages.addObject(msg)
        dispatch_async(dispatch_get_main_queue(), {
            self.finishSendingMessageAnimated(true)
            }
        )
        
    }
    
    //MARK Swipe gesture
    func handleSwipeLeft(recognizer : UIGestureRecognizer) {
        println("swipe left")
    }
}