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
import CoreLocation

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    lazy var tableView: UITableView = {
        let view: UITableView = UITableView(frame: self.view.bounds, style: .Grouped)
        view.dataSource = self
        view.delegate = self
        view.alwaysBounceVertical = true
        view.registerClass(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
        return view
    }()
    
    var datasource: Salada<User>?
    
    override func loadView() {
        super.loadView()
        self.view.addSubview(tableView)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.whiteColor()
        
//        let group: Group = Group()
//        group.name = "iOS Development Team"
//        group.save { (error, ref) in
//            
//            do {
//                let user: User = User()
//                let image: UIImage = UIImage(named: "Salada")!
//                let data: NSData = UIImagePNGRepresentation(image)!
//                let thumbnail: File = File(name: "salada_test.png", data: data)
//                thumbnail.data = data
//                user.thumbnail = thumbnail
//                user.tempName = "Test1_name"
//                user.name = "john appleseed"
//                user.gender = "man"
//                user.age = 22
//                user.url = NSURL(string: "https://www.google.co.jp/")
//                user.items = ["Book", "Pen"]
//                user.groups.insert(ref.key)
//                user.location = CLLocation(latitude: 1, longitude: 1)
//                user.type = .second
//                user.birth = NSDate()
//                user.save({ (error, ref) in
//                    user.name = "Iron Man"
//                    group.users.insert(ref.key)
//                    
////                    let image: UIImage = UIImage(named: "Salada1")!
////                    let data: NSData = UIImageJPEGRepresentation(image, 1)!
////                    let thumbnail: File = File(name: "salada_test1.jpg", data: data)
////                    user.thumbnail = thumbnail
//                    
//                })
//            }
//            
////            do {
////                let user: User = User()
////                let image: UIImage = UIImage(named: "Salada")!
////                let data: NSData = UIImagePNGRepresentation(image)!
////                let thumbnail: File = File(name: "salada_test.png", data: data)
////                thumbnail.data = data
////                user.thumbnail = thumbnail
////                user.name = "Marilyn Monroe"
////                user.gender = "woman"
////                user.age = 34
////                user.url = NSURL(string: "https://www.google.co.jp/")
////                user.items = ["Rip"]
////                user.groups.insert(ref.key)
////                user.save({ (error, ref) in
////                    user.name = "Mark Zuckerberg"
////                    group.users.insert(ref.key)
////                })
////            }
//            
//        }

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
        
//        (0..<30).forEach { (index) in
//            let user: User = User()
//            user.name = "\(index)"
//            user.gender = "woman"
//            user.age = index
//            user.items = ["Rip"]
//            user.save()
//        }
        
        self.datasource = Salada.observe({ [weak self](change) in
            
            guard let tableView: UITableView = self?.tableView else { return }
            
            let deletions: [Int] = change.deletions
            let insertions: [Int] = change.insertions
            let modifications: [Int] = change.modifications
            
            tableView.beginUpdates()
            tableView.insertRowsAtIndexPaths(insertions.map { NSIndexPath(forRow: $0, inSection: 0) }, withRowAnimation: .Automatic)
            tableView.deleteRowsAtIndexPaths(deletions.map { NSIndexPath(forRow: $0, inSection: 0) }, withRowAnimation: .Automatic)
            tableView.reloadRowsAtIndexPaths(modifications.map { NSIndexPath(forRow: $0, inSection: 0) }, withRowAnimation: .Automatic)
            tableView.endUpdates()
            
        })
        let sortDescriptor: NSSortDescriptor = NSSortDescriptor(key: "age", ascending: false)
        self.datasource?.sortDescriptors = [sortDescriptor]
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.datasource?.count ?? 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier("UITableViewCell", forIndexPath: indexPath)
        configure(cell, atIndexPath: indexPath)
        return cell
    }
    
    func configure(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        guard let user: User = self.datasource?.objectAtIndex(indexPath.item) else { return }
        user.thumbnail?.dataWithMaxSize(1 * 1000 * 1000, completion: { (data, error) in
            if let error: NSError = error {
                print(error)
                return
            }
            cell.imageView?.image = UIImage(data: data!)
            cell.setNeedsLayout()
        })
        cell.imageView?.contentMode = .ScaleAspectFill
        cell.textLabel?.text = user.name
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
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        guard let user: User = self.datasource?.objectAtIndex(indexPath.item) else { return }
        let viewConntroller: GroupViewController = GroupViewController()
        viewConntroller.userID = user.id
        self.presentViewController(viewConntroller, animated: true, completion: nil)
    }
    
    func tableView(tableView: UITableView, didEndDisplayingCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        guard let user: User = self.datasource?.objectAtIndex(indexPath.item) else { return }
        //user.thumbnail?.downloadTask?.cancel()
    }
    
}
