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
        let characteristics = self.characteristics.filter() {
            return  $0.UUIDString != nil && $0.UUIDString.compare(AVATAR_CBUUID.UUIDString, options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: nil) == NSComparisonResult.OrderedSame
        }
        
        return characteristics.first as? CBCharacteristic
    }
    
    func getExchangCharacteristic() -> CBCharacteristic? {
        let characteristics = self.characteristics.filter() {
            return  $0.UUIDString != nil && $0.UUIDString == EXCHANGE_DATA_CBUUID.UUIDString.uppercaseString
        }
        
        return characteristics.first as? CBCharacteristic
    }
}

extension CBCharacteristic {
    func isWritable() -> Bool {
        let result = self.properties & CBCharacteristicProperties.Write
        return result.rawValue != 0
    }
}

class OnlineFriendsViewController : UIViewController, UITableViewDelegate, UITableViewDataSource, BLECentralManagerDelegate {
    @IBOutlet weak var tblFriends : UITableView!
 
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationItem.title = "Nearby friends"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //Enable broadcast
        BLEPeripheralManager.SharedInstance().enableBroadcast(true)
        
        //Enable Receive
        BLECentralManager.SharedInstance().delegate = self
        BLECentralManager.SharedInstance().enableLE(true)
    }
    
    //MARK: BLECentralManagerDelegate
    func peripheralsUpdated() {
        dispatch_async(dispatch_get_main_queue(), {
            //reload table view
            self.tblFriends.reloadData()
        })
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return BLECentralManager.SharedInstance().nearbyPeripherals?.count ?? 0
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("FriendViewCell") as! UITableViewCell
        
        //update label
        if let _perifs = BLECentralManager.SharedInstance().nearbyPeripherals {
            let rowPerif = _perifs[indexPath.row]
            
            if let _transferService = rowPerif.getTransferService() {
                if let _userIdChar = _transferService.getUserIdCharacteristic() {
                    (cell.viewWithTag(2) as! UILabel).text = NSString(data: _userIdChar.value, encoding: NSUTF8StringEncoding) as? String
                } else {
                    //display "fetching user id"
                    (cell.viewWithTag(2) as! UILabel).text = "Fetching User Id ..."
                }
            } else {
                (cell.viewWithTag(2) as! UILabel).text = "Fetching CB Service ..."
            }
        } else {
            (cell.viewWithTag(2) as! UILabel).text = "[Peripheral disconnected]"
        }
        
        return cell
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier?.compare("startChatRoom", options: .allZeros, range: nil, locale: nil) == .OrderedSame) {
            if let _indexPath = self.tblFriends.indexPathForSelectedRow()
                , let perif = BLECentralManager.SharedInstance().nearbyPeripherals?[_indexPath.row] {
                    
                    if let _transferService = perif.getTransferService() {
                        if let _userIdChar = _transferService.getUserIdCharacteristic() {
                           ChatSession.SharedInstance().friendId = NSString(data: _userIdChar.value, encoding: NSUTF8StringEncoding) as? String
                            
                            
                        } else {
                            
                        }
                    }
            }
        }
    }
}