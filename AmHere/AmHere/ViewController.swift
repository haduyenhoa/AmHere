//
//  ViewController.swift
//  AmHere
//
//  Created by Duyen Hoa Ha on 29/04/2015.
//  Copyright (c) 2015 Duyen-Hoa HA. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var swBroadcast: UISwitch!
    @IBOutlet weak var swReceiver: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func enableService(sender: AnyObject) {
        if (sender as! NSObject == self.swBroadcast) {
            BLEPeripheralManager.SharedInstance().enableBroadcast(self.swBroadcast.on)
        } else {
            BLECentralManager.SharedInstance().enableLE(self.swReceiver.on)
        }
    }


}

