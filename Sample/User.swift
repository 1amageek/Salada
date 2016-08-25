//
//  User.swift
//  Salada
//
//  Created by 1amageek on 2016/08/15.
//  Copyright © 2016年 Stamp. All rights reserved.
//

import Foundation
import CoreLocation

class User: Ingredient {
    typealias Tsp = User
    dynamic var name: String?
    dynamic var age: Int = 0
    dynamic var gender: String?
    dynamic var groups: Set<String> = []
    dynamic var items: [String] = []
    dynamic var location: CLLocation?
    dynamic var url: NSURL?
    
    var tempName: String? 
    
    override var ignore: [String] {
        return ["tempName"]
    }
    
    override func encode(key: String, value: Any) -> AnyObject? {
        
        if "location" == key {
            if let location = self.location {
                return ["latitude": location.coordinate.latitude, "longitude": location.coordinate.longitude]
            }
        }
        
        return nil
    }
    
    override func decode(key: String, value: Any) -> AnyObject? {
        
        if "location" == key {
            if let location: [String: Double] = value as? [String: Double] {
                return CLLocation(latitude: location["latitude"]!, longitude: location["longitude"]!)
            }
        }
        
        return nil
    }
    
}
