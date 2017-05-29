//
//  TestObject.swift
//  Salada
//
//  Created by nori on 2017/05/29.
//  Copyright © 2017年 Stamp. All rights reserved.
//

import Foundation

class TestObject: Object {

    dynamic var bool: Bool = true
    dynamic var int: Int = Int.max
    dynamic var int8: Int8 = Int8.max
    dynamic var int16: Int16 = Int16.max
    dynamic var int32: Int32 = Int32.max
    dynamic var int64: Int64 = Int64.max
    dynamic var string: String = "String"
    dynamic var strings: [String] = ["String", "String"]
    dynamic var values: [Int] = [1, 2, 3, 4]
    dynamic var object: [AnyHashable: Any] = ["String": "String", "Number": 0]

}
