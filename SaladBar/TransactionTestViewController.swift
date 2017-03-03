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

 
    @IBAction func testStart(_ sender: Any) {
        
        User.observeSingle("-Ke24wLDZonHR5G-s0JD", eventType: .value) { [weak self](user) in
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
            
//            (0..<500).forEach({ (index) in
//                user.testItems.insert(UUID().uuidString)
//            })
            
        }
        
    }
    @IBOutlet weak var countLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        User.observe("-Ke24wLDZonHR5G-s0JD", eventType: .value) { [weak self] (user) in
            guard let user: User = user as? User else {
                return
            }
            self?.countLabel.text = String(user.testItems.count)
        }
        
    }

}
