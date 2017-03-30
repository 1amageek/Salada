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

class User: Salada.Object {
    
    typealias Element = User
    
    override class var _version: String {
        return "v1"
    }
    
    dynamic var name: String?
    dynamic var age: Int = 0
    dynamic var gender: String?
    dynamic var groups: Set<String> = []
    dynamic var items: [String] = []
    dynamic var location: CLLocation?
    dynamic var url: URL?
    dynamic var birth: Date?
    dynamic var thumbnail: Salada.File?
    dynamic var cover: Salada.File?
    dynamic var type: UserType = .first
    dynamic var testItems: Set<String> = []
    
    var tempName: String? 
    
    override var ignore: [String] {
        return ["tempName"]
    }
    
    override func encode(_ key: String, value: Any?) -> Any? {
        if key == "location" {
            if let location = self.location {
                return ["latitude": location.coordinate.latitude, "longitude": location.coordinate.longitude]
            }
        } else if key == "type" {
            return self.type.rawValue as AnyObject?
        }
        return nil
    }
    
    override func decode(_ key: String, value: Any?) -> Any? {
        if key == "location" {
            if let location: [String: Double] = value as? [String: Double] {
                self.location = CLLocation(latitude: location["latitude"]!, longitude: location["longitude"]!)
                return self.location
            }
        } else if key == "type" {
            if let type: Int = value as? Int {
                self.type = UserType(rawValue: type)!
                return self.type
            }
        }
        return nil
    }
}
