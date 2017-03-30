//
//  TransactionTestViewController.swift
//  Salada
//
//  Created by 1amageek on 2017/02/28.
//  Copyright © 2017年 Stamp. All rights reserved.
//

import UIKit
import Firebase

class TransactionTestViewController: UIViewController {

    var userID: String?
    var handle: UInt?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let user: User = User()
        user.tempName = "Test1_name"
        user.name = "TestUser"
        user.gender = "man"
        user.age = 30
        user.url = URL(string: "https://www.google.co.jp/")
        user.items = ["Book", "Pen"]
        user.type = .second
        user.birth = Date()
        user.save({ (ref, error) in
            if let error: Error = error {
                print(error)
                return
            }
            self.userID = ref!.key
            
            self.handle = User.observe(ref!.key, eventType: .value) { [weak self] (user) in
                guard let user: User = user as? User else {
                    return
                }
                self?.countLabel.text = String(user.testItems.count)
            }
            
        })
        
    }

    
    @IBAction func testStart(_ sender: Any) {
        
        guard let id: String = self.userID else {
            return
        }
        
        User.observeSingle(id, eventType: .value) { (user) in
            guard let user: User = user as? User else {
                return
            }
            
            (0..<500).forEach({ (index) in
                let item: Item = Item()
                item.index = index
                item.userID = user.id
                item.save({ (ref, error) in
                    if let error = error {
                        debugPrint(error)
                        return
                    }
                    print("save ", ref!.key)
                    user.testItems.insert(ref!.key)
                })
            })
            
        }
        
    }
    @IBOutlet weak var countLabel: UILabel!

    deinit {
        if let handle: UInt = self.handle {
            User.removeObserver(with: handle)
        }
    }

}
