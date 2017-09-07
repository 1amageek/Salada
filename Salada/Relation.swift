//
//  Relation.swift
//  Salada
//
//  Created by 1amageek on 2017/09/04.
//  Copyright © 2017年 Stamp. All rights reserved.
//

import Foundation
import Firebase

public protocol Relationable {
    var path: String { get }
    var parent: Referenceable? { get set }
    var value: [String: Bool] { get }
    var values: [String: Any] { get }
    var package: [String: Any] { get }
}

public class Relation<T: Object>: Relationable, Collection, ExpressibleByArrayLiteral {

    public typealias ArrayLiteralElement = T

    private var _self: [T] = []

    private var _dataSource: DataSource<T> = []

    public weak var parent: Referenceable?

    public var value: [String: Bool] {
        return _self.keys.toKeys()
    }

    public var values: [String: Any] {
        return _self.values()
    }

    public var isObserved: Bool {
        return self.parent?.isObserved ?? false
    }

    public var package: [String : Any] {
        var package: [String: Any] = [:]
        self.values.forEach { (key, value) in

            // body
            do {
                let path: String = "\(T.self._path)/\(key)"
                package[path] = value
            }

            // relation
            do {

                let path: String = "\(self.path)/\(key)"
                package[path] = true
            }
        }
        return package
    }

    public var path: String {
        guard let parent: Referenceable = self.parent else {
            fatalError("[Salada.Relation] It is necessary to set parent.")
        }
        let parentType = type(of: parent)
        return "\(parentType._version)/\(parentType._modelName)-\(T.self._modelName)/\(parent.id)"
    }

    public required init(arrayLiteral elements: Relation.ArrayLiteralElement...) {
        self._self = elements
    }

    public func save() {

    }

    public var startIndex: Int {
        return _self.startIndex
    }

    public var endIndex: Int {
        return _self.endIndex
    }

    public var count: Int {
        return _self.count
    }

    public var first: T? {
        return _self.first
    }

    public subscript(i: Int) -> T {
        return _self[i]
    }

    func index(of element: T) -> Int? {
        return _self.index(of: element)
    }

    public func index(after i: Int) -> Int {
        return _self.index(after: i)
    }

    public func index(_ i: Int, offsetBy n: Int) -> Int {
        return _self.index(i, offsetBy: n)
    }

    public func index(_ i: Int, offsetBy n: Int, limitedBy limit: Int) -> Int? {
        return _self.index(i, offsetBy: n, limitedBy: limit)
    }

    public func objects(at indexes: IndexSet) -> [Element] {
        return indexes.filter { $0 < self.count }.map{ self[$0] }
    }

    // MARK: -
    public func insert(_ newMember: Element) {
        if !_self.contains(newMember) {
            _self.append(newMember)
        }
    }

    public func remove(_ member: Element) {
        if let index: Int = _self.index(of: member) {
            _self.remove(at: index)
        }
    }

    public func removeAll() {
        _self = []
    }

    // MARK: -
    public var description: String {
        if _self.isEmpty {
            return "Relation([])"
        }
        return "\(_self.description)"
    }
}

fileprivate extension Collection where Iterator.Element: Object {
    func values() -> [String: Any] {
        if self.isEmpty { return [:] }
        var values: [String: Any] = [:]
        let timestamp: [AnyHashable : Any] = ServerValue.timestamp() as [AnyHashable : Any]
        self.forEach { (object) in
            var value: [AnyHashable: Any] = object.value
            value["_createdAt"] = timestamp
            value["_updatedAt"] = timestamp
            values[object.id] = value
        }
        return values
    }
}
