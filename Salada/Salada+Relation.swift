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

        required convenience public init(arrayLiteral elements: Relation.Element...) {
            self.init()
            _Self = elements
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

        }

        public func remove(_ member: Element) {
            
        }
        
        public func removeAll() {
            
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
