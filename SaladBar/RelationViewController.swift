//
//  RelationViewController.swift
//  SaladBar
//
//  Created by 1amageek on 2017/09/07.
//  Copyright © 2017年 Stamp. All rights reserved.
//

import UIKit

class RelationViewController: UIViewController {

    var user: User?

    var checkUser: User?

    @IBAction func containsAction(_ sender: Any) {
        Follower.child(self.user!.id).contains(checkUser!.id) { (contain) in
            print(contain)
        }
    }

    @IBAction func removeAction(_ sender: Any) {
        self.user?.followers.remove(self.checkUser!)
    }
    
    @IBAction func followAction(_ sender: Any) {
        let aUser: User = User()
        aUser.name = "followUser"
        self.user?.followers.insert(aUser)
    }
    override func viewDidLoad() {
        super.viewDidLoad()

//        User.observeSingle("-KuT1SNcNRFvXm345001", eventType: .value) { (user) in
//            self.user = user
//        }

        let user: User = User()
        self.user = user
        user.name = "aaaa"
        (0..<3).forEach { (index) in
            let aUser: User = User()
            self.checkUser = aUser
            aUser.name = "\(index)"
            user.followers.insert(aUser)
        }
        user.save()
    }

}
