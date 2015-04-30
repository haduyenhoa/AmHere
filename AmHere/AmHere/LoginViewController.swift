//
//  LoginViewController.swift
//  AmHere
//
//  Created by Duyen Hoa Ha on 30/04/2015.
//  Copyright (c) 2015 Duyen-Hoa HA. All rights reserved.
//

import Foundation
import UIKit

class LoginViewController : UIViewController {

    @IBOutlet weak var tfUserId : UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
    }
    
    @IBAction func login(sender : NSObject) {
        if (self.tfUserId.text.isEmpty) {
            //do nothing
        } else {
            ChatSession.SharedInstance().userId = self.tfUserId.text
        }
    }
}