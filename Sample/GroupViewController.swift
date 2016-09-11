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
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
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
            tableView.insertRows(at: insertions.map { IndexPath(row: $0, section: 0) }, with: .automatic)
            tableView.deleteRows(at: deletions.map { IndexPath(row: $0, section: 0) }, with: .automatic)
            tableView.reloadRows(at: modifications.map { IndexPath(row: $0, section: 0) }, with: .automatic)
            tableView.endUpdates()
        }
        
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.datasource?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
        configure(cell, atIndexPath: indexPath)
        return cell
    }
    
    func configure(_ cell: UITableViewCell, atIndexPath indexPath: IndexPath) {
        guard let group: Group = self.datasource?.objectAtIndex((indexPath as NSIndexPath).item) else { return }
        cell.imageView?.contentMode = .scaleAspectFill
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
