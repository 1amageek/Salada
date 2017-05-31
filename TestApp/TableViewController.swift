//
//  TableViewController.swift
//  Salada
//
//  Created by 1amageek on 2017/05/31.
//  Copyright © 2017年 Stamp. All rights reserved.
//

import UIKit

class TableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

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
    }

}
