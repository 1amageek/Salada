//
//  TestAppTests.swift
//  TestAppTests
//
//  Created by nori on 2017/05/29.
//  Copyright © 2017年 Stamp. All rights reserved.
//

@testable import TestApp

import Quick
import Nimble
import Firebase

class ObjectTests: QuickSpec {

    override func spec() {
        FirebaseApp.configure()
        //var objectKey: String?

        describe("hoge") { 
            it("ww", closure: { 
                expect("ww").to(equal("ww"))
            })
            let object: TestObject = TestObject()

            it("hh", closure: { 
                expect(object).toNot(beNil())
            })
        }

//        describe("TestObject Write") {
//            let object: TestObject = TestObject()
//            objectKey = object.key
//            expect(objectKey).toNot(beNil())
//            context("Write", {
//                waitUntil(action: { (done) in
//                    object.save({ (ref, error) in
//                        done()
//                        context("Read", {
//                            TestObject.observeSingle(objectKey!, eventType: .value, block: { (obj) in
//
//                                it("Bool", closure: {
//                                    expect(obj!.bool).to(equal(true))
//                                })
//
//                                it("Int", closure: {
//                                    expect(obj!.int).to(equal(Int.max))
//                                })
//
//                                it("Int8", closure: {
//                                    expect(obj!.int8).to(equal(Int8.max))
//                                })
//
//                                it("Int16", closure: {
//                                    expect(obj!.int16).to(equal(Int16.max))
//                                })
//
//                                it("Int32", closure: {
//                                    expect(obj!.int32).to(equal(Int32.max))
//                                })
//
//                                it("Int64", closure: {
//                                    expect(obj!.int64).to(equal(Int64.max))
//                                })
//
//                                it("String", closure: {
//                                    expect(obj!.string).to(equal("String"))
//                                })
//
//                                it("Strings", closure: {
//                                    expect(obj!.strings).to(equal(["String", "String"]))
//                                })
//
//                                it("velues", closure: {
//                                    expect(obj!.values).to(equal([1, 2, 3, 4]))
//                                })
//
//                                //                        it("object", closure: {
//                                //                            expect(obj!.object).to(equal(["String": "String", "Number": 0]))
//                                //                        })
//
//                                
//                                done()
//                            })
//                        })
//                    })
//                })
//            })
//        }
    }

}
