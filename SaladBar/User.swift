//
//  User.swift
//  Salada
//
//  Created by 1amageek on 2016/08/15.
//  Copyright © 2016年 Stamp. All rights reserved.
//

import Foundation
import CoreLocation


class User: Object {
    
    override class var _version: String {
        return "v1"
    }
    
    @objc dynamic var name: String?
    @objc dynamic var age: Int = 0
    @objc dynamic var gender: String?
    @objc dynamic var groups: Set<String> = []
    @objc dynamic var items: [String] = []
    @objc dynamic var location: CLLocation?
    @objc dynamic var url: URL?
    @objc dynamic var birth: Date?
    @objc dynamic var thumbnail: File?
    @objc dynamic var cover: File?
    @objc dynamic var type: UserType = .first
    @objc dynamic var testItems: Set<String> = []
    let followers: Follower = []
    
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
