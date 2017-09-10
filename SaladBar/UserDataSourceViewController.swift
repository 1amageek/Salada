//
//  UserDataSourceViewController.swift
//  SaladBar
//
//  Created by 1amageek on 2017/09/03.
//  Copyright © 2017年 Stamp. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import CoreLocation

class UserDataSourceViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    lazy var tableView: UITableView = {
        let view: UITableView = UITableView(frame: self.view.bounds, style: .grouped)
        view.dataSource = self
        view.delegate = self
        view.alwaysBounceVertical = true
        view.register(TableViewCell.self, forCellReuseIdentifier: "TableViewCell")
        return view
    }()

    var datasource: DataSource<User>?

    override func loadView() {
        super.loadView()
        self.view.addSubview(tableView)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.rightBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(add)),
            UIBarButtonItem(title: "Prev", style: UIBarButtonItemStyle.plain, target: self, action: #selector(prev))
        ]
        self.view.backgroundColor = UIColor.white
        let options: SaladaOptions = SaladaOptions()
        options.limit = 10
        options.sortDescirptors = [NSSortDescriptor(key: "age", ascending: false)]
        self.datasource = DataSource(User.databaseRef, options: options, block: { [weak self](changes) in
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
        })

    }

    @objc func prev() {
        self.datasource?.prev()
    }

    @objc func add() {
//        guard let key: String = self.groupKey else {
//            return
//        }
//        Group.observeSingle(key, eventType: .value) { (group) in
//            guard let group: Group = group else { return }
//            let user: User = User()
//            let image: UIImage = #imageLiteral(resourceName: "salada")
//            let data: Data = UIImageJPEGRepresentation(image, 1)!
//            user.thumbnail = File(data: data, mimeType: .jpeg)
//            user.tempName = "Test1_name"
//            user.name = "ADD"
//            user.gender = "man"
//            user.url = URL(string: "https://www.google.co.jp/")
//            user.items = ["Book", "Pen"]
//            user.groups.insert(key)
//            user.location = CLLocation(latitude: 1, longitude: 1)
//            user.type = .second
//            user.birth = Date()
//            user.save({ (ref, error) in
//                if let error: Error = error {
//                    print(error)
//                    return
//                }
//                group.users.insert(ref!.key)
//            })
//        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.datasource?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: TableViewCell = tableView.dequeueReusableCell(withIdentifier: "TableViewCell", for: indexPath) as! TableViewCell
        configure(cell, atIndexPath: indexPath)
        return cell
    }

    func configure(_ cell: TableViewCell, atIndexPath indexPath: IndexPath) {
        cell.disposer = self.datasource?.observeObject(at: indexPath.item, block: { (user) in
            guard let user: User = user else { return }
            cell.imageView?.contentMode = .scaleAspectFill
            cell.textLabel?.text = user.name
            cell.setNeedsLayout()
        })
    }

    private func tableView(_ tableView: UITableView, didEndDisplaying cell: TableViewCell, forRowAt indexPath: IndexPath) {
        cell.disposer?.dispose()
    }

    func tableView(_ tableView: UITableView, canPerformAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            self.datasource?.removeObject(at: indexPath.item, block: { (key, error) in
                if let error: Error = error {
                    print(error)
                }
            })
        }
    }
}
