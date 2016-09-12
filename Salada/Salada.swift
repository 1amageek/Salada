//
//  Salada.swift
//  Salada
//
//  Created by 1amageek on 2016/08/15.
//  Copyright © 2016年 Stamp. All rights reserved.
//

import Foundation
import Firebase
import FirebaseDatabase
import FirebaseStorage

public protocol IngredientType {
    static var database: FIRDatabaseReference { get }
    static var databaseRef: FIRDatabaseReference { get }
    static var storage: FIRStorageReference { get }
    static var storageRef: FIRStorageReference { get }
    static var path: String { get }
    
    var id: String { get }
    var snapshot: FIRDataSnapshot? { get }
    var createdAt: Date { get }
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
    associatedtype Tsp: IngredientType
    static func observeSingle(_ eventType: FIRDataEventType, block: @escaping ([Tsp]) -> Void)
    static func observeSingle(_ id: String, eventType: FIRDataEventType, block: @escaping (Tsp?) -> Void)
    static func observe(_ eventType: FIRDataEventType, block: @escaping ([Tsp]) -> Void) -> UInt
    static func observe(_ id: String, eventType: FIRDataEventType, block: @escaping (Tsp?) -> Void) -> UInt
}

public extension Tasting where Self: IngredientType, Tsp == Self {
    
    public static func observeSingle(_ eventType: FIRDataEventType, block: @escaping ([Tsp]) -> Void) {
        self.databaseRef.observeSingleEvent(of: eventType, with: { (snapshot) in
            if snapshot.exists() {
                var children: [Tsp] = []
                snapshot.children.forEach({ (snapshot) in
                    if let snapshot: FIRDataSnapshot = snapshot as? FIRDataSnapshot {
                        if let tsp: Tsp = Tsp(snapshot: snapshot) {
                            children.append(tsp)
                        }
                    }
                })
            } else {
                block([])
            }
        })
    }
    
