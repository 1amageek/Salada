//
//  Nest.swift
//  Salada
//
//  Created by 1amageek on 2017/06/29.
//  Copyright © 2017年 Stamp. All rights reserved.
//

import Foundation
import Firebase

public class Nest<T: Object>: NSObject {

    internal var snapshot: DataSnapshot?

    public typealias Index = Int

    public typealias Element = T

    /// Parent to hold the location where you want to save
    public var parent: Object?

    /// Property name to save
    public var keyPath: String?

    override init() {
        super.init()
    }

    // MARK: -

    override public var description: String {
        if _Self.isEmpty {
            return "Relation([])"
        }
        return "\(_Self.description)"
    }
}
