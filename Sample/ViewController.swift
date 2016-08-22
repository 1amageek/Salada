//
//  ViewController.swift
//  Salada
//
//  Created by 1amageek on 2016/08/15.
//  Copyright © 2016年 Stamp. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    lazy var tableView: UITableView = {
        let view: UITableView = UITableView(frame: self.view.bounds, style: .Grouped)
        view.dataSource = self
        view.delegate = self
        view.registerClass(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
        return view
    }()
    
    var salada: Salada<User>?
    
    override func loadView() {
        super.loadView()
        self.view.addSubview(tableView)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.whiteColor()
        let group: Group = Group()
        group.name = "iOS Development Team"
        group.save { (error, ref) in
            
            do {
                let user: User = User()
                user.name = "john appleseed"
                user.gender = "man"
                user.age = 22
                user.items = ["Book", "Pen"]
                user.groups.insert(ref.key)
                user.save({ (error, ref) in
                    group.users.insert(ref.key)
                })
            }
            
            do {
                let user: User = User()
                user.name = "Marilyn Monroe"
                user.gender = "woman"
                user.age = 34
                user.items = ["Rip"]
                user.groups.insert(ref.key)
                user.save({ (error, ref) in
                    group.users.insert(ref.key)
                })
            }
            
        }

//        User.observeSingle(FIRDataEventType.Value) { (results) in
//            results.forEach({ (user) in
//                print(user.description)
//                print(user.age)
//                print(user.name)
//                print(user.gender)
//                print(user.groups)
//                print(user.items)
//                
//                if let groupId: String = user.groups.first {
//                    Group.observeSingle(groupId, eventType: .Value, block: { (group) in
//                        print(group)
//                        //group.remove()
//                    })
//                }
//                //user.remove()
//            })
//        }
        
        
        self.salada = Salada.observe({ [weak self](change) in
            
            guard let tableView: UITableView = self?.tableView else { return }
            
            switch change {
            case .Initial: tableView.reloadData()
            case .Update(let deletions, let insertions, let modifications):
//                tableView.beginUpdates()
//                tableView.insertRowsAtIndexPaths(insertions.map { NSIndexPath(forRow: $0, inSection: 0) }, withRowAnimation: .Automatic)
//                tableView.deleteRowsAtIndexPaths(deletions.map { NSIndexPath(forRow: $0, inSection: 0) }, withRowAnimation: .Automatic)
//                tableView.reloadRowsAtIndexPaths(modifications.map { NSIndexPath(forRow: $0, inSection: 0) }, withRowAnimation: .Automatic)
//                tableView.endUpdates()
                break
            }
            
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.salada?.count ?? 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier("UITableViewCell", forIndexPath: indexPath)
        configure(cell, atIndexPath: indexPath)
        return cell
    }
    
    func configure(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        guard let user: User = self.salada?.objectAtIndex(indexPath.item) else { return }
        cell.textLabel?.text = user.name
    }
    
}


