//
//  Relation.swift
//  Salada
//
//  Created by 1amageek on 2017/09/04.
//  Copyright © 2017年 Stamp. All rights reserved.
//

import FirebaseDatabase

public protocol Relationable {

    static var _version: String { get }

    static var _name: String { get }

    static var _path: String { get }

    static var database: DatabaseReference { get }

    static var databaseRef: DatabaseReference { get }

    var path: String { get }
    var keyPath: String? { get set }
    var parent: Referenceable? { get set }
    var value: [AnyHashable: Any] { get }
    var values: [AnyHashable: Any] { get }
    func setValue(_ value: Any?, forKey key: String)
    func pack() -> Package
}

public struct RelationNode {

    let id: String

    let relation: Relationable.Type

    var ref: DatabaseReference {
        return self.relation.databaseRef.child(self.id)
    }

    public init<T: Relationable>(relation: T.Type, id: String) {
        self.relation = relation
        self.id = id
    }

    public func contains(_ id: String, block: @escaping (Bool) -> Void) {
        self.ref.child(id).observeSingleEvent(of: .value) { (snapshot) in
            block(snapshot.value as? Bool ?? false)
        }
    }
}

public extension Relationable {
    static var database: DatabaseReference { return Database.database().reference() }
    static var databaseRef: DatabaseReference { return self.database.child(self._path) }
}

public extension Relationable where Self: Relationable {
    static func child(_ id: String) -> RelationNode {
        return RelationNode(relation: self, id: id)
    }
}

/**
 Relation class
 Relation works with the property of Object.
 */
open class Relation<T: Object>: Relationable, ExpressibleByArrayLiteral {

    public typealias ArrayLiteralElement = T

    open class var _version: String {
        return "v1"
    }

    open class var _name: String {
        return String(describing: Mirror(reflecting: self).subjectType).components(separatedBy: ".").first!.lowercased()
    }

    open class var _path: String {
        return "\(self._version)/\(self._name)"
    }

    internal var _self: DataSource<T>

    internal var _count: Int = 0

    /// Contains the Object holding the property.
    public weak var parent: Referenceable?

    public var keyPath: String?

    private var parentRef: DatabaseReference? {
        guard let key: String = self.keyPath else { return nil }
        return self.parent?.ref.child(key)
    }

    /// Relation detail value
    public var value: [AnyHashable: Any] {
        let count: Int = self.count
        let value: [AnyHashable: Any] = ["count": count]
        return value
    }

    /// It is an Object whose ID is Key.
    public var values: [AnyHashable: Any] {
        return _self.values()
    }

    /// You can retrieve whether the parent Object is saved.
    public var isObserved: Bool {
        return self.parent?.isObserved ?? false
    }

    public var count: Int {
        return self.isObserved ? _count : _self.count
    }

    /// Package an object to be saved in Firebase.
    public func pack() -> Package {
        var package: Package = Package(self)
        self.forEach { (object) in
            package.add(object)
        }
        return package
    }

    /// It is a Path stored in Firebase.
    public var path: String {
        guard let parent: Referenceable = self.parent else {
            fatalError("[Salada.Relation] It is necessary to set parent.")
        }
        return "\(type(of: self)._version)/\(type(of: self)._name)/\(parent.id)"
    }

    /// It is a Reference stored in Firebase.
    public var ref: DatabaseReference {
        return Database.database().reference().child(self.path)
    }

    /**
     Initialize Relation.
     */

    public init(_ elements: [ArrayLiteralElement]) {
        self._self = DataSource(elements)
    }

    public required convenience init(arrayLiteral elements: ArrayLiteralElement...) {
        self.init(elements)
    }

    private var countHandle: UInt?

    public func setValue(_ value: Any?, forKey key: String) {
        self.keyPath = key
        guard let value: [AnyHashable: Any] = value as? [AnyHashable: Any] else {
            return
        }
        if let count: Int = value["count"] as? Int {
            self._count = count
            self.countHandle = self.parent?.ref.child(key).observe(.value, with: { [weak self] (snapshot) in
                if let count: Int = snapshot.value as? Int {
                    self?._count = count
                }
            })
        }
    }

    /// Returns the Object of the specified indexes.
    public func objects(at indexes: IndexSet) -> [Element] {
        return indexes.filter { $0 < self.count }.map { self[$0] }
    }

    // MARK: -

    /// Save the new Object.
    public func insert(_ newMember: Element) {
        if isObserved {
            guard let parentRef: DatabaseReference = self.parentRef else { return }
            var package: Package = Package(self, object: newMember)
            if !newMember.isObserved {
                package.add(newMember)
            }
            package.submit({ (ref, error) in
                if let error: Error = error {
                    print(error)
                    return
                }
                parentRef.runTransactionBlock({ (data) -> TransactionResult in
                    if var relation: [AnyHashable: Any] = data.value as? [AnyHashable: Any] {
                        var count: Int = relation["count"] as? Int ?? 0
                        count += 1
                        relation["count"] = count
                        data.value = relation
                        return .success(withValue: data)
                    }
                    let relation: [AnyHashable: Any] = ["count": 1]
                    data.value = relation
                    return .success(withValue: data)
                }, andCompletionBlock: { (error, committed, snapshot) in
                    if let error: Error = error {
                        print(error)
                        return
                    }
                })
            })
        } else {
            _self.insert(newMember)
        }
    }

    /// Deletes the Object from the reference destination.
    public func remove(_ member: Element, isHard: Bool = false) {
        if isObserved {
            guard let parentRef: DatabaseReference = self.parentRef else { return }
            var package: Package = Package(self, object: member)
            if isHard {
                package.add(member)
            }
            package.delete({ (ref, error) in
                if let error: Error = error {
                    print(error)
                    return
                }
                parentRef.runTransactionBlock({ (data) -> TransactionResult in
                    if var relation: [AnyHashable: Any] = data.value as? [AnyHashable: Any] {
                        var count: Int = relation["count"] as? Int ?? 0
                        count -= 1
                        relation["count"] = count
                        data.value = relation
                        return .success(withValue: data)
                    }
                    return .success(withValue: data)
                }, andCompletionBlock: { (error, committed, snapshot) in
                    if let error: Error = error {
                        print(error)
                        return
                    }
                })
            })
        } else {
            _self.remove(member)
        }
    }

    // MARK: -

    public func contains(_ element: T, block: @escaping (Bool) -> Void) {
        self.ref.child(element.id).observeSingleEvent(of: .value) { (snapshot) in
            return block(snapshot.exists())
        }
    }

    // MARK: -

    public var description: String {
        if _self.isEmpty {
            return "Relation([])"
        }
        return "\(_self.objects.description)"
    }

    // MARK: -

    deinit {
        if let handle: UInt = self.countHandle, let key: String = self.keyPath {
            self.parent?.ref.child(key).removeObserver(withHandle: handle)
        }
    }
}

extension Relation: Collection {

    public var startIndex: Int {
        return _self.startIndex
    }

    public var endIndex: Int {
        return _self.endIndex
    }

    public var first: T? {
        return _self.first
    }

    public subscript(i: Int) -> T {
        return _self[i]
    }

    public func index(of element: T) -> Int? {
        return _self.index(of: element)
    }

    public func index(where predicate: (T) throws -> Bool) rethrows -> Int? {
        return try _self.index(where: predicate)
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
}

fileprivate extension Collection where Iterator.Element: Object {
    func values() -> [String: Any] {
        return reduce(into: [:]) { $0[$1.id] = $1.value }
    }
}

