//
//  User.swift
//  Salada
//
//  Created by 1amageek on 2016/08/15.
//  Copyright © 2016年 Stamp. All rights reserved.
//

import Foundation
import CoreLocation

@objc enum UserType: Int {
    case first
    case second
}

class User: Ingredient {
    typealias Tsp = User
    dynamic var name: String?
    dynamic var age: Int = 0
    dynamic var gender: String?
    dynamic var groups: Set<String> = []
    dynamic var items: [String] = []
    dynamic var location: CLLocation?
    dynamic var url: NSURL?
    dynamic var birth: NSDate?
    dynamic var thumbnail: File?
    dynamic var type: UserType = .first
    
    var tempName: String? 
    
    override var ignore: [String] {
        return ["tempName"]
    }
    
    override func encode(key: String, value: Any) -> AnyObject? {
        
        if key == "location" {
            if let location = self.location {
                return ["latitude": location.coordinate.latitude, "longitude": location.coordinate.longitude]
            }
        } else if key == "type" {
            return self.type.rawValue
        }
        
        return nil
    }
    
    override func decode(key: String, value: Any) -> AnyObject? {
        
        if key == "location" {
            if let location: [String: Double] = value as? [String: Double] {
                return CLLocation(latitude: location["latitude"]!, longitude: location["longitude"]!)
            }
        } else if key == "type" {
            if let type: Int = value as? Int {
                self.type = UserType(rawValue: type)!
            }

        }
    
        return nil
    }
    
}
