//
//  TimelineViewController.swift
//  SaladBar
//
//  Created by 1amageek on 2017/05/20.
//  Copyright © 2017年 Stamp Inc. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseStorageUI
import Salada

class TimelineViewController: UITableViewController {
    
    @IBAction func stopAction(_ sender: Any) {
        FeedGenerator.start()
    }
    
    var datasource: Datasource<SaladBar.User, SaladBar.Feed>?

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let user: User = Auth.auth().currentUser else {
            return
        }
        
//        FeedGenerator.start()
//        
//        let options: SaladaOptions = SaladaOptions()
//        options.limit = 100
//        options.ascending = false
//        
//        self.datasource = Datasource(parentKey: user.uid, referenceKey: "feeds", options: options) { [weak self] (changes) in
//            guard let tableView: UITableView = self?.tableView else { return }
//            
//            switch changes {
//            case .initial:
//                tableView.reloadData()
//            case .update(let deletions, let insertions, let modifications):
//                tableView.beginUpdates()
//                tableView.insertRows(at: insertions.map { IndexPath(row: $0, section: 0) }, with: .automatic)
//                tableView.deleteRows(at: deletions.map { IndexPath(row: $0, section: 0) }, with: .automatic)
//                tableView.reloadRows(at: modifications.map { IndexPath(row: $0, section: 0) }, with: .automatic)
//                tableView.endUpdates()
//            case .error(let error):
//                print(error)
//            }
//        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.datasource?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: FeedViewCell = tableView.dequeueReusableCell(withIdentifier: "FeedViewCell", for: indexPath) as! FeedViewCell
        configure(cell: cell, at: indexPath)
        return cell
    }
    
    func configure(cell: FeedViewCell, at indexPath: IndexPath) {
        self.datasource?.observeObject(at: indexPath.item) { (feed) in
            guard let feed: SaladBar.Feed = feed else {
                return
            }
            cell.id = feed.id
            SaladBar.User.observeSingle(feed.userID!, eventType: .value) { (user) in
                guard let user: SaladBar.User = user as? SaladBar.User else {
                    return
                }
                
                let dateFormatter: DateFormatter = DateFormatter()
                dateFormatter.dateFormat = "YYYY/M/d"
                
                cell.titleLabel.text = user.name
                cell.detailLabel.text = feed.text
                cell.dateLabel.text = dateFormatter.string(from: feed.createdAt)
                
                if let ref: StorageReference = user.profileImage?.ref {
                    cell.thumbnailImageView.sd_setImage(with: ref, placeholderImage: #imageLiteral(resourceName: "thumbnail"))
                }
            }
        }
    }
 
    override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        self.datasource?.removeObserver(at: indexPath.item)
    }

}
