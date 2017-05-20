//
//  SaladBar+Feed.swift
//  SaladBar
//
//  Created by 1amageek on 2017/05/20.
//  Copyright © 2017年 Stamp Inc. All rights reserved.
//

import Foundation
import Firebase
import FirebaseAuth
import Salada

extension SaladBar {
    class Feed: Salada.Object {
        
        typealias Element = Feed
        
        dynamic var userID: String?
        
        dynamic var text: String?
        
        dynamic var contentImage: Salada.File?
        
    }
}
