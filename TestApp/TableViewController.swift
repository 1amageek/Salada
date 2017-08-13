//
//  TableViewController.swift
//  Salada
//
//  Created by 1amageek on 2017/05/31.
//  Copyright © 2017年 Stamp. All rights reserved.
//

import UIKit

class TableViewController: UITableViewController {

    var handle: UInt?
    var key: String? {
        didSet {
            self.tableView.reloadData()
            if let key: String = key {
                if let handle: UInt = self.handle {
                    TestObject.removeObserver(key, with: handle)
                }
                self.handle = TestObject.observe(key, eventType: .value, block: { _ in 
                    self.tableView.reloadData()
                })
            }

        }
    }

    let expect: ExpectObject = ExpectObject()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.estimatedRowHeight = 64
        self.tableView.rowHeight = 64
        //self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Test Start", style: .plain, target: self, action: #selector(test))
    }

    func test() {
        let obj: TestObject = TestObject()
        obj.save { (ref, error) in
            self.key = ref!.key
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return TestProperty.list.count
        }
        return TestFlow.list.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Validation items"
        }
        return "Testflow"
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell: TableViewCell = tableView.dequeueReusableCell(withIdentifier: "TableViewCell", for: indexPath) as! TableViewCell
            configure(cell: cell, at: indexPath)
            return cell
        }
        let cell: ActionCell = tableView.dequeueReusableCell(withIdentifier: "ActionCell", for: indexPath) as! ActionCell
        cell.titleLabel.text = TestFlow.list[indexPath.item].toString()
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
            cell.expectLabel.text = String(describing: property.expect(obj: self.expect))
            cell.judgmentLabel.text = property.validation(obj: obj, expect: self.expect) ? "Pass" : "Fail"
            cell.judgmentLabel.textColor = property.validation(obj: obj, expect: self.expect) ? UIColor.green : UIColor.red

            let expect = self.expect
            cell.increment = {
                switch property {
                case .bool:
                    expect.bool = true
                    obj.bool = true
                case .int:
                    expect.int += 1
                    obj.int += 1
                case .int8:
                    expect.int8 += 1
                    obj.int8 += 1
                case .int16:
                    expect.int16 += 1
                    obj.int16 += 1
                case .int32:
                    expect.int32 += 1
                    obj.int32 += 1
                case .int64:
                    expect.int64 += 1
                    obj.int64 += 1
                case .string:
                    expect.string = "increment"
                    obj.string = "increment"
                case .strings:
                    expect.strings.append("increment")
                    obj.strings.append("increment")
                case .values:
                    expect.values.append(expect.values.count)
                    obj.values.append(obj.values.count)
                case .object:
                    expect.object["\(expect.object.count)"] = "\(expect.object.count)"
                    obj.object["\(obj.object.count)"] = "\(obj.object.count)"
                case .set:
                    expect.set.insert("\(expect.set.count)")
                    obj.set.insert("\(obj.set.count)")
                }
            }

            cell.decrement = {
                switch property {
                case .bool:
                    expect.bool = false
                    obj.bool = false
                case .int:
                    expect.int -= 1
                    obj.int -= 1
                case .int8:
                    expect.int8 -= 1
                    obj.int8 -= 1
                case .int16:
                    expect.int16 -= 1
                    obj.int16 -= 1
                case .int32:
                    expect.int32 -= 1
                    obj.int32 -= 1
                case .int64:
                    expect.int64 -= 1
                    obj.int64 -= 1
                case .string:
                    expect.string = "decrement"
                    obj.string = "decrement"
                case .strings:
                    if let index: Int = expect.strings.index(of: "increment") {
                         expect.strings.remove(at: index)
                    }
                    if let index: Int = obj.strings.index(of: "increment") {
                        obj.strings.remove(at: index)
                    }
                case .values:
                    expect.values.removeLast()
                    obj.values.removeLast()
                case .object:
                    expect.object.removeValue(forKey: "\(expect.object.count - 1)")
                    obj.object.removeValue(forKey: "\(obj.object.count - 1)")
                case .set:
                    expect.set.remove("\(expect.set.count - 1)")
                    obj.set.remove("\(obj.set.count - 1)")
                
                }
            }
        }
    }

    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        if indexPath.section == 0 {
            return false
        }
        return true
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer {
            tableView.deselectRow(at: indexPath, animated: true)
        }
        let testFlow: TestFlow = TestFlow.list[indexPath.item]
        switch testFlow {
        case .write_read: break
        case .update:
            self.expect.reset()
        case .delete: break
        }

        testFlow.action(key: self.key) { (key) in
            self.key = key
        }
    }

}
