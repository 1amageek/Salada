//
//  Group.swift
//  Salada
//
//  Created by 1amageek on 2016/08/17.
//  Copyright © 2016年 Stamp. All rights reserved.
//

import Foundation

class Group: Salada.Object {
    typealias Element = Group
    dynamic var name: String?
    dynamic var users: Set<String> = []
}
