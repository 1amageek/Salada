//
//  Salada+Relation.swift
//  Salada
//
//  Created by 1amageek on 2017/01/05.
//  Copyright © 2017年 Stamp. All rights reserved.
//

import Foundation
import Firebase

extension Salada {

    open class Relation: NSObject, Collection, ExpressibleByArrayLiteral {

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

        public weak var owner: Salada.Object?
        
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

        // MARK: -

        public func insert(_ newMember: Element) {
            

            if saved {
                
            } else {
                if !_Self.contains(newMember) {
                    _Self.append(newMember)
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
        
        // MARK: -
        
        override open var description: String {
            if _Self.isEmpty {
                return "Relation([])"
            }
            return "\(_Self.description)"
        }
        
    }
    
}
