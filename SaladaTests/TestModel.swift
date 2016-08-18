//
//  TestModel.swift
//  Salada
//
//  Created by 1amageek on 2016/08/18.
//  Copyright © 2016年 Stamp. All rights reserved.
//

import Foundation

class TestModel: Ingredient {
    typealias Tsp = TestModel
    dynamic var string: String?
    dynamic var int: Int = 0
    dynamic var uint: UInt = 0
    dynamic var double: Double = 0
    dynamic var float: Float = 0
    dynamic var relation: Set<String> = []
    dynamic var array: [String] = []
    dynamic var dictionary: [String: AnyObject] = [:]
}