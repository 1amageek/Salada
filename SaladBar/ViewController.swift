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
    
    @IBAction func prev(_ sender: AnyObject) {
        self.datasource?.prev()
    }
    
    var groupID: String?
    
    @IBAction func add(_ sender: AnyObject) {
        if let id: String = self.groupID {
            
            Group.observeSingle(id, eventType: .value, block: { (group) in
                
                guard let group: Group = group else { return }
                
                let user: User = User()
                let image: UIImage = UIImage(named: "salada")!
                let data: Data = UIImagePNGRepresentation(image)!
                let thumbnail: File = File(name: "salada.png", data: data)
                thumbnail.data = data
                user.thumbnail = thumbnail
                user.tempName = "Test1_name"
                user.name = "Spider man"
                user.gender = "man"
                user.age = 22
                user.url = URL(string: "https://www.google.co.jp/")
                user.items = ["Book", "Pen"]
                user.groups.insert(id)
                user.location = CLLocation(latitude: 1, longitude: 1)
                user.type = .second
                user.birth = Date()
                user.save({ (error, ref) in
                    group.users.insert(ref.key)
                })
            })
            

        }
    }
    
    lazy var tableView: UITableView = {
        let view: UITableView = UITableView(frame: self.view.bounds, style: .grouped)
        view.dataSource = self
        view.delegate = self
        view.alwaysBounceVertical = true
        view.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
        return view
    }()
    
    var datasource: Salada<Group, User>?
    
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
            
            self.groupID = ref.key
            
            (0..<5).forEach({ (index) in
                let user: User = User()
                let image: UIImage = UIImage(named: "salada")!
                let data: Data = UIImagePNGRepresentation(image)!
                let thumbnail: File = File(name: "salada.png", data: data)
                thumbnail.data = data
                //user.thumbnail = thumbnail
                user.tempName = "Test1_name"
                user.name = "\(index)"
                user.gender = "man"
                user.age = index
                user.url = URL(string: "https://www.google.co.jp/")
                user.items = ["Book", "Pen"]
                user.groups.insert(ref.key)
                user.location = CLLocation(latitude: 1, longitude: 1)
                user.type = .second
                user.birth = Date()
                user.save({ (error, ref) in
                    group.users.insert(ref.key)
                    
                })
            })
            
            do {
                
                let options: SaladaOptions = SaladaOptions()
//                let sortDescriptor: NSSortDescriptor = NSSortDescriptor(key: "age", ascending: false)
//                options.sortDescriptors = [sortDescriptor]
                options.limit = 10
                
                self.datasource = Salada(parentKey: ref.key, referenceKey: "users", options: options, block: { [weak self](changes) in
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
        }
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
        self.datasource?.observeObject(at: indexPath.item, block: { (user) in
            cell.imageView?.contentMode = .scaleAspectFill
            cell.textLabel?.text = user?.name
            
            print(user?.name)
            print(user?.age)
            print(user?.birth)
            print(user?.gender)
            print(user?.url)
            print(user?.items)
            print(user?.location)
            print(user?.type)
            print(user?.groups)
            print(user?.thumbnail)
            
        })
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        guard let user: User = self.datasource?.objectAtIndex((indexPath as NSIndexPath).item) else { return }
//        let viewConntroller: GroupViewController = GroupViewController()
//        viewConntroller.userID = user.id
//        self.present(viewConntroller, animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        self.datasource?.removeObserver(at: indexPath.item)
    }
    
    func tableView(_ tableView: UITableView, canPerformAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            self.datasource?.removeObject(at: indexPath.item, cascade: true, block: { (error) in
                if let error: Error = error {
                    print(error)
                }
            })
        }
    }
}
