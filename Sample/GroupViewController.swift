//
//  GroupViewController.swift
//  Salada
//
//  Created by 1amageek on 2016/09/01.
//  Copyright © 2016年 Stamp. All rights reserved.
//

import UIKit

class GroupViewController: UITableViewController {

    var userID: String!
    var datasource: Salada<Group>?
    
    override func loadView() {
        super.loadView()
        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print(self.userID)
        self.datasource = Salada.observe(with: User.databaseRef.child(userID).child("groups")) { [weak self] (change) in
            guard let tableView: UITableView = self?.tableView else { return }
            
            let deletions: [Int] = change.deletions
            let insertions: [Int] = change.insertions
            let modifications: [Int] = change.modifications
            
            tableView.beginUpdates()
            tableView.insertRowsAtIndexPaths(insertions.map { NSIndexPath(forRow: $0, inSection: 0) }, withRowAnimation: .Automatic)
            tableView.deleteRowsAtIndexPaths(deletions.map { NSIndexPath(forRow: $0, inSection: 0) }, withRowAnimation: .Automatic)
            tableView.reloadRowsAtIndexPaths(modifications.map { NSIndexPath(forRow: $0, inSection: 0) }, withRowAnimation: .Automatic)
            tableView.endUpdates()
        }
        
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.datasource?.count ?? 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier("UITableViewCell", forIndexPath: indexPath)
        configure(cell, atIndexPath: indexPath)
        return cell
    }
    
    func configure(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        guard let group: Group = self.datasource?.objectAtIndex(indexPath.item) else { return }
        cell.imageView?.contentMode = .ScaleAspectFill
        cell.textLabel?.text = group.name
        //        print(user.tempName)
        //        print(user.thumbnail)
        //        print(user.tempName)
        //        print(user.name)
        //        print(user.gender)
        //        print(user.age)
        //        print(user.url)
        //        print(user.items)
        //        print(user.groups)
        //        print(user.location)
        //        print(user.type)
        //        print(user.birth)
    }
    
}
