//: Playground - noun: a place where people can play

import UIKit

protocol Referenceable {
    static var database: Any { get }
    static var databaseRef: Any { get }
    static var storage: Any { get }
    static var storageRef: Any { get }
    static var path: String { get }
    init()
}

protocol Tasting {
    associatedtype Tsp: Referenceable
    static func a() -> Tsp
    static func observe(_ eventType: Any, block: @escaping ([Tsp]) -> Void) -> UInt
}

extension Tasting where Tsp == Self, Tsp: Referenceable {

    static func observe(_ eventType: Any, block: @escaping ([Tsp]) -> Void) -> UInt {
        let tsp: Tsp = Tsp()
        block([tsp])
        return 1
    }
    
    static func a() -> Tsp {
        return Tsp()
    }
    
}

class Ingredient: Referenceable, Tasting {
    
    typealias Tsp = Ingredient
    
    static var database: Any { return [] }
    static var databaseRef: Any { return [] }
    static var storage: Any { return [] }
    static var storageRef: Any { return [] }
    static var path: String { return "" }

    required init() {
        
    }
    
}

class User: Ingredient {
    typealias Tsp = User
    var name: String = "223232"
}


class Salada<T> where T: Referenceable, T: Tasting {
    
}

extension Salada where T == T.Tsp {
    func object(at index: Int, block: @escaping (T.Tsp) -> Void) {
        T.observe("") { (t) in
            print(t)
            block(t.first!)
        }
    }
    
    func objectAt() -> T? {
        let a: T = T()
        let b: T.Tsp = T.Tsp()
        let c: T = T.a()
        return T.a()
    }
    
    func objec() -> T.Tsp {
        return T.Tsp()
    }
}


let s: Salada<User> = Salada()
s.objec()
s.objectAt()
//s.object(at: 0) { (user) in
//    print(user.name)
//}

