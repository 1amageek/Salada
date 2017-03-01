//
//  Item.swift
//  Salada
//
//  Created by 1amageek on 2017/02/28.
//  Copyright © 2017年 Stamp. All rights reserved.
//

import Foundation

class Item: Salada.Object {
    typealias Element = Item
    dynamic var index: Int = 0
    dynamic var userID: String?
    dynamic var file: Salada.File?
}
