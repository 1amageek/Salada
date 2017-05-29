//
//  Relation.swift
//  Salada
//
//  Created by nori on 2017/05/29.
//  Copyright © 2017年 Stamp. All rights reserved.
//

import Foundation

public class Relation: NSObject, Collection, ExpressibleByArrayLiteral {

    internal var _Self: [String] = []

    public typealias Index = Int

    public typealias Element = String

    override init() {
        super.init()
    }

    public convenience init<Source : Sequence>(_ sequence: Source) where Source.Iterator.Element == Element {
        self.init()
        _Self = Array(sequence)
    }

    required convenience public init(arrayLiteral elements: Relation.Element...) {
        self.init()
        _Self = elements
    }

    public var saved: Bool = false

    public weak var owner: Object?

    public var keyPath: String?

    public var startIndex: Int {
        return _Self.startIndex
    }

    public var endIndex: Int {
        return _Self.endIndex
    }

    public var count: Int {
        return _Self.count
    }

    public var first: String? {
        return _Self.first
    }

    public subscript(i: Int) -> String {
        return _Self[i]
    }

    func index(of element: String) -> Int? {
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

    public func insert(_ newMember: Element) {
        if saved {

        } else {
            if !_Self.contains(newMember) {
                let indexes: IndexSet = IndexSet(integer: _Self.count)
                print(indexes)
                self.willChange(.insertion, valuesAt: indexes, forKey: keyPath!)
                //                    owner?.willChangeValue(forKey: keyPath!)
                _Self.append(newMember)
                //                    owner?.didChangeValue(forKey: keyPath!)
                self.didChange(.insertion, valuesAt: indexes, forKey: keyPath!)
            }
        }

    }

    public func remove(_ member: Element) {
        if saved {

        } else {
            if let index: Int = self.index(of: member) {
                _Self.remove(at: index)
            }
        }
    }

    public func removeAll() {
        if saved {

        } else {
            _Self = []
        }
    }

    public override func setValue(_ value: Any?, forKeyPath keyPath: String) {
        super.setValue(value, forKeyPath: keyPath)
    }

    public override func mutableSetValue(forKeyPath keyPath: String) -> NSMutableSet {
        let set = super.mutableSetValue(forKeyPath: keyPath)
        return set
    }

    // MARK: -

    override public var description: String {
        if _Self.isEmpty {
            return "Relation([])"
        }
        return "\(_Self.description)"
    }

}
