//
//  SimpleModelViewController.swift
//  SaladBar
//
//  Created by 1amageek on 2017/08/04.
//  Copyright © 2017年 Stamp. All rights reserved.
//

import UIKit

class SimpleModelViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

    }
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var ageTextField: UITextField!
    @IBAction func createAction(_ sender: Any) {


        guard let name: String = nameTextField.text else {
            return
        }
        let user: User = User()
        user.name = name
        if let age: String = ageTextField.text {
            user.age = Int(age) ?? 0
        }
        user.save { (ref, error) in
            if let _ = error {
                self.messageLabel.text = "Error"
                return
            }
            self.messageLabel.text = "Success! Show your firebase console"
        }
    }
    
}
