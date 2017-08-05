//
//  Group.swift
//  Salada
//
//  Created by 1amageek on 2016/08/17.
//  Copyright © 2016年 Stamp. All rights reserved.
//

import Foundation

class Group: Object {
    @objc dynamic var name: String?
    @objc dynamic var cover: File?
    @objc dynamic var users: Set<String> = []
}
