//
//  ViewController.swift
//  TestApp
//
//  Created by nori on 2017/05/29.
//  Copyright © 2017年 Stamp. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        TestObject.observeSingle(.value) { (tests) in
            print(tests)
        }
    }

}

