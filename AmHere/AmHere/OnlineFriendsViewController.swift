//
//  OnlineFriendsViewController.swift
//  AmHere
//
//  Created by Duyen Hoa Ha on 30/04/2015.
//  Copyright (c) 2015 Duyen-Hoa HA. All rights reserved.
//

import Foundation
import UIKit
import CoreBluetooth


class OnlineFriendsViewController : UIViewController, UITableViewDelegate, UITableViewDataSource, BLECentralManagerDelegate {
    @IBOutlet weak var tblFriends : UITableView!
 
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationItem.title = "Nearby friends"
        
        //Enable Receive
        BLECentralManager.SharedInstance().delegate = self
        BLECentralManager.SharedInstance().enableLE(true)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //Enable broadcast
        BLEPeripheralManager.SharedInstance().enableBroadcast(true)
    }
    
    //MARK: BLECentralManagerDelegate
    func peripheralsUpdated() {
        dispatch_async(dispatch_get_main_queue(), {
            //reload table view
            self.tblFriends.reloadData()
        })
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var allKeys = BLECentralManager.SharedInstance().dicPeripheral.keys.array
        return allKeys.count
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("FriendViewCell") as! UITableViewCell
        
        //update label
        var perif  = BLECentralManager.SharedInstance().dicPeripheral.values.array[indexPath.row].0
        
        if let _transferService = perif.getTransferService() {
            if let _userIdChar = _transferService.getUserIdCharacteristic() {
                (cell.viewWithTag(2) as! UILabel).text = NSString(data: _userIdChar.value, encoding: NSUTF8StringEncoding) as? String
            } else {
                //display "fetching user id"
                (cell.viewWithTag(2) as! UILabel).text = "Fetching User Id ..."
            }
        } else {
            (cell.viewWithTag(2) as! UILabel).text = "Device is disconnected ..."
        }
        
        return cell
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier?.compare("startChatRoom", options: .allZeros, range: nil, locale: nil) == .OrderedSame) {
            if let _indexPath = self.tblFriends.indexPathForSelectedRow()
            {
                let _perif = BLECentralManager.SharedInstance().dicPeripheral.values.array[_indexPath.row].0
                
                if let _transferService = _perif.getTransferService() {
                    var exC = _transferService.getExchangCharacteristic()
                    var requestChatC = _transferService.getEndChatSessionCharacteristic()
                    var userIdC = _transferService.getUserIdCharacteristic()
                    
                    if let _exC = exC, let _userIdC = userIdC {
                        var userId = NSString(data: _userIdC.value, encoding: NSUTF8StringEncoding) as? String
                        
                        if userId == nil {
                            userId = ""
                        }
                        
                        ChatSession.SharedInstance().beginChat(true, friendUserId: userId!, perif: _perif, exchangeCharacteristic: _exC)
                    } else {
                        if let _userIdC = userIdC {
                            println("Cannot find exchange characteristic or userId characteristic. Will update this later")
                            var userId = NSString(data: _userIdC.value, encoding: NSUTF8StringEncoding) as? String
                            
                            if userId == nil {
                                userId = ""
                            }
                            
                            ChatSession.SharedInstance().beginChat(true, friendUserId: userId!, perif: _perif, exchangeCharacteristic: exC)
                        }
                    }
                } else {
                    println("Cannot find transfer service. Reconnect to that peripheral now")
                    
                    //ask to reconnect to the peripheral
                    _perif.delegate = BLECentralManager.SharedInstance()
                    
                    //discovery service, 
                    //TODO: hope that all services are available when the ChatRoomViewController is displayed, else we have to wait
                    BLECentralManager.SharedInstance().bluetoothManager?.connectPeripheral(_perif, options: nil)
                }
            }
        }
    }
}