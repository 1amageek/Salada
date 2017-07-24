//
//  Chat.swift
//  Chat
//
//  Created by 1amageek on 2017/01/31.
//  Copyright © 2017年 Stamp inc. All rights reserved.
//

import UIKit

class Chat {
    enum ContentType: Int {
        case text
        case image
    }
}

enum ChatError: Error {
    case authorization
    case network
    case database
}
