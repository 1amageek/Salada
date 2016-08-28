//: Playground - noun: a place where people can play

import Foundation

protocol IngredientType {
    var id: String? { get }
    var createdAt: NSDate { get }
    init(value: [String: AnyObject])
}

protocol Tasting {
    associatedtype Tsp: Ingredient
}

extension Tasting where Self.Tsp: IngredientType, Self.Tsp == Self {
    static func observe() -> Tsp {
        let tsp: Tsp = Tsp(value: [:])
        return tsp
    }
}

class Ingredient: NSObject, IngredientType, Tasting {
    
    typealias Tsp = Ingredient
    
    var id: String? { return "123" }
    
    var createdAt: NSDate
    
    private var hasObserve: Bool = false
    
    private let ignore: [String] = ["snapshot", "hasObserve", "ignore"]
    
    override init() {
        self.createdAt = NSDate()
    }
    
    convenience required init(value: [String: AnyObject]) {
        self.init()
        self.hasObserve = true
        Mirror(reflecting: self).children.forEach { (key, _) in
            print(key)
            if let key: String = key {
                if !self.ignore.contains(key) {
                    self.addObserver(self, forKeyPath: key, options: [.New], context: nil)
                    if let value: AnyObject = value[key] {
                        self.setValue(value, forKey: key)
                    }
                }
            }
        }
    }
}

class User: Ingredient {
    typealias Tsp = User
    var name: String?
}


let user: User = User.observe()

@objc enum UserType: Int {
    case User
    case Group
}

let mirror: Mirror = Mirror(reflecting: UserType.User)
mirror.displayStyle
mirror.subjectType
mirror.children
mirror.description
mirror.superclassMirror()


let t = mirror.subjectType
t

