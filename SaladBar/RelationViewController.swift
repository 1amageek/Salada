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

        let user: User = User()

        user.name = "aaaa"
        (0..<10).forEach { (index) in
            let item: Item = Item()
            item.index = index
            user.relationItems.insert(item)
        }
        user.save()
    }

}
