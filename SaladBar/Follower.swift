//
//  Follower.swift
//  SaladBar
//
//  Created by 1amageek on 2017/09/18.
//  Copyright © 2017年 Stamp. All rights reserved.
//

import Foundation

class Follower: Relation<User> {
    required init(arrayLiteral elements: Follower.ArrayLiteralElement...) {
        super.init(elements)
    }
}
