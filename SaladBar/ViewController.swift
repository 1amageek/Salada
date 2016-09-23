//
//  ViewController.swift
//  SaladBar
//
//  Created by 1amageek on 2016/09/23.
//  Copyright © 2016年 Stamp. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import CoreLocation

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    lazy var tableView: UITableView = {
        let view: UITableView = UITableView(frame: self.view.bounds, style: .grouped)
        view.dataSource = self
        view.delegate = self
        view.alwaysBounceVertical = true
        view.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
        return view
    }()
    
    var datasource: Salada<User>?
    
    override func loadView() {
        super.loadView()
        self.view.addSubview(tableView)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        
        
        let group: Group = Group()
        group.name = "iOS Development Team"
        group.save { (error, ref) in
            
            do {
                let user: User = User()
                let image: UIImage = UIImage(named: "salada")!
                let data: Data = UIImagePNGRepresentation(image)!
                let thumbnail: File = File(name: "salada.png", data: data)
                thumbnail.data = data
                user.thumbnail = thumbnail
                user.tempName = "Test1_name"
                user.name = "john appleseed"
                user.gender = "man"
                user.age = 22
                user.url = URL(string: "https://www.google.co.jp/")
                user.items = ["Book", "Pen"]
                user.groups.insert(ref.key)
                user.location = CLLocation(latitude: 1, longitude: 1)
                user.type = .second
                user.birth = Date()
                user.save({ (error, ref) in
                    //                    user.name = "Iron Man"
                    //                    group.users.insert(ref.key)
                    
                    //                    let image: UIImage = UIImage(named: "Salada1")!
                    //                    let data: NSData = UIImageJPEGRepresentation(image, 1)!
                    //                    let thumbnail: File = File(name: "salada_test1.jpg", data: data)
                    //                    user.thumbnail = thumbnail
                    
                })
            }
            
            do {
                let user: User = User()
                let image: UIImage = UIImage(named: "salada")!
                let data: Data = UIImagePNGRepresentation(image)!
                let thumbnail: File = File(name: "salada_test.png", data: data)
                thumbnail.data = data
                user.thumbnail = thumbnail
                user.tempName = "Test1_name"
                user.name = "john appleseed"
                user.gender = "man"
                user.age = 22
                user.url = URL(string: "https://www.google.co.jp/")
                user.items = ["Book", "Pen"]
                user.groups.insert(ref.key)
                user.location = CLLocation(latitude: 1, longitude: 1)
                user.type = .second
                user.birth = Date()
                user.save({ (error, ref) in
                    user.name = "Iron Man"
                    group.users.insert(ref.key)
                    
                    //                    let image: UIImage = UIImage(named: "Salada1")!
                    //                    let data: NSData = UIImageJPEGRepresentation(image, 1)!
                    //                    let thumbnail: File = File(name: "salada_test1.jpg", data: data)
                    //                    user.thumbnail = thumbnail
                    
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
            tableView.insertRows(at: insertions.map { IndexPath(row: $0, section: 0) }, with: .automatic)
            tableView.deleteRows(at: deletions.map { IndexPath(row: $0, section: 0) }, with: .automatic)
            tableView.reloadRows(at: modifications.map { IndexPath(row: $0, section: 0) }, with: .automatic)
            tableView.endUpdates()
            
            })
        let sortDescriptor: NSSortDescriptor = NSSortDescriptor(key: "age", ascending: false)
        self.datasource?.sortDescriptors = [sortDescriptor]
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.datasource?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
        configure(cell, atIndexPath: indexPath)
        return cell
    }
    
    func configure(_ cell: UITableViewCell, atIndexPath indexPath: IndexPath) {
        guard let user: User = self.datasource?.objectAtIndex((indexPath as NSIndexPath).item) else { return }
        user.thumbnail?.dataWithMaxSize(1 * 1000 * 1000, completion: { (data, error) in
            if let error: NSError = error {
                print(error)
                return
            }
            cell.imageView?.image = UIImage(data: data!)
            cell.setNeedsLayout()
        })
        cell.imageView?.contentMode = .scaleAspectFill
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        guard let user: User = self.datasource?.objectAtIndex((indexPath as NSIndexPath).item) else { return }
//        let viewConntroller: GroupViewController = GroupViewController()
//        viewConntroller.userID = user.id
//        self.present(viewConntroller, animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let user: User = self.datasource?.objectAtIndex((indexPath as NSIndexPath).item) else { return }
        //user.thumbnail?.downloadTask?.cancel()
    }
    
}
