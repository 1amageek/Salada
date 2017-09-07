//
//  RelationViewController.swift
//  SaladBar
//
//  Created by 1amageek on 2017/09/07.
//  Copyright © 2017年 Stamp. All rights reserved.
//

import UIKit

class RelationViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        (0..<100).forEach { (index) in
            let user: User = User()
            let item: Item = Item()
            user.name = "aaaa"
            user.relationItems.insert(item)
            user.save()
        }
    }

}
