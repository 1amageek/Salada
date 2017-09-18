//
//  RelationViewController.swift
//  SaladBar
//
//  Created by 1amageek on 2017/09/07.
//  Copyright © 2017年 Stamp. All rights reserved.
//

import UIKit

class RelationViewController: UIViewController {

    @IBAction func deleteItems(_ sender: Any) {

        if let item: Item = self.items.first {
            self.user?.relationItems.remove(item)
            self.items.remove(at: 0)
        }
    }

    var user: User?
    var items: [Item] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        let user: User = User()
        self.user = user
        user.name = "aaaa"
        (0..<3).forEach { (index) in
            let item: Item = Item()
            item.index = index
            self.items.append(item)
            user.relationItems.insert(item)

            let aUser: User = User()
            aUser.name = "\(index)"
            user.followers.insert(aUser)
        }
        user.save()
    }

}
