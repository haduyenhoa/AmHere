//
//  ChatRoomViewController.swift
//  AmHere
//
//  Created by Duyen Hoa Ha on 03/05/2015.
//  Copyright (c) 2015 Duyen-Hoa HA. All rights reserved.
//

import Foundation
import UIKit

class ChatRoomViewController: JSQMessagesViewController {
    var demoData : DemoModelData?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.demoData = DemoModelData()
        
        self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeZero
        self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero
    }
    
    override func viewWillAppear(animated: Bool) {
        self.senderId = ChatSession.SharedInstance().userId
        self.senderDisplayName = "Name: " + ChatSession.SharedInstance().userId!
        
        
        super.viewWillAppear(animated)
    }
    
    //MARK JSQMessageViewController
    override func didPressSendButton(button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: NSDate!) {
        let msg = JSQMessage(senderId: senderId, displayName: senderDisplayName, text: text)
        
        self.demoData?.messages.addObject(msg)
        
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
        
        return self.demoData?.avatars[msg.senderId] as! JSQMessageAvatarImageDataSource
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageBubbleImageDataSource! {
       
        let msg = self.demoData?.messages[indexPath.row] as! JSQMessage
        
        if (msg.senderId.compare(self.senderId, options: NSStringCompareOptions.allZeros, range: nil, locale: nil) == NSComparisonResult.OrderedSame) {
            return self.demoData?.outgoingBubbleImageData
        } else {
            return self.demoData?.incomingBubbleImageData
        }
    }
    
    override func didPressAccessoryButton(sender: UIButton!) {
        //do nothing for now
    }
}