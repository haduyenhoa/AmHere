//
//  OnlineFriendsViewController.swift
//  AmHere
//
//  Created by Duyen Hoa Ha on 30/04/2015.
//  Copyright (c) 2015 Duyen-Hoa HA. All rights reserved.
//

import Foundation
import UIKit

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
        return 1
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCellWithIdentifier("FriendViewCell") as! UITableViewCell
    }
}