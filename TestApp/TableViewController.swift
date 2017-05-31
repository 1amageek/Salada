//
//  TableViewController.swift
//  Salada
//
//  Created by 1amageek on 2017/05/31.
//  Copyright © 2017年 Stamp. All rights reserved.
//

import UIKit

class TableViewController: UITableViewController {

    var key: String? {
        didSet {
            self.tableView.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Test Start", style: .plain, target: self, action: #selector(test))
    }

    func test() {
        let obj: TestObject = TestObject()
        obj.save { (ref, error) in
            self.key = ref!.key
        }
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return TestProperty.list.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: TableViewCell = tableView.dequeueReusableCell(withIdentifier: "TableViewCell", for: indexPath) as! TableViewCell
        configure(cell: cell, at: indexPath)
        return cell
    }

    func configure(cell: TableViewCell, at indexPath: IndexPath) {
        let property: TestProperty = TestProperty.list[indexPath.item]
        cell.titleLabel.text = property.toString()
        guard let key: String = self.key else {
            return
        }
        TestObject.observeSingle(key, eventType: .value) { (obj) in
            guard let obj: TestObject = obj else {
                return
            }
            cell.detailLabel.text = property.value(obj: obj)
            cell.judgmentLabel.text = property.validation(obj: obj) ? "Pass" : "Fail"
            cell.judgmentLabel.textColor = property.validation(obj: obj) ? UIColor.green : UIColor.red

        }
    }

}
