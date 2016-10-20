//
//  SaladaTests.swift
//  SaladaTests
//
//  Created by 1amageek on 2016/10/18.
//  Copyright © 2016年 Stamp. All rights reserved.
//

import XCTest
import Firebase
import FirebaseDatabase
import FirebaseStorage

class SaladaTests: XCTestCase {
    
    
    func testObjectValues() {
        
        FIRApp.configure()
        
        let date: Date = Date()
        
        let expetation: XCTestExpectation? = self.expectation(description: "Firebase object")
        let object: Object = Object()
        
        // String
        object.string = "string"
        
        // Number
        object.int = 0
        object.double = 0
        object.float = 0.1
        
        // Relation
        object.relation.insert("relation")
        
        // Array
        object.array.append("array")
        
        // URL
        object.url = URL(string: "https://google.com")
        
        // Date
        object.date = date
        
        // Object
        object.object = ["object": "object"]
        
        object.save { (ref, error) in
            
            XCTAssertNil(error)
            XCTAssertNotNil(ref)

            Object.observeSingle(ref.key, eventType: .value, block: { (obj) in
                
                XCTAssertEqual(obj!.string, "string")
                XCTAssertEqual(obj!.int, 0)
                XCTAssertEqual(obj!.double, 0)
                XCTAssertEqual(obj!.float, 0.1)
                
                XCTAssertEqual(obj!.relation, ["relation"])
                XCTAssertEqual(obj!.array, ["array"])
                XCTAssertEqual(obj!.url?.absoluteString, "https://google.com")
                
                XCTAssertEqual(obj!.date, date)
                let object: [String: String] = obj!.object as! [String: String]
                XCTAssertEqual(object, ["object": "object"])
                
            })
            
            expetation?.fulfill()
        }
        
        self.waitForExpectations(timeout: 1000, handler: nil)
        
    }
    

}
