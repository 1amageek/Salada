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
    var values: [AnyHashable: Any] { get }
    func pack() -> Package
}

public typealias RelationalCollection = Relationable & Collection

public class Relation<T: Object>: RelationalCollection, ExpressibleByArrayLiteral {

    public typealias ArrayLiteralElement = T

    private var _self: DataSource<T>

    public weak var parent: Referenceable?

    public var values: [AnyHashable: Any] {
        return _self.values()
    }

    public var isObserved: Bool {
        return self.parent?.isObserved ?? false
    }

    public func pack() -> Package {
        return Package(self)
    }

    public var path: String {
        guard let parent: Referenceable = self.parent else {
            fatalError("[Salada.Relation] It is necessary to set parent.")
        }
        let parentType = type(of: parent)
        return "\(parentType._version)/\(parentType._modelName)-\(T.self._modelName)/\(parent.id)"
    }

    public var ref: DatabaseReference {
        return Database.database().reference().child(self.path)
    }

    public required init(arrayLiteral elements: ArrayLiteralElement...) {
        self._self = DataSource(elements)
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
        if isObserved {
            let package: Package = Package(self, object: newMember)
            package.submit(nil)
        } else {
            _self.insert(newMember)
        }
    }

    public func remove(_ member: Element) {
        if isObserved {
            let package: Package = Package(self, object: member)
            package.delete(nil)
        } else {
            _self.remove(member)
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
        return "\(_self.pool.description)"
    }
}

fileprivate extension Collection where Iterator.Element: Object {
    func values() -> [String: Any] {
        return reduce(into: [:]) { $0[$1.id] = $1.value }
    }
}
