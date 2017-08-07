//
//  TestFlow.swift
//  Salada
//
//  Created by nori on 2017/05/30.
//  Copyright © 2017年 Stamp. All rights reserved.
//

import Foundation

enum TestFlow: Int {
    case write_read
    case update
    case delete

    static var list: [TestFlow] {
        return [.write_read, .update, delete]
    }

    func toString() -> String {
        switch self {
        case .write_read: return "write/read"
        case .update: return "update"
        case .delete: return "delete"
        }
    }

    func action(key: String?, block: @escaping (String) -> Void) {
        switch self {
        case .write_read:

            let obj: TestObject = TestObject()
            obj.save { (ref, error) in
                block(ref!.key)
            }

        case .update:
            guard let key: String = key else {
                return
            }
            TestObject.observeSingle(key, eventType: .value, block: { (obj) in
                guard let obj: TestObject = obj else {
                    return
                }
                print(obj)
                obj.reset()
                block(key)
            })
        case .delete: break
            
            
            
        }
    }
}

