//
//  User.swift
//  Salada
//
//  Created by 1amageek on 2016/08/15.
//  Copyright © 2016年 Stamp. All rights reserved.
//

import Foundation

class User: Ingredient {
    typealias Tsp = User
    dynamic var name: String?
    dynamic var age: Int = 0
    dynamic var gender: String?
    dynamic var groups: Set<String> = []
    dynamic var items: [String] = []
    
    var tempName: String? 
    
    override var ignore: [String] {
        return ["tempName"]
    }
}