    public static func observeSingle(_ id: String, eventType: FIRDataEventType, block: @escaping (Tsp?) -> Void) {
        self.databaseRef.observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.hasChild(id) {
                self.databaseRef.child(id).observeSingleEvent(of: eventType, with: { (snapshot) in
                    if snapshot.exists() {
                        if let tsp: Tsp = Tsp(snapshot: snapshot) {
                            block(tsp)
                        }
                    } else {
                        block(nil)
                    }
                })
            } else {
                block(nil)
            }
        })
    }
    
    public static func observe(_ eventType: FIRDataEventType, block: @escaping ([Tsp]) -> Void) -> UInt {
        return self.databaseRef.observe(eventType, with: { (snapshot) in
            if snapshot.exists() {
                var children: [Tsp] = []
                snapshot.children.forEach({ (snapshot) in
                    if let snapshot: FIRDataSnapshot = snapshot as? FIRDataSnapshot {
                        if let tsp: Tsp = Tsp(snapshot: snapshot) {
                            children.append(tsp)
                        }
                    }
                })
            } else {
                block([])
            }
        })
    }
    
    public static func observe(_ id: String, eventType: FIRDataEventType, block: @escaping (Tsp?) -> Void) -> UInt {
        return self.databaseRef.child(id).observe(eventType, with: { (snapshot) in
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

open class Ingredient: NSObject, IngredientType, Tasting {

    public typealias Tsp = Ingredient
    
    // MARK: Initialize
    
    public override init() {
        self.localTimestamp = Date()
    }
    
    convenience required public init?(snapshot: FIRDataSnapshot) {
        self.init()
        _setSnapshot(snapshot)
    }
    
    convenience required public init?(id: String) {
        self.init()
        self._id = id
    }
    
    open static var path: String {
        let type = Mirror(reflecting: self).subjectType
        return String(describing: type).components(separatedBy: ".").first!.lowercased()
    }
    
    fileprivate var tmpID: String = UUID().uuidString
    fileprivate var _id: String?
    
    open var id: String {
        if let id: String = self.snapshot?.key { return id }
        if let id: String = self._id { return id }
        return tmpID
    }
    
    open var uploadTasks: [String: FIRStorageUploadTask] = [:]
    
    open var snapshot: FIRDataSnapshot? {
        didSet {
            if let snapshot: FIRDataSnapshot = snapshot {
                self.hasObserve = true
                guard let snapshot: [String: AnyObject] = snapshot.value as? [String: AnyObject] else { return }
                self.serverTimestamp = value["_timestamp"] as? Double
                Mirror(reflecting: self).children.forEach { (key, value) in
                    if let key: String = key {
                        if !self.ignore.contains(key) {
                            if let _: Any = self.decode(key, value: snapshot[key]) {
                                self.addObserver(self, forKeyPath: key, options: [.new, .old], context: nil)
                                return
                            }
                            let mirror: Mirror = Mirror(reflecting: value)
                            guard let subjectType: Any.Type = mirror.subjectType else { return }
                            if subjectType == URL?.self || subjectType == URL.self {
                                if let value: String = snapshot[key] as? String, let url: URL = URL(string: value) {
                                    self.setValue(url, forKey: key)
                                }
                            } else if subjectType == Date?.self || subjectType == Date.self {
                                if let value: Double = snapshot[key] as? Double {
                                    let date: Date = Date(timeIntervalSince1970: TimeInterval(value))
                                    self.setValue(date, forKey: key)
                                }
                            } else if subjectType == File?.self || subjectType == File.self {
                                if let name: String = snapshot[key] as? String {
                                    if let _: File = value as? File {
                                        
                                    } else {
                                        let file: File = File(name: name)
                                        file.parent = self
                                        file.keyPath = key
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
                            self.addObserver(self, forKeyPath: key, options: [.new, .old], context: nil)
                        }
                    }
                }
            }
        }
    }
    
    fileprivate func _setSnapshot(_ snapshot: FIRDataSnapshot) {
        self.snapshot = snapshot
    }
    
    open var createdAt: Date {
        if let serverTimestamp: Double = self.serverTimestamp {
            let timestamp: TimeInterval = TimeInterval(serverTimestamp / 1000)
            return Date(timeIntervalSince1970: timestamp)
        }
        return self.localTimestamp
    }
    
    fileprivate var localTimestamp: Date
    
    fileprivate var serverTimestamp: Double?
    
    // MARK: Ingnore
    
    open var ignore: [String] {
        return []
    }
    
    fileprivate var hasObserve: Bool = false
    
    open var value: [String: AnyObject] {
        let mirror = Mirror(reflecting: self)
        var object: [String: AnyObject] = [:]
        mirror.children.forEach { (key, value) in
            if let key: String = key {
                if !self.ignore.contains(key) {
                    if let newValue: Any = self.encode(key, value: value) {
                        object[key] = newValue as AnyObject?
                        return
                    }
                    switch value.self {
                    case is String: if let value: String = value as? String { object[key] = value as AnyObject? }
                    case is URL: if let value: URL = value as? URL { object[key] = value.absoluteString as AnyObject? }
                    case is Date: if let value: Date = value as? Date { object[key] = value.timeIntervalSince1970 as AnyObject? }
                    case is Int: if let value: Int = value as? Int { object[key] = value as AnyObject? }
                    case is [String]: if let value: [String] = value as? [String] , !value.isEmpty { object[key] = value as AnyObject? }
                    case is Set<String>: if let value: Set<String> = value as? Set<String> , !value.isEmpty { object[key] = value.toKeys() as AnyObject? }
                    case is File:
                        if let file: File = value as? File {
                            file.parent = self
                            file.keyPath = key
                        }
                    default: if let value: AnyObject = value as AnyObject? { object[key] = value as AnyObject? }
                    }
                }
            }
        }
        return object
    }
    
    // MARK: - Encode, Decode
    
    /// Model -> Firebase
    open func encode(_ key: String, value: Any) -> Any? {
        return nil
    }
    
    /// Snapshot -> Model
    open func decode(_ key: String, value: Any) -> Any? {
        return nil
    }
    
    // MARK: - Save
    
    open func save() {
        self.save(nil)
    }
    
    open func save(_ completion: ((NSError?, FIRDatabaseReference) -> Void)?) {
        if self.id == self.tmpID || self.id == self._id {
            var value: [String: AnyObject] = self.value
            value["_timestamp"] = FIRServerValue.timestamp() as AnyObject?
            
            var ref: FIRDatabaseReference
            if let id: String = self._id {
                ref = type(of: self).databaseRef.child(id)
            } else {
                ref = type(of: self).databaseRef.childByAutoId()
            }
            
            ref.setValue(value, withCompletionBlock: { (error, ref) in
                if let error: NSError = error as NSError? { print(error) }
                type(of: self).databaseRef.child(ref.key).observeSingleEvent(of: .value, with: { (snapshot) in
                    self.snapshot = snapshot
                    
                    // File save
                    Mirror(reflecting: self).children.forEach({ (key, value) in
                        if let key: String = key {
                            if !self.ignore.contains(key) {
                                let mirror: Mirror = Mirror(reflecting: value)
                                guard let subjectType: Any.Type = mirror.subjectType else { return }
                                if subjectType == File?.self || subjectType == File.self {
                                    if let file: File = value as? File {
                                        _ = file.save(key)
                                    }
                                }
                            }
                        }
                    })
                    
                    completion?(error as NSError?, ref)
                })
            })
        }
    }
    
    // MARK: - Delete
    
    open func remove() {
        guard let id: String = self.id else { return }
        type(of: self).databaseRef.child(id).removeValue()
    }
    
    // MARK: - KVO
    
    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        guard let keyPath: String = keyPath else {
            super.observeValue(forKeyPath: nil, of: object, change: change, context: context)
            return
        }
        
        guard let object: NSObject = object as? NSObject else {
            super.observeValue(forKeyPath: keyPath, of: nil, change: change, context: context)
            return
        }
        
        let keys: [String] = Mirror(reflecting: self).children.flatMap({ return $0.label })
        if keys.contains(keyPath) {
            
            if let value: AnyObject = object.value(forKey: keyPath) as AnyObject? {
                if let _: File = value as? File {
                    if let change: [NSKeyValueChangeKey: AnyObject] = change as [NSKeyValueChangeKey: AnyObject]? {
                        let new: File = change[.newKey] as! File
                        if let old: File = change[.oldKey] as? File {
                            if old.name != new.name {
                                new.parent = self
                                new.keyPath = keyPath
                                old.parent = self
                                old.keyPath = keyPath
                                _ = new.save(keyPath, completion: { (meta, error) in
                                    old.remove()
                                })
                            }
                        } else {
                            new.parent = self
                            _ = new.save(keyPath)
                        }
                    }
                } else if let values: Set<String> = value as? Set<String> {
                    if values.isEmpty { return }
                    if let change: [NSKeyValueChangeKey: AnyObject] = change as [NSKeyValueChangeKey: AnyObject]? {
                        
                        let new: Set<String> = change[.newKey] as! Set<String>
                        let old: Set<String> = change[.oldKey] as! Set<String>
                        
                        // Added
                        new.subtracting(old).forEach({ (id) in
                            type(of: self).databaseRef.child(self.id).child(keyPath).child(id).setValue(true)
                        })
                        
                        // Remove
                        old.subtracting(new).forEach({ (id) in
                            type(of: self).databaseRef.child(self.id).child(keyPath).child(id).removeValue()
                        })
                        
                    }
                } else if let values: [String] = value as? [String] {
                    if values.isEmpty { return }
                    type(of: self).databaseRef.child(self.id).child(keyPath).setValue(value)
                } else if let value: String = value as? String {
                    type(of: self).databaseRef.child(self.id).child(keyPath).setValue(value)
                } else {
                    type(of: self).databaseRef.child(self.id).child(keyPath).setValue(value)
                }
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
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
    
    open class File: NSObject {
        
        /// Save location
        open var ref: FIRStorageReference? {
            if let parent: Ingredient = self.parent {
                return type(of: parent).storageRef.child(parent.id).child(self.name)
            }
            return nil
        }
        
        /// Save data
        open var data: Data?
        
        /// File name
        open var name: String
        
        /// File metadata
        open var metadata: FIRStorageMetadata?
        
        /// Parent to hold the location where you want to save
        open var parent: Ingredient?
        
        /// Property name to save
        open var keyPath: String?
        
        /// Firebase uploading task
        open fileprivate(set) var uploadTask: FIRStorageUploadTask?
        
        /// Firebase downloading task
        open fileprivate(set) var downloadTask: FIRStorageDownloadTask?
        
        // MARK: - Initialize
        
        public init(name: String) {
            self.name = name
        }
        
        public convenience init(name: String, data: Data) {
            self.init(name: name)
            self.data = data
        }
        
        public convenience init(data: Data) {
            let name: String = "\(Int(Date().timeIntervalSince1970 * 1000))"
            self.init(name: name)
            self.data = data
        }
        
        // MARK: - Save
        
        open func save(_ keyPath: String) -> FIRStorageUploadTask? {
            return self.save(keyPath, completion: nil)
        }
        
        open func save(_ keyPath: String, completion: ((FIRStorageMetadata?, NSError?) -> Void)?) -> FIRStorageUploadTask? {
            if let data: Data = self.data, let parent: Ingredient = self.parent {
                // If parent have uploadTask cancel
                parent.uploadTasks[keyPath]?.cancel()
                self.downloadTask?.cancel()
                self.uploadTask = self.ref?.put(data, metadata: self.metadata) { (metadata, error) in
                    self.metadata = metadata
                    if let error: NSError = error as NSError? {
                        completion?(metadata, error)
                        return
                    }
                    type(of: parent).databaseRef.child(parent.id).child(keyPath).setValue(self.name, withCompletionBlock: { (error, ref) in
                        parent.uploadTasks.removeValue(forKey: keyPath)
                        self.uploadTask = nil
                        completion?(metadata, error as NSError?)
                    })
                }
                parent.uploadTasks[keyPath] = self.uploadTask
                return self.uploadTask
            }
            return nil
        }
        
        // MARK: - Load
        
        open func dataWithMaxSize(_ size: Int64, completion: @escaping (Data?, NSError?) -> Void) -> FIRStorageDownloadTask? {
            self.downloadTask?.cancel()
            let task: FIRStorageDownloadTask? = self.ref?.data(withMaxSize: size, completion: { (data, error) in
                self.downloadTask = nil
                completion(data, error as NSError?)
            })
            self.downloadTask = task
            return task
        }
        
        open func remove() {
            self.remove(nil)
        }
        
        open func remove(_ completion: ((NSError?) -> Void)?) {
            self.ref?.delete(completion: { (error) in
                
            })
//            self.ref?.delete(completion: { (error) in
//                completion?(error)
//            })
        }
        
        deinit {
            self.parent = nil
        }
        
    }
    
}

extension Ingredient {
    open override var hashValue: Int {
        return self.id.hash
    }
}

func ==(lhs: Ingredient, rhs: Ingredient) -> Bool {
    return lhs.id == rhs.id
}

public typealias SaladaChange = (deletions: [Int], insertions: [Int], modifications: [Int])

/// Datasource class.
/// Observe at a Firebase Database location.
open class Salada<T: Ingredient>: NSObject where T: IngredientType, T: Tasting {
    
    /// DatabaseReference
    open var databaseRef: FIRDatabaseReference?
    
    open var bowl: [T] = []
    open var count: Int { return bowl.count }
    open var sortDescriptors: [NSSortDescriptor] = []
    
    open func objectAtIndex(_ index: Int) -> T? {
        if bowl.count > index {
            return bowl[index]
        }
        return nil
    }
    
    open func indexOfObject(_ tsp: T) -> Int? {
        return bowl.index(where: { $0.id == tsp.id })
    }
    
    open func indexOfKey(_ key: String) -> Int? {
        return bowl.index(where: { $0.id == key })
    }
    
    deinit {
        if let handle: UInt = self.addedHandle {
            self.databaseRef?.removeObserver(withHandle: handle)
        }
        if let handle: UInt = self.changedHandle {
            self.databaseRef?.removeObserver(withHandle: handle)
        }
        if let handle: UInt = self.removedHandle {
            self.databaseRef?.removeObserver(withHandle: handle)
        }
    }
    
    fileprivate var addedHandle: UInt?
    fileprivate var changedHandle: UInt?
    fileprivate var removedHandle: UInt?
    
    // http://jsfiddle.net/katowulf/yumaB/
    
    
    open class func observe(_ block: @escaping (SaladaChange) -> Void) -> Salada<T> {
        
        let salada: Salada<T> = Salada()
        salada.databaseRef = T.databaseRef
        salada.addedHandle = salada.databaseRef?.observe(.childAdded, with: { [weak salada](snapshot) in
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
        
        salada.changedHandle = salada.databaseRef?.observe(.childChanged, with: { [weak salada](snapshot) in
            print("change")
            guard let salada = salada else { return }
            if let t: T = T(snapshot: snapshot) {
                if let index: Int = salada.indexOfObject(t) {
                    salada.bowl[index] = t
                    block(SaladaChange(deletions: [], insertions: [], modifications: [index]))
                }
            }
            })
        
        salada.removedHandle = salada.databaseRef?.observe(.childRemoved, with: { [weak salada](snapshot) in
            print("remove")
            guard let salada = salada else { return }
            if let t: T = T(snapshot: snapshot) {
                if let index: Int = salada.indexOfObject(t) {
                    salada.bowl.remove(at: index)
                    block(SaladaChange(deletions: [index], insertions: [], modifications: []))
                }
            }
            })
        
        return salada
    }
    
}

extension Salada {
    
    public class func observe(with reference: FIRDatabaseReference, block: @escaping (SaladaChange) -> Void) -> Salada<T> {
        
        let salada: Salada<T> = Salada<T>()
        salada.databaseRef = reference
        salada.addedHandle = salada.databaseRef?.observe(.childAdded, with: { [weak salada](snapshot) in
            
            guard let salada = salada else { return }
            let key: String = snapshot.key
            
            T.databaseRef.child(key).observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.exists() {
                    if let t: T = T(snapshot: snapshot) {
                        objc_sync_enter(salada)
                        salada.bowl.append(t)
                        let bowl: [T] = salada.bowl.sort(sortDescriptors: salada.sortDescriptors)
                        salada.bowl = bowl
                        let index: Int = salada.indexOfObject(t)!
                        block(SaladaChange(deletions: [], insertions: [index], modifications: []))
                        objc_sync_exit(salada)
                    }
                }
            })
            })
        
        salada.changedHandle = salada.databaseRef?.observe(.childChanged, with: { [weak salada](snapshot) in
            
            guard let salada = salada else { return }
            let key: String = snapshot.key
            
            T.databaseRef.child(key).observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.exists() {
                    if let t: T = T(snapshot: snapshot) {
                        if let index: Int = salada.indexOfObject(t) {
                            salada.bowl[index] = t
                            block(SaladaChange(deletions: [], insertions: [], modifications: [index]))
                        }
                    }
                }
            })
            })
        
        salada.removedHandle = salada.databaseRef?.observe(.childRemoved, with: { [weak salada](snapshot) in
            
            guard let salada = salada else { return }
            let key: String = snapshot.key
            
            if let index: Int = salada.indexOfKey(key) {
                salada.bowl.remove(at: index)
                block(SaladaChange(deletions: [index], insertions: [], modifications: []))
            }
            })
        
        return salada
    }
    
}


// MARK: -

extension Collection where Iterator.Element == String {
    func toKeys() -> [String: Bool] {
        if self.isEmpty { return [:] }
        var keys: [String: Bool] = [:]
        self.forEach { (object) in
            keys[object] = true
        }
        return keys
    }
}

extension Sequence where Iterator.Element : AnyObject {
    /// Return an `Array` containing the sorted elements of `source`
    /// using criteria stored in a NSSortDescriptors array.
    
    public func sort(sortDescriptors theSortDescs: [NSSortDescriptor]) -> [Self.Iterator.Element] {
        return sorted {
            for sortDesc in theSortDescs {
                switch sortDesc.compare($0, to: $1) {
                case .orderedAscending: return true
                case .orderedDescending: return false
                case .orderedSame: continue
                }
            }
            return false
        }
    }
}
