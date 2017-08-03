//
//  Nest.swift
//  Salada
//
//  Created by 1amageek on 2017/06/29.
//  Copyright © 2017年 Stamp. All rights reserved.
//

import Foundation
import Firebase

protocol Nestable {
    var value: [AnyHashable: Any] { get }
    var owner: Object? { get set }
    var keyPath: String? { get set }
    var shouldAttachedTimestamp: Bool { get }
    init()
}

public class Nest<T: Object>: NSObject, Collection, ExpressibleByArrayLiteral, Nestable {

    public typealias Index = Int

    public typealias Element = T

    private var _Self: [Element] = []

    internal var snapshot: DataSnapshot?

    /// Parent to hold the location where you want to save
    public var owner: Object?

    /// Property name to save
    public var keyPath: String?

    public var value: [AnyHashable: Any] {
        return _Self.reduce([:], { (result, obj) -> [String: [AnyHashable: Any]] in
            var result = result
            result[obj.id] = obj.value
            return result
        })
    }

    public var shouldAttachedTimestamp: Bool {
        return true
    }

    public required override init() {
        super.init()
    }

    public convenience init<Source : Sequence>(_ sequence: Source) where Source.Iterator.Element == Element {
        self.init()
        _Self = Array(sequence)
    }

    required convenience public init(arrayLiteral elements: Nest.Element...) {
        self.init()
        _Self = elements
    }

    public var isSaved: Bool {
        return self.owner?.isObserved ?? false
    }

    public var startIndex: Int {
        return _Self.startIndex
    }

    public var endIndex: Int {
        return _Self.endIndex
    }

    public var count: Int {
        return _Self.count
    }

    public var first: Element? {
        return _Self.first
    }

    public subscript(i: Int) -> Element {
        return _Self[i]
    }

    func index(of element: Element) -> Int? {
        return _Self.index(of: element)
    }

    public func index(after i: Int) -> Int {
        return _Self.index(after: i)
    }

    public func index(_ i: Int, offsetBy n: Int) -> Int {
        return _Self.index(i, offsetBy: n)
    }

    public func index(_ i: Int, offsetBy n: Int, limitedBy limit: Int) -> Int? {
        return _Self.index(i, offsetBy: n, limitedBy: limit)
    }

    public func objects(at indexes: IndexSet) -> [Element] {
        return indexes.filter { $0 < self.count }.map{ self[$0] }
    }

    // MARK: -

    public func append(_ newMember: Element) {
        if !_Self.contains(newMember) {
            _Self.append(newMember)
        }
        if isSaved {
            guard let keyPath: String = self.keyPath else { return }
            let id: String = newMember.id
            self.owner?.updateValue(keyPath, child: id, value: newMember.value)
        }
    }

    public func remove(_ member: Element) {
        if let index: Int = _Self.index(of: member) {
            _Self.remove(at: index)
        }
    }

    public func removeAll() {
        _Self = []
    }

    // MARK: -

    override public var description: String {
        if _Self.isEmpty {
            return "Nest([])"
        }
        return "\(_Self.description)"
    }
}
