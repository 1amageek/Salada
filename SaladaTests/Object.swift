//
//  Object.swift
//  Salada
//
//  Created by 1amageek on 2016/10/18.
//  Copyright © 2016年 Stamp. All rights reserved.
//

import Foundation

class Object: Ingredient {
    
    typealias Tsp = Object
    
    // String
    dynamic var string:     String?
    
    // Number
    dynamic var int:        Int = 0
    dynamic var double:     Double = 0
    dynamic var float:      Float = 0
    
    // Relation
    dynamic var relation:   Set<String> = []
    
    // Array
    dynamic var array:      [String] = []
    
    // URL
    dynamic var url:        URL?
    
    // Date
    dynamic var date:       Date?
    
    // Object
    dynamic var object:     [String: Any] = [:]
}
