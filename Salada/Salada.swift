//
//  Salada.swift
//  Salada
//
//  Created by 1amageek on 2016/08/15.
//  Copyright © 2016年 Stamp. All rights reserved.
//

import Foundation
import Firebase

public protocol IngredientType {
    static var database: FIRDatabaseReference { get }
    static var ref: FIRDatabaseReference { get }
    static var path: String { get }
    
    var id: String? { get }
    var snapshot: FIRDataSnapshot? { get }
    var createdAt: NSDate { get }
    var value: [String: AnyObject] { get }
    var ignore: [String] { get }
    
    
    init?(snapshot: FIRDataSnapshot)
}

public extension IngredientType {
    static var database: FIRDatabaseReference { return FIRDatabase.database().reference() }
    static var ref: FIRDatabaseReference { return self.database.child(self.path) }
    var id: String? { return self.snapshot?.key }
}

public protocol Tasting {
    associatedtype Tsp: Ingredient
}

public extension Tasting where Self.Tsp: IngredientType, Self.Tsp == Self {
    
    public static func observeSingle(eventType: FIRDataEventType, block: ([Tsp]) -> Void) {
        self.ref.observeSingleEventOfType(eventType, withBlock: { (snapshot) in
            var children: [Tsp] = []
            snapshot.children.forEach({ (snapshot) in
                if let snapshot: FIRDataSnapshot = snapshot as? FIRDataSnapshot {
                    if let tsp: Tsp = Tsp(snapshot: snapshot) {
                        children.append(tsp)
                    }
                }
            })
            block(children)
        })
    }
    
    public static func observeSingle(id: String, eventType: FIRDataEventType, block: (Tsp) -> Void) {
        self.ref.child(id).observeSingleEventOfType(eventType, withBlock: { (snapshot) in
            if let tsp: Tsp = Tsp(snapshot: snapshot) {
                block(tsp)
            }
        })
    }
    
    public static func observe(eventType: FIRDataEventType, block: ([Tsp]) -> Void) {
        self.ref.observeEventType(eventType, withBlock: { (snapshot) in

        })
    }
    
}

public class Salada<Tsp: IngredientType>: NSObject {
    
    var snapshot: FIRDataSnapshot?
    
    deinit {
        if let handle: UInt = self.valueHandle {
            Tsp.ref.removeObserverWithHandle(handle)
        }
        if let handle: UInt = self.addedHandle {
            Tsp.ref.removeObserverWithHandle(handle)
        }
        if let handle: UInt = self.changedHandle {
            Tsp.ref.removeObserverWithHandle(handle)
        }
        if let handle: UInt = self.movedHandle {
            Tsp.ref.removeObserverWithHandle(handle)
        }
        if let handle: UInt = self.removedHandle {
            Tsp.ref.removeObserverWithHandle(handle)
        }
    }

    private var valueHandle: UInt?
    private var addedHandle: UInt?
    private var changedHandle: UInt?
    private var movedHandle: UInt?
    private var removedHandle: UInt?
    
    class func observe(tsp: Tsp.Type, block: (Tsp) -> Void) -> Salada<Tsp> {
        
        let salada: Salada<Tsp> = Salada()
//        weak let weakSelf: Salada<Tsp> = salada
        
