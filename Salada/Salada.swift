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

public class Salada<T: Ingredient where T: IngredientType, T: Tasting>: NSObject {
    
    var ref: FIRDatabaseReference?
    var snapshot: FIRDataSnapshot?
    var count: Int {
        guard let snapshot: FIRDataSnapshot = self.snapshot else { return 0 }
        return Int(snapshot.childrenCount)
    }
    
    func objectAtIndex(index: Int) -> T? {
        guard let snapshot: FIRDataSnapshot = self.snapshot else { return nil }
        guard let snap: FIRDataSnapshot = snapshot.children.allObjects[index] as? FIRDataSnapshot else { return nil }
        return T(snapshot: snap)
    }
    
    func indexOfObject(tsp: T) -> Int? {
        guard let snapshot: FIRDataSnapshot = self.snapshot else { return NSNotFound }
        guard let snap: FIRDataSnapshot = tsp.snapshot else { return NSNotFound }
        return snapshot.children.allObjects.indexOf({ snap.key == $0.key })
    }
    
    deinit {
        print(#function)
        if let handle: UInt = self.valueHandle {
            self.ref?.removeObserverWithHandle(handle)
        }
        if let handle: UInt = self.addedHandle {
            self.ref?.removeObserverWithHandle(handle)
        }
        if let handle: UInt = self.changedHandle {
            self.ref?.removeObserverWithHandle(handle)
        }
        if let handle: UInt = self.movedHandle {
            self.ref?.removeObserverWithHandle(handle)
        }
        if let handle: UInt = self.removedHandle {
            self.ref?.removeObserverWithHandle(handle)
        }
    }

    private var valueHandle: UInt?
    private var addedHandle: UInt?
    private var changedHandle: UInt?
    private var movedHandle: UInt?
    private var removedHandle: UInt?
    
    class func observe(block: (SaladaChange<T>) -> Void) -> Salada<T> {
        
        let salada: Salada<T> = Salada()
////        weak let weakSelf: Salada<Tsp> = salada
//        salada.valueHandle = T.ref.observeEventType(.Value, withBlock: { (snapshot) in
////            guard let strongSelf: Salada = weakSelf else { return }
//            print("value")
//            salada.snapshot = snapshot
//            block(.Initial)
//        })
        
        salada.ref = T.ref
        salada.ref!.observeSingleEventOfType(.Value, withBlock: {(snapshot) in
            
            print("value")
            salada.snapshot = snapshot
            block(.Initial)
            
        })
        
        salada.addedHandle = salada.ref?.observeEventType(.ChildAdded, withBlock: { (snapshot) in
            
            if let t: T = T(snapshot: snapshot) {
                if salada.indexOfObject(t) == nil {
                    print("Added")
                    salada.ref?.observeSingleEventOfType(.Value, withBlock: { (snap) in
                        salada.snapshot = snap
                        if let index: Int = salada.indexOfObject(t) where index != NSNotFound {
                            block(.Update(deletions: [], insertions: [index], modifications: []))
                        }
                    })
                }
            }
        })
        
        salada.changedHandle = salada.ref?.observeEventType(.ChildChanged, withBlock: { (snapshot) in
            print("Changed")
            if let _: T = T(snapshot: snapshot) {
//                block(.Update)
            }
        })

        salada.movedHandle = salada.ref?.observeEventType(.ChildMoved, withBlock: { (snapshot) in
            print("Moved")
            if let _: T = T(snapshot: snapshot) {
//                block(.Update)
            }
        })
        
        salada.removedHandle = salada.ref?.observeEventType(.ChildRemoved, withBlock: { (snapshot) in
            print("Removed")
            if let _: T = T(snapshot: snapshot) {
//                block(.Update)
            }
        })
        
        return salada
    }
    
}

public enum SaladaChange<T> {
    case Initial
    case Update(deletions: [Int], insertions: [Int], modifications: [Int])
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

