//
//  Room.swift
//  Salada
//
//  Created by 1amageek on 2017/07/05.
//  Copyright © 2017年 Stamp. All rights reserved.
//

import Foundation

class Room: Object {

    dynamic var name: String?
    var messages: Nest<Message> = []

}
