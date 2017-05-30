//
//  TestFlow.swift
//  Salada
//
//  Created by nori on 2017/05/30.
//  Copyright © 2017年 Stamp. All rights reserved.
//

import Foundation

class TestFlow: NSObject {

    var key: String!
    
    func write(block: @escaping () -> Void) {
        let object: TestObject = TestObject()
        self.key = object.key
        object.save { (ref, error) in
            block()
        }
    }

    func read(block: () -> Void) {
        TestObject.observeSingle(key, eventType: .value) { (object) in

            assert(object!.bool == true,                    "Object bool sucess")
            assert(object!.int == Int.max,                  "Object Int sucess")
            assert(object!.int8 == Int8.max,                "Object Int8 sucess")
            assert(object!.int16 == Int16.max,              "Object Int16 sucess")
            assert(object!.int32 == Int32.max,              "Object Int32 sucess")
            assert(object!.int64 == Int64.max,              "Object Int64 sucess")
            assert(object!.string == "String",              "Object String sucess")
            assert(object!.strings == ["String", "String"], "Object Strings sucess")
            assert(object!.values == [1, 2, 3, 4],          "Object Strings sucess")
            //assert(object!.object == ["String": "String", "Number": 0] as [AnyHashable, any],          "Object Strings sucess")
        }
    }

}
