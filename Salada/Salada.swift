//
//  Salada.swift
//  Salada
//
//  Created by 1amageek on 2016/08/15.
//  Copyright © 2016年 Stamp. All rights reserved.
//

import Foundation
import Firebase
import FirebaseStorage

public protocol IngredientType {
    static var database: FIRDatabaseReference { get }
    static var databaseRef: FIRDatabaseReference { get }
    static var storage: FIRStorageReference { get }
    static var storageRef: FIRStorageReference { get }
    static var path: String { get }
    
    var id: String { get }
    var snapshot: FIRDataSnapshot? { get }
    var createdAt: NSDate { get }
    var value: [String: AnyObject] { get }
    var ignore: [String] { get }
    
    init?(snapshot: FIRDataSnapshot)
}

public extension IngredientType {
    static var database: FIRDatabaseReference { return FIRDatabase.database().reference() }
    static var databaseRef: FIRDatabaseReference { return self.database.child(self.path) }
    static var storage: FIRStorageReference { return FIRStorage.storage().reference() }
    static var storageRef: FIRStorageReference { return self.storage.child(self.path) }
}

public protocol Tasting {
    associatedtype Tsp: Ingredient
}

public extension Tasting where Self.Tsp: IngredientType, Self.Tsp == Self {
    
    public static func observeSingle(eventType: FIRDataEventType, block: ([Tsp]) -> Void) {
        self.databaseRef.observeSingleEventOfType(eventType, withBlock: { (snapshot) in
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
    
    public static func observeSingle(id: String, eventType: FIRDataEventType, block: (Tsp?) -> Void) {
        self.databaseRef.child(id).observeSingleEventOfType(eventType, withBlock: { (snapshot) in
            if snapshot.exists() {
                if let tsp: Tsp = Tsp(snapshot: snapshot) {
                    block(tsp)
                }
            } else {
                block(nil)
            }
        })
    }
    
}

public typealias File = Ingredient.File

public class Ingredient: NSObject, IngredientType, Tasting {
    
    public typealias Tsp = Ingredient
    
    // MARK: Initialize
    
    public override init() {
        self.localTimestamp = NSDate()
    }
    
    convenience required public init?(snapshot: FIRDataSnapshot) {
        self.init()
        _setSnapshot(snapshot)
    }
    
    convenience required public init?(id: String) {
        self.init()
    }
    
    public static var path: String {
        let type = Mirror(reflecting: self).subjectType
        return String(type).componentsSeparatedByString(".").first!.lowercaseString
    }
    
    private var tmpID: String = NSUUID().UUIDString
    private var _ID: String?
    
    public var id: String {
        if let id: String = self.snapshot?.key { return id }
        return self.tmpID
    }
    
    public var uploadTasks: [String: FIRStorageUploadTask] = [:]
    
    public var snapshot: FIRDataSnapshot? {
        didSet {
            if let snapshot: FIRDataSnapshot = snapshot {
                self.hasObserve = true
                guard let snapshot: [String: AnyObject] = snapshot.value as? [String: AnyObject] else { return }
                self.serverTimestamp = value["_timestamp"] as? Double
                Mirror(reflecting: self).children.forEach { (key, value) in
                    if let key: String = key {
                        if !self.ignore.contains(key) {
                            if let _: Any = self.decode(key, value: snapshot[key]) {
                                self.addObserver(self, forKeyPath: key, options: [.New, .Old], context: nil)
                                return
                            }
                            let mirror: Mirror = Mirror(reflecting: value)
                            guard let subjectType: Any.Type = mirror.subjectType else { return }
                            if subjectType == NSURL?.self || subjectType == NSURL.self {
                                if let value: String = snapshot[key] as? String {
                                    self.setValue(value, forKey: key)
                                }
                            } else if subjectType == NSDate?.self || subjectType == NSDate.self {
                                if let value: Double = snapshot[key] as? Double {
                                    let date: NSDate = NSDate(timeIntervalSince1970: NSTimeInterval(value))
                                    self.setValue(date, forKey: key)
                                }
                            } else if subjectType == File?.self || subjectType == File.self {
                                if let name: String = snapshot[key] as? String {
                                    if let _: File = value as? File {
                                        
                                    } else {
                                        let file: File = File(name: name)
                                        file.parent = self
                                        self.setValue(file, forKey: key)
                                    }
                                }
                            } else if let value: [Int: AnyObject] = snapshot[key] as? [Int: AnyObject] {
                                print(value, key)
                                // TODO array
                            } else if let value: [String: AnyObject] = snapshot[key] as? [String: AnyObject] {
                                self.setValue(Set(value.keys), forKey: key)
                            } else if let value: AnyObject = snapshot[key] {
                                self.setValue(value, forKey: key)
                            }
                            self.addObserver(self, forKeyPath: key, options: [.New, .Old], context: nil)
                        }
                    }
                }
            }
        }
    }
    
    private func _setSnapshot(snapshot: FIRDataSnapshot) {
        self.snapshot = snapshot
    }
    
    public var createdAt: NSDate {
        if let serverTimestamp: Double = self.serverTimestamp {
            let timestamp: NSTimeInterval = NSTimeInterval(serverTimestamp / 1000)
            return NSDate(timeIntervalSince1970: timestamp)
        }
        return self.localTimestamp
    }
    
    private var localTimestamp: NSDate
    
    private var serverTimestamp: Double?
    
    // MARK: Ingnore
    
    public var ignore: [String] {
        return []
    }
    
    private var hasObserve: Bool = false
    
    public var value: [String: AnyObject] {
        let mirror = Mirror(reflecting: self)
        var object: [String: AnyObject] = [:]
        mirror.children.forEach { (key, value) in
            if let key: String = key {
                if !self.ignore.contains(key) {
                    if let newValue: AnyObject = self.encode(key, value: value) {
                        object[key] = newValue
                        return
                    }
                    switch value.self {
                    case is String: if let value: String = value as? String { object[key] = value }
                    case is NSURL: if let value: NSURL = value as? NSURL { object[key] = value.absoluteString }
                    case is NSDate: if let value: NSDate = value as? NSDate { object[key] = value.timeIntervalSince1970 }
                    case is Int: if let value: Int = value as? Int { object[key] = value }
                    case is [String]: if let value: [String] = value as? [String] where !value.isEmpty { object[key] = value }
                    case is Set<String>: if let value: Set<String> = value as? Set<String> where !value.isEmpty { object[key] = value.toKeys() }
                    case is File:
                        if let file: File = value as? File {
                            file.parent = self
                        }
                    default: if let value: AnyObject = value as? AnyObject { object[key] = value }
                    }
                }
            }
        }
        return object
    }
    
    // MARK: - Encode, Decode
    
    /// Model -> Firebase
    public func encode(key: String, value: Any) -> AnyObject? {
        return nil
    }
    
    /// Snapshot -> Model
    public func decode(key: String, value: Any) -> Any? {
        return nil
    }
    
    // MARK: - Save
    
    public func save() {
        self.save(nil)
    }
    
    public func save(completion: ((NSError?, FIRDatabaseReference) -> Void)?) {
        if self.id == self.tmpID {
            var value: [String: AnyObject] = self.value
            value["_timestamp"] = FIRServerValue.timestamp()
            
            var ref: FIRDatabaseReference
            if let ID: String = self._ID {
                ref = self.dynamicType.databaseRef.child(ID)
            } else {
                ref = self.dynamicType.databaseRef.childByAutoId()
            }
            
            ref.setValue(value, withCompletionBlock: { (error, ref) in
                if let error: NSError = error { print(error) }
                self.dynamicType.databaseRef.child(ref.key).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
                    self.snapshot = snapshot
                    
                    // File save
                    Mirror(reflecting: self).children.forEach({ (key, value) in
                        if let key: String = key {
                            if !self.ignore.contains(key) {
                                let mirror: Mirror = Mirror(reflecting: value)
                                guard let subjectType: Any.Type = mirror.subjectType else { return }
                                if subjectType == File?.self || subjectType == File.self {
                                    if let file: File = value as? File {
                                        file.save(key)
                                    }
                                }
                            }
                        }
                    })
                    
                    completion?(error, ref)
                })
            })
        }
    }
    
    // MARK: - Delete
    
    public func remove() {
        guard let id: String = self.id else { return }
        self.dynamicType.databaseRef.child(id).removeValue()
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
            if let value: AnyObject = object.valueForKey(keyPath) {
                if let file: File = value as? File {
                    if let change: [String: AnyObject] = change {
                        let new: File = change["new"] as! File
                        let old: File = change["old"] as! File
                        if old.name != new.name {
                            new.parent = self
                            old.parent = self
                            file.save(keyPath, completion: { (meta, error) in
                                old.remove()
                            })
                        }
                    }
                } else if let values: Set<String> = value as? Set<String> {
                    if values.isEmpty { return }
                    if let change: [String: AnyObject] = change {
                        
                        let new: Set<String> = change["new"] as! Set<String>
                        let old: Set<String> = change["old"] as! Set<String>
                        
                        // Added
                        new.subtract(old).forEach({ (id) in
                            self.dynamicType.databaseRef.child(self.id).child(keyPath).child(id).setValue(true)
                        })
                        
                        // Remove
                        old.subtract(new).forEach({ (id) in
                            self.dynamicType.databaseRef.child(self.id).child(keyPath).child(id).removeValue()
                        })
                        
                    }
                } else if let values: [String] = value as? [String] {
                    if values.isEmpty { return }
                    self.dynamicType.databaseRef.child(self.id).child(keyPath).setValue(value)
                } else if let value: String = value as? String {
                    self.dynamicType.databaseRef.child(self.id).child(keyPath).setValue(value)
                } else {
                    self.dynamicType.databaseRef.child(self.id).child(keyPath).setValue(value)
                }
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
    
    // MARK: -
    
    public class File: NSObject {
        
        /// Save location
        public var ref: FIRStorageReference? {
            if let parent: Ingredient = self.parent {
                return parent.dynamicType.storageRef.child(parent.id).child(self.name)
            }
            return nil
        }
        
        /// Save data
        public var data: NSData?
        
        /// File name
        public var name: String
        
        /// File metadata
        public var metadata: FIRStorageMetadata?
        
        /// Parent to hold the location where you want to save
        public var parent: Ingredient?
        
        /// Firebase uploading task
        public private(set) var uploadTask: FIRStorageUploadTask?
        
        /// Firebase downloading task
        public private(set) var downloadTask: FIRStorageDownloadTask?
        
        // MARK: - Initialize
        
        public init(name: String) {
            self.name = name
        }
        
        public convenience init(name: String, data: NSData) {
            self.init(name: name)
            self.data = data
        }
        
        public convenience init(data: NSData) {
            let name: String = "\(NSDate().timeIntervalSince1970 * 1000)"
            self.init(name: name)
            self.data = data
        }
        
        // MARK: - Save
        
        public func save(keyPath: String) {
            self.save(keyPath, completion: nil)
        }
        
        public func save(keyPath: String, completion: ((FIRStorageMetadata?, NSError?) -> Void)?) {
            if let data: NSData = self.data, parent: Ingredient = self.parent {
                // If parent have uploadTask cancel
                parent.uploadTasks[keyPath]?.cancel()
                self.downloadTask?.cancel()
                self.uploadTask = self.ref?.putData(data, metadata: self.metadata) { (metadata, error) in
                    self.metadata = metadata
                    if let error: NSError = error {
                        completion?(metadata, error)
                        return
                    }
                    parent.dynamicType.databaseRef.child(parent.id).child(keyPath).setValue(self.name, withCompletionBlock: { (error, ref) in
                        parent.uploadTasks.removeValueForKey(keyPath)
                        self.uploadTask = nil
                        completion?(metadata, error)
                    })
                }
                parent.uploadTasks[keyPath] = self.uploadTask
            }
        }
        
        // MARK: - Load
        
        public func dataWithMaxSize(size: Int64, completion: (NSData?, NSError?) -> Void) -> FIRStorageDownloadTask? {
            self.downloadTask?.cancel()
            let task: FIRStorageDownloadTask? = self.ref?.dataWithMaxSize(size, completion: { (data, error) in
                self.downloadTask = nil
                completion(data, error)
            })
            self.downloadTask = task
            return task
        }
        
        public func remove() {
            self.remove(nil)
        }
        
        public func remove(completion: ((NSError?) -> Void)?) {
            self.ref?.deleteWithCompletion({ (error) in
                completion?(error)
            })
        }
        
        deinit {
            self.parent = nil
        }
        
    }
    
}

extension Ingredient {
    public override var hashValue: Int {
        return self.id.hash
    }
}

func ==(lhs: Ingredient, rhs: Ingredient) -> Bool {
    return lhs.id == rhs.id
}

public typealias SaladaChange = (deletions: [Int], insertions: [Int], modifications: [Int])

/// Datasource class.
/// Observe at a Firebase Database location.
public class Salada<T: Ingredient where T: IngredientType, T: Tasting>: NSObject {
    
    public var databaseRef: FIRDatabaseReference?
    public var bowl: [T] = []
    public var count: Int { return bowl.count }
    public var sortDescriptors: [NSSortDescriptor] = []
    
    public func objectAtIndex(index: Int) -> T? {
        if bowl.count > index {
            return bowl[index]
        }
        return nil
    }
    
    public func indexOfObject(tsp: T) -> Int? {
        return bowl.indexOf({ $0.id == tsp.id })
    }
    
    deinit {
        print(#function)
        if let handle: UInt = self.addedHandle {
            self.databaseRef?.removeObserverWithHandle(handle)
        }
        if let handle: UInt = self.changedHandle {
            self.databaseRef?.removeObserverWithHandle(handle)
        }
        if let handle: UInt = self.removedHandle {
            self.databaseRef?.removeObserverWithHandle(handle)
        }
    }
    
    private var addedHandle: UInt?
    private var changedHandle: UInt?
    private var removedHandle: UInt?
    
    // http://jsfiddle.net/katowulf/yumaB/
    
    public class func observe(block: (SaladaChange) -> Void) -> Salada<T> {
        
        let salada: Salada<T> = Salada()
        salada.databaseRef = T.databaseRef
        salada.addedHandle = salada.databaseRef?.queryLimitedToLast(10).observeEventType(.ChildAdded, withBlock: { [weak salada](snapshot) in
            print("added")
            guard let salada = salada else { return }
            if let t: T = T(snapshot: snapshot) {
                objc_sync_enter(salada)
                salada.bowl.append(t)
                let bowl: [T] = salada.bowl.sort(sortDescriptors: salada.sortDescriptors)
                salada.bowl = bowl
                let index: Int = salada.indexOfObject(t)!
                block(SaladaChange(deletions: [], insertions: [index], modifications: []))
                objc_sync_exit(salada)
            }
            })
        
        salada.changedHandle = salada.databaseRef?.observeEventType(.ChildChanged, withBlock: { [weak salada](snapshot) in
            print("change")
            guard let salada = salada else { return }
            if let t: T = T(snapshot: snapshot) {
                if let index: Int = salada.indexOfObject(t) {
                    salada.bowl[index] = t
                    block(SaladaChange(deletions: [], insertions: [], modifications: [index]))
                }
            }
            })
        
        salada.removedHandle = salada.databaseRef?.observeEventType(.ChildRemoved, withBlock: { [weak salada](snapshot) in
            print("remove")
            guard let salada = salada else { return }
            if let t: T = T(snapshot: snapshot) {
                if let index: Int = salada.indexOfObject(t) {
                    salada.bowl.removeAtIndex(index)
                    block(SaladaChange(deletions: [index], insertions: [], modifications: []))
                }
            }
            })
        
        return salada
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

extension SequenceType where Generator.Element : AnyObject {
    /// Return an `Array` containing the sorted elements of `source`
    /// using criteria stored in a NSSortDescriptors array.
    @warn_unused_result
    public func sort(sortDescriptors theSortDescs: [NSSortDescriptor]) -> [Self.Generator.Element] {
        return sort {
            for sortDesc in theSortDescs {
                switch sortDesc.compareObject($0, toObject: $1) {
                case .OrderedAscending: return true
                case .OrderedDescending: return false
                case .OrderedSame: continue
                }
            }
            return false
        }
    }
}
