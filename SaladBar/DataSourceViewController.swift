//
//  DataSourceViewController.swift
//  SaladBar
//
//  Created by 1amageek on 2016/09/23.
//  Copyright © 2016年 Stamp. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import CoreLocation

class DataSourceViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    lazy var tableView: UITableView = {
        let view: UITableView = UITableView(frame: self.view.bounds, style: .grouped)
        view.dataSource = self
        view.delegate = self
        view.alwaysBounceVertical = true
        view.register(TableViewCell.self, forCellReuseIdentifier: "TableViewCell")
        return view
    }()

    override func loadView() {
        super.loadView()
        self.view.addSubview(tableView)
    }

    var dataSource: DataSource<User>?

    var group: Group?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.rightBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(add)),
            UIBarButtonItem(title: "Prev", style: UIBarButtonItemStyle.plain, target: self, action: #selector(prev))
        ]
        self.view.backgroundColor = UIColor.white


        let group: Group = Group()
        self.group = group
        group.name = "iOS Development Team"

        (0..<10).forEach({ (index) in
            let user: User = User()
            let image: UIImage = #imageLiteral(resourceName: "salada")
            let data: Data = UIImageJPEGRepresentation(image, 1)!
            user.thumbnail = File(data: data, mimeType: .jpeg)
            user.tempName = "Test1_name"
            user.name = "\(index)"
            user.gender = "man"
            user.age = index
            user.url = URL(string: "https://www.google.co.jp/")
            user.items = ["Book", "Pen"]
            user.groups.insert(group.id)
            user.location = CLLocation(latitude: 1, longitude: 1)
            user.type = .second
            user.birth = Date()
            group.users.insert(user)
        })

        group.save { [weak self](ref, error) in
            self?.setupDataSource(key: group.id)
        }
    }

    func setupDataSource(key: String) {
        let options: SaladaOptions = SaladaOptions()
        options.limit = 10
//        options.predicate = NSPredicate(format: "age == 21")
        options.sortDescirptors = [NSSortDescriptor(key: "age", ascending: false)]

        self.dataSource = DataSource(self.group!.users.ref, options: options) { [weak self] (changes) in
            guard let tableView: UITableView = self?.tableView else { return }

            switch changes {
            case .initial:
                tableView.reloadData()
            case .update(let deletions, let insertions, let modifications):
                tableView.beginUpdates()
                tableView.insertRows(at: insertions.map { IndexPath(row: $0, section: 0) }, with: .automatic)
                tableView.deleteRows(at: deletions.map { IndexPath(row: $0, section: 0) }, with: .automatic)
                tableView.reloadRows(at: modifications.map { IndexPath(row: $0, section: 0) }, with: .automatic)
                tableView.endUpdates()
            case .error(let error):
                print(error)
            }
        }
    }

    @objc func prev() {
        self.dataSource?.prev()

    }

    @objc func add() {
        guard let group: Group = self.group else { return }
        let user: User = User()
        let image: UIImage = #imageLiteral(resourceName: "salada")
        let data: Data = UIImageJPEGRepresentation(image, 1)!
        user.thumbnail = File(data: data, mimeType: .jpeg)
        user.tempName = "Test1_name"
        user.name = "ADD"
        user.gender = "man"
        user.url = URL(string: "https://www.google.co.jp/")
        user.items = ["Book", "Pen"]
        user.groups.insert(group.id)
        user.location = CLLocation(latitude: 1, longitude: 1)
        user.type = .second
        user.birth = Date()
        group.users.insert(user)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSource?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: TableViewCell = tableView.dequeueReusableCell(withIdentifier: "TableViewCell", for: indexPath) as! TableViewCell
        configure(cell, atIndexPath: indexPath)
        return cell
    }
    
    func configure(_ cell: TableViewCell, atIndexPath indexPath: IndexPath) {
//        let user: User = self.dataSource![indexPath.item]
//        cell.imageView?.contentMode = .scaleAspectFill
//        cell.textLabel?.text = user.name
//        cell.setNeedsLayout()

        //
        cell.disposer = self.dataSource?.observeObject(at: indexPath.item, block: { (user) in
            guard let user: User = user else { return }
            cell.imageView?.contentMode = .scaleAspectFill
            cell.textLabel?.text = user.name
            cell.setNeedsLayout()
        })
    }
    
    private func tableView(_ tableView: UITableView, didEndDisplaying cell: TableViewCell, forRowAt indexPath: IndexPath) {
        //self.dataSource?.removeObserver(at: indexPath.item)
        cell.disposer?.dispose()
    }
    
    func tableView(_ tableView: UITableView, canPerformAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            self.dataSource?.removeObject(at: indexPath.item, block: { (key, error) in
                if let error: Error = error {
                    print(error)
                }
            })
        }
    }
}
