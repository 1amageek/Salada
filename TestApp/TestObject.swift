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
    case set
    case relation

    static var list: [TestProperty] {
        return [.bool, .int, .int8, .int16, .int32, .int64, .string, .strings, .values, .object, .set, .relation]
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
        case .set:      return Set<String>.self
        case .relation: return Relation.self
        }
    }

    func expect(obj: ExpectObject) -> Any {
        switch self {
        case .bool:     return obj.bool
        case .int:      return obj.int
        case .int8:     return obj.int8
        case .int16:    return obj.int16
        case .int32:    return obj.int32
        case .int64:    return obj.int64
        case .string:   return obj.string
        case .strings:  return obj.strings
        case .values:   return obj.values
        case .object:   return obj.object
        case .set:      return obj.set
        case .relation: return obj.relation
        }
    }

    func value(obj: TestObject) -> String {
        switch self {
        case .bool:     return String(obj.bool)
        case .int:      return String(obj.int)
        case .int8:     return String(obj.int8)
        case .int16:    return String(obj.int16)
        case .int32:    return String(obj.int32)
        case .int64:    return String(obj.int64)
        case .string:   return obj.string
        case .strings:  return String(describing: obj.strings)
        case .values:   return String(describing: obj.values)
        case .object:   return String(describing: obj.object)
        case .set:      return String(describing: obj.set)
        case .relation: return String(describing: obj.relation)
        }
    }

    func validation(obj: TestObject, expect: ExpectObject) -> Bool {
        switch self {
        case .bool:     return expect.bool == obj.bool
        case .int:      return expect.int == obj.int
        case .int8:     return expect.int8 == obj.int8
        case .int16:    return expect.int16 == obj.int16
        case .int32:    return expect.int32 == obj.int32
        case .int64:    return expect.int64 == obj.int64
        case .string:   return expect.string == obj.string
        case .strings:  return expect.strings == obj.strings
        case .values:   return expect.values == obj.values
        case .object:
            var valid: Bool = true
            if expect.object.isEmpty, obj.object.isEmpty {
                return true
            }
            obj.object.forEach({ (key, value) in
                if let v0: Int = value as? Int, let v1: Int = expect.object[key] as? Int {
                    if v0 != v1 {
                        valid = false
                    }
                }
                if let v0: String = value as? String, let v1: String = expect.object[key] as? String {
                    if v0 != v1 {
                        valid = false
                    }
                }
            })
            return valid
        case .set: return expect.set == obj.set
        case .relation: return expect.relation == obj.relation
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
        case .set: return "Set<String>"
        case .relation: return "Relation"
        }
    }
}

class ExpectObject: NSObject {
    var bool: Bool = true
    var int: Int = Int.max
    var int8: Int8 = Int8.max
    var int16: Int16 = Int16.max
    var int32: Int32 = Int32.max
    var int64: Int64 = Int64.max
    var string: String = "String"
    var strings: [String] = ["0", "1"]
    var values: [Int] = [0, 1, 2, 3, 4]
    var object: [AnyHashable: Any] = ["String": "String", "Number": 0]
    var set: Set<String> = ["-0"]
    var relation: Relation = ["-0"]

    func reset() {
        bool = false
        int = 0
        int8 = 0
        int16 = 0
        int32 = 0
        int64 = 0
        string = ""
        strings = []
        values = []
        object = [:]
        set = []
        relation = []
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
    dynamic var strings: [String] = ["0", "1"]
    dynamic var values: [Int] = [0, 1, 2, 3, 4]
    dynamic var object: [AnyHashable: Any] = ["String": "String", "Number": 0]
    dynamic var set: Set<String> = ["-0"]
    dynamic var relation: Relation = ["-0"]

    func reset() {
        bool = false
        int = 0
        int8 = 0
        int16 = 0
        int32 = 0
        int64 = 0
        string = ""
        strings = []
        values = []
        object = [:]
        set = []
        relation = []
    }
}
