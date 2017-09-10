//
//  Package.swift
//  Salada
//
//  Created by 1amageek on 2017/09/10.
//  Copyright © 2017年 Stamp. All rights reserved.
//

import Foundation
import Firebase

public struct Package {

    public typealias Path = AnyHashable

    public typealias AnyValue = Any

    public var value: [Path: AnyValue]

    public init() {
        self.value = [:]
    }

    public init<T: Referenceable>(_ object: T) {
        self.init()
        self.add(object)
    }

    public init<T>(_ relation: Relation<T>) {
        self.init()
        self.add(relation)
    }

    public init<T, U: Referenceable>(_ relation: Relation<T>, object: U) {
        self.init()
        self.add(relation, object: object)
    }

    public mutating func add<T: Referenceable>(_ newObject: T) {
        let path: String = "\(type(of: newObject).self._path)/\(newObject.id)"
        var value: [Path: AnyValue] = self.value
        value[path] = newObject.value
        self.value = value
    }

    public mutating func add<T>(_ newRelation: Relation<T>) {
        newRelation.forEach { (object) in
            self.add(newRelation, object: object)
        }
    }

    public mutating func add<T, U: Referenceable>(_ relation: Relation<T>, object: U) {
        var value: [Path: AnyValue] = self.value
        do {
            let path: String = "\(relation.path)/\(object.id)"
            value[path] = true
        }
        do {
            let path: String = "\(type(of: object).self._path)/\(object.id)"
            value[path] = object.value
        }
        self.value = value
    }

    public mutating func merge(_ package: Package) {
        self.value.merge(package.value, uniquingKeysWith: { (_, new) -> Any in
            return new
        })
    }

    public func submit(_ block: ((DatabaseReference?, Error?) -> Void)?) {
        Database.database().reference().updateChildValues(self.value) { (error, ref) in
            block?(ref, error)
        }
    }

    public func delete(_ block: ((DatabaseReference?, Error?) -> Void)?) {
        var value: [Path: AnyValue] = [:]
        self.value.forEach { (key, _) in
            value[key] = NSNull()
        }
        Database.database().reference().updateChildValues(value) { (error, ref) in
            block?(ref, error)
        }
    }
}
