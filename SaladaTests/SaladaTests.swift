//
//  SaladaTests.swift
//  SaladaTests
//
//  Created by 1amageek on 2016/08/18.
//  Copyright © 2016年 Stamp. All rights reserved.
//

import Quick
import Nimble
import Firebase
import FirebaseDatabase

class SaladaTest: QuickSpec {
    

    
    override func spec() {
        
//        FIRApp.configure()
        
        describe("Salada Model Test") { 
            
            let model: TestModel = TestModel()
            
            context("Initialize model ", {
                
                it("ID is nil", closure: { 
                    expect(model.id).to(beNil())
                })
                
                it("Snapshot is nil", closure: { 
                    expect(model.snapshot).to(beNil())
                })
                
            })
            
            model.string = "String"
            model.int = Int.max
            model.uint = UInt.max
            model.double = Double.infinity
            model.float = Float.infinity
            model.array = ["item0", "item1"]
            model.dictionary = ["key": "value"]
            model.relation = ["item0"]
            
            context("Set values", {
                
                it("have a value of String", closure: {
                    expect(model.string).to(equal("String"))
                })
                
                it("have a value of Int", closure: {
                    expect(model.int).to(equal(Int.max))
                })
                
                it("have a value of UInt", closure: {
                    expect(model.uint).to(equal(UInt.max))
                })
                
                it("have a value of Double", closure: {
                    expect(model.double).to(equal(Double.infinity))
                })
                
                it("have a value of Float", closure: {
                    expect(model.float).to(equal(Float.infinity))
                })
              
                it("have a value of Array", closure: {
                    expect(model.array).to(equal(["item0", "item1"]))
                })
                
                it("have a value of Dictionary", closure: {
                    let value: String = model.dictionary["key"] as! String
                    expect(value).to(equal("value"))
                })
                
                it("have a value of Relation", closure: {
                    expect(model.relation.first!).to(equal("item0"))
                })
                
            })
            
//            context("Save values", { 
//                var savedModel: TestModel = TestModel()
//                savedModel.string = ""
//                model.save({ (error, ref) in
//                    
//                    //                context("Save values", {
//                    //
//                    //                    it("have a ID", closure: {
//                    //                        expect(model.id).toNot(beNil())
//                    //                    })
//                    //
//                    //                    it("have a Snapshot", closure: {
//                    //                        expect(model.snapshot).toNot(beNil())
//                    //                    })
//                    //
//                    //                })
//                    //
//                    //
//                    //                TestModel.observeSingle(model.id!, eventType: .Value, block: { (model) in
//                    //                    savedModel = model
//                    //                })
//                    
//                    
//                })
//                it("have a value of String", closure: { 
//                    //expect(savedModel.string).toEventually(equal("String"), timeout: 10)
//                })
//            })
         
        
        }
    }
}
