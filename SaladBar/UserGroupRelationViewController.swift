
//
//  UserGroupRelationViewController.swift
//  SaladBar
//
//  Created by 1amageek on 2017/08/04.
//  Copyright © 2017年 Stamp. All rights reserved.
//

import UIKit

class UserGroupRelationViewController: UIViewController {

    @IBOutlet weak var groupNameTextField: UITextField!
    @IBOutlet weak var userNameTextField: UITextField!
    @IBOutlet weak var userAgeTextField: UITextField!
    @IBOutlet weak var messageLabel: UILabel!
    @IBAction func createAction(_ sender: Any) {

        guard let groupName: String = self.groupNameTextField.text else {
            self.messageLabel.text = "Input Group name"
            return
        }

        guard let userName: String = self.groupNameTextField.text else {
            self.messageLabel.text = "Input User name"
            return
        }

        let group: Group = Group()
        group.name = groupName
        let user: User = User()
        user.name = userName
        if let age: String = self.userAgeTextField.text {
            user.age = Int(age) ?? 0
        }

        // Cross reference
        group.users.insert(user.id)
        user.groups.insert(group.id)

        /*
         There are three Coding methods.
         Behavior changes in off-line
         */

        // 1.
//        group.save { (ref, error) in
//            if let error = error {
//                debugPrint(error)
//                return
//            }
//            user.save()
//        }

        // 2.
//        group.save()
//        user.save()

        // 3.
        group.transactionSave { (snapshot, error) in
            if let error = error {
                debugPrint(error)
                return
            }
            user.save()
        }

    }
}
