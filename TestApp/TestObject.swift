//
//  TestObject.swift
//  Salada
//
//  Created by nori on 2017/05/29.
//  Copyright © 2017年 Stamp. All rights reserved.
//

import Foundation

enum TestProperty: Int {

    case bool
    case int
    case int8
    case int16
    case int32
    case int64
    case string
    case strings
    case values
    case object

    static var list: [TestProperty] {
        return [.bool, .int, .int8, .int16, .int32, .int64, .string, .strings, .values, .object]
    }

    var type: Any.Type {
        switch self {
        case .bool:     return Bool.self
        case .int:      return Int.self
        case .int8:     return Int8.self
        case .int16:    return Int16.self
        case .int32:    return Int32.self
        case .int64:    return Int64.self
        case .string:   return String.self
        case .strings:  return [String].self
        case .values:   return [Int].self
        case .object:   return [String: Any].self
        }
    }

    var expect: Any {
        switch self {
        case .bool:     return true
        case .int:      return Int.max
        case .int8:     return Int8.max
        case .int16:    return Int16.max
        case .int32:    return Int32.max
        case .int64:    return Int64.max
        case .string:   return "String"
        case .strings:  return ["String", "String"]
        case .values:   return [1, 2, 3, 4]
        case .object:   return ["String": "String", "Number": 0]
        }
    }

    func toString() -> String {
        switch self {
        case .bool:     return "Bool"
        case .int:      return "Int"
        case .int8:     return "Int8"
        case .int16:    return "Int16"
        case .int32:    return "Int32"
        case .int64:    return "Int64"
        case .string:   return "String"
        case .strings:  return "[String]"
        case .values:   return "[Int]"
        case .object:   return "[String: Any]"
        }
    }


}

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
    dynamic var object: [String: Any] = ["String": "String", "Number": 0]

}