        salada.valueHandle = Tsp.ref.observeEventType(.Value, withBlock: { (snapshot) in
//            guard let strongSelf: Salada = weakSelf else { return }
            salada.snapshot = snapshot
            print(#function)
        })
        
        salada.addedHandle = Tsp.ref.observeEventType(.ChildAdded, withBlock: { (snapshot) in
            print(#function)
        })
        
        salada.changedHandle = Tsp.ref.observeEventType(.ChildChanged, withBlock: { (snapshot) in
            print(#function)
        })

        salada.movedHandle = Tsp.ref.observeEventType(.ChildMoved, withBlock: { (snapshot) in
            print(#function)
        })
        
        salada.removedHandle = Tsp.ref.observeEventType(.ChildRemoved, withBlock: { (snapshot) in
            print(#function)
        })
        
        return Salada()
    }
    
    
    
}

public class Ingredient: NSObject, IngredientType, Tasting {
    
    public typealias Tsp = Ingredient
    
    public static var path: String {
        let type = Mirror(reflecting: self).subjectType
        return String(type).componentsSeparatedByString(".").first!.lowercaseString
    }
    
    public var id: String? { return self.snapshot?.key }
    
    public var snapshot: FIRDataSnapshot? {
        didSet {
            if let snapshot: FIRDataSnapshot = snapshot {
                self.hasObserve = true
                guard let value: [String: AnyObject] = snapshot.value as? [String: AnyObject] else { return }
                Mirror(reflecting: self).children.forEach { (key, _) in
                    if let key: String = key {
                        if !self.ignore.contains(key) {
                            if let value: [Int: AnyObject] = value[key] as? [Int: AnyObject] {
                                print(value, key)
                            } else if let value: [String: AnyObject] = value[key] as? [String: AnyObject] {
                                self.setValue(Set(value.keys), forKey: key)
                            } else if let value: AnyObject = value[key] {
                                self.setValue(value, forKey: key)
                            }
                            self.addObserver(self, forKeyPath: key, options: [.New], context: nil)
                        }
                    }
                }
            }
        }
    }
    
    private func _setSnapshot(snapshot: FIRDataSnapshot) {
        self.snapshot = snapshot
    }
    
    public var createdAt: NSDate
    
    // MARK: Ingnore
    
    public var ignore: [String] {
        return []
    }
 
    private var hasObserve: Bool = false
    
    // MARK: Initialize
    
    public override init() {
        self.createdAt = NSDate()
    }
    
    convenience required public init?(snapshot: FIRDataSnapshot) {
        self.init()
        print(snapshot)
        _setSnapshot(snapshot)
    }

    public var value: [String: AnyObject] {
        let mirror = Mirror(reflecting: self)
        var object: [String: AnyObject] = [:]
        mirror.children.forEach { (key, value) in
            if let key: String = key {
                if !self.ignore.contains(key) {
                    switch value.self {
                    case is String: if let value: String = value as? String { object[key] = value }
                    case is Int: if let value: Int = value as? Int { object[key] = value }
                    case is [String]: if let value: [String] = value as? [String] where !value.isEmpty { object[key] = value }
                    case is Set<String>: if let value: Set<String> = value as? Set<String> where !value.isEmpty { object[key] = value.toKeys() }
                    default: if let value: AnyObject = value as? AnyObject { object[key] = value }
                    }
                }
            }
        }
        return object
    }
    
    // MARK: - Save
    
    public func save() {
        self.save(nil)
    }
    
    public func save(completion: ((NSError?, FIRDatabaseReference) -> Void)?) {
        if self.id == nil {
            let value: [String: AnyObject] = self.value
            self.dynamicType.ref.childByAutoId().setValue(value, withCompletionBlock: { (error, ref) in
                if let error: NSError = error { print(error) }
                self.dynamicType.ref.child(ref.key).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
                    self.snapshot = snapshot
                    completion?(error, ref)
                })                
            })
        }
    }
    
    // MARK: - Delete
    
    public func remove() {
        guard let id: String = self.id else { return }
        self.dynamicType.ref.child(id).removeValue()
    }
    
    // MARK: - KVO
    
    override public func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {

        guard let keyPath: String = keyPath else {
            super.observeValueForKeyPath(nil, ofObject: object, change: change, context: context)
            return
        }
        
        guard let object: AnyObject = object else {
            super.observeValueForKeyPath(keyPath, ofObject: nil, change: change, context: context)
            return
        }
        
        let keys: [String] = Mirror(reflecting: self).children.flatMap({ return $0.label })
        if keys.contains(keyPath) {
            if var value: AnyObject = object.valueForKey(keyPath) {
                if let values: Set<String> = value as? Set<String> {
                    if values.isEmpty { return }
                    value = values.toKeys()
                }
                if let values: [String] = value as? [String] {
                    if values.isEmpty { return }
                }
                self.dynamicType.ref.child(self.id!).child(keyPath).setValue(value)
            }
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
    
    // MARK: - deinit
    
    deinit {
        if self.hasObserve {
            Mirror(reflecting: self).children.forEach { (key, value) in
                if let key: String = key {
                    if !self.ignore.contains(key) {
                        self.removeObserver(self, forKeyPath: key)
                    }
                }
            }
        }
    }
}

// MARK: -

extension CollectionType where Generator.Element == String {
    func toKeys() -> [String: Bool] {
        if self.isEmpty { return [:] }
        var keys: [String: Bool] = [:]
        self.forEach { (object) in
            keys[object] = true
        }
        return keys
    }
}

//struct RelationArray: CollectionType, Hashable {
//    
//}

