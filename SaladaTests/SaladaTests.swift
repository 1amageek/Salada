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
    
    let timeout: TimeInterval = 100
    
    override func tearDown() {
        super.tearDown()
        
    }
    
    private static let appConfigure: () = {
        FirebaseApp.configure()
    }()
    
    
    // 保存したObjectが正確に取り出せる
    func testObjectValues() {
        
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
        object.relation.insert("set")
        
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

            Object.observeSingle(ref!.key, eventType: .value, block: { (obj) in
                
                XCTAssertNotNil(obj!.id)
                XCTAssertNotNil(obj!.createdAt)
                XCTAssertNotNil(obj!.updatedAt)

                XCTAssertEqual(obj!.string, "string")
                XCTAssertEqual(obj!.int, 0)
                XCTAssertEqual(obj!.double, 0)
                XCTAssertEqual(obj!.float, 0.1)
                
                XCTAssertEqual(obj!.relation, ["set"])
                XCTAssertEqual(obj!.array, ["array"])
                XCTAssertEqual(obj!.url?.absoluteString, "https://google.com")
                
                XCTAssertEqual(String(obj!.date!.timeIntervalSince1970), String(date.timeIntervalSince1970))
                let object: [String: String] = obj!.object as! [String: String]
                XCTAssertEqual(object, ["object": "object"])
                
                obj?.remove()
                
                expetation?.fulfill()
                
            })
            
        }
        
        self.waitForExpectations(timeout: timeout, handler: nil)
        
    }
    
    //
//    func testSalada() {
//        
//        let expetation: XCTestExpectation? = self.expectation(description: "Firebase Test Salada")
//        let parent: Parent = Parent()
//        parent.save { (ref, error) in
//            
//            _ = Salada<Parent, Child>(parentKey: ref!.key, referenceKey: "children", options: nil, block: { (changes) in
//                switch changes {
//                case .initial: break
//                case .update(_, let insertions, _):
//                    
//                    XCTAssertEqual(insertions.count, 1)
//
//                case .error(_): break
//                }
//                
//                expetation?.fulfill()
//            })
//            
//            let delay = DispatchTime.now() + .seconds(1)
//            DispatchQueue.main.asyncAfter(deadline: delay, execute: { 
//                let child: Child = Child()
//                child.name = "0"
//                child.save { (ref, error) in
//                    parent.children.insert(ref!.key)
//                }
//            })
//            
//        }
//        
//        self.waitForExpectations(timeout: timeout, handler: nil)
//    }

}
