//
//  Package.swift
//  Salada
//
//  Created by 1amageek on 2017/09/10.
//  Copyright © 2017年 Stamp. All rights reserved.
//

import FirebaseDatabase

/**
 Package for transferring data to Firebase
 */
public struct Package {

    public typealias Path = AnyHashable

    public typealias AnyValue = Any

    /// Transfer to Firebase body
    public var body: [Path: AnyValue]

    /// Initialize Package
    public init() {
        self.body = [:]
    }

    /// Initialize Package from Object
    public init<T: Referenceable>(_ object: T) {
        self.init()
        self.add(object)
    }

    /// Initialize Package from Relation
    public init<T>(_ relation: Relation<T>) {
        self.init()
        self.add(relation)
    }

    /// Initialize Package from Relation and Object
    public init<T, U: Referenceable>(_ relation: Relation<T>, object: U) {
        self.init()
        self.add(relation, object: object)
    }

    /// Add Object to Package.
    public mutating func add<T: Referenceable>(_ newObject: T) {
        let path: String = "\(type(of: newObject).self._path)/\(newObject.id)"
        self.add(path: path, value: newObject.value)
    }

    /// Add all Objects held by Relation to Package.
    public mutating func add<T>(_ newRelation: Relation<T>) {
        newRelation.forEach { (object) in
            self.add(newRelation, object: object)
        }
    }

    /// Add Relation and Object to Package.
    public mutating func add<T, U: Referenceable>(_ relation: Relation<T>, object: U) {
        do {
            let path: String = "\(relation.path)/\(object.id)"
            self.add(path: path, value: true)
        }
    }

    public mutating func add(path: Path, value: AnyValue) {
        var body: [Path: AnyValue] = self.body
        body[path] = value
        self.body = body
    }

    /// Merge the two packages.
    public mutating func merge(_ package: Package) {
        self.body.merge(package.body, uniquingKeysWith: { (_, new) -> Any in
            return new
        })
    }

    // MARK: -

    /// Transfer the Package's Body.
    public func submit(_ block: ((DatabaseReference?, Error?) -> Void)?) {
        Database.database().reference().updateChildValues(self.body) { (error, ref) in
            block?(ref, error)
        }
    }

    /// Delete references to Package.
    public func delete(_ block: ((DatabaseReference?, Error?) -> Void)?) {
        var body: [Path: AnyValue] = [:]
        self.body.forEach { (key, _) in
            body[key] = NSNull()
        }
        Database.database().reference().updateChildValues(body) { (error, ref) in
            block?(ref, error)
        }
    }
}
