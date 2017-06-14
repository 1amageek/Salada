//
//  Relation.swift
//  Salada
//
//  Created by nori on 2017/05/29.
//  Copyright © 2017年 Stamp. All rights reserved.
//

import Foundation
import Firebase

public class Relation: NSObject, Collection, ExpressibleByArrayLiteral {

    private var _Self: [String] = []

    internal var snapshot: DataSnapshot?

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
        if !_Self.contains(newMember) {


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

    // MARK: -

    override public var description: String {
        if _Self.isEmpty {
            return "Relation([])"
        }
        return "\(_Self.description)"
    }
}
