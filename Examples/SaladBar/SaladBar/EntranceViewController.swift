//
//  EntranceViewController.swift
//  SaladBar
//
//  Created by 1amageek on 2017/05/20.
//  Copyright © 2017年 Stamp Inc. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth

class EntranceViewController: UIViewController {

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBAction func start(_ sender: Any) {
        self.activityIndicator.startAnimating()
        Auth.auth().signInAnonymously { [unowned self](user, error) in
            defer {
                self.activityIndicator.stopAnimating()
            }
            if let error = error {
                debugPrint(error)
                return
            }
            
            let me: SaladBar.User = SaladBar.User(id: user!.uid)!
            me.name = UIDevice.current.name
            NotificationCenter.default.post(name: .AuthStateDidChange, object: nil)
        }
    }
}
