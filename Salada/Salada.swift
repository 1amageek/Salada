//
//  Salada.swift
//  Salada
//
//  Created by 1amageek on 2016/08/15.
//  Copyright © 2016年 Stamp. All rights reserved.
//
//  Github: https://github.com/1amageek/Salada
//

import Foundation
import Firebase
import FirebaseDatabase
import FirebaseStorage

/**
 Protocol that holds a reference Firebase
 */
public protocol Referenceable: NSObjectProtocol, Hashable {
    static var database: FIRDatabaseReference { get }
    static var databaseRef: FIRDatabaseReference { get }
    static var storage: FIRStorageReference { get }
    static var storageRef: FIRStorageReference { get }
    static var _path: String { get }
    
    var id: String { get }
    var snapshot: FIRDataSnapshot? { get }
    var createdAt: Date { get }
    var value: [String: Any] { get }
    var ignore: [String] { get }
    
    init?(snapshot: FIRDataSnapshot)
}

public extension Referenceable {
    static var database: FIRDatabaseReference { return FIRDatabase.database().reference() }
    static var databaseRef: FIRDatabaseReference { return self.database.child(self._path) }
    static var storage: FIRStorageReference { return FIRStorage.storage().reference() }
    static var storageRef: FIRStorageReference { return self.storage.child(self._path) }
}

public typealias File = Ingredient.File

/**
 Ingredient is a class that defines the Scheme to Firebase.
 Once saved Ingredient, save to the server in real time by KVO changes.
 Changes are run even offline.
 
 Please observe the following rules.
 1. Declaration the Tsp
 1. Class other than the Foundation description 'decode, 'encode'
 */
public class Ingredient: NSObject, Referenceable {
    
    public typealias Tsp = Ingredient
    
    struct IngredientError: Error {
        enum ErrorKind {
            case invalidId
            case invalidFile
            case timeout
        }
        let kind: ErrorKind
        let description: String
    }
    
    enum ValueType {
        
        case string(String, String)
        case int(String, Int)
        case double(String, Double)
        case float(String, Float)
        case bool(String, Bool)
        case date(String, TimeInterval, Date)
        case url(String, String, URL)
        case array(String, [Any])
        case relation(String, [String: Bool], Set<String>)
        case file(String, File)
        case object(String, Any)
        case null
        
        static func from(key: String, value: Any) -> ValueType {
            switch value.self {
            case is String:         if let value: String        = value as? String      { return .string(key, value)  }
            case is URL:            if let value: URL           = value as? URL         { return .url(key, value.absoluteString, value) }
            case is Date:           if let value: Date          = value as? Date        { return .date(key, value.timeIntervalSince1970, value)}
            case is Int:            if let value: Int           = value as? Int         { return .int(key, Int(value)) }
            case is Double:         if let value: Double        = value as? Double      { return .double(key, Double(value)) }
            case is Float:          if let value: Float         = value as? Float       { return .float(key, Float(value)) }
            case is Bool:           if let value: Bool          = value as? Bool        { return .bool(key, Bool(value)) }
            case is [String]:       if let value: [String]      = value as? [String], !value.isEmpty { return .array(key, value) }
            case is Set<String>:    if let value: Set<String>   = value as? Set<String>, !value.isEmpty { return .relation(key, value.toKeys(), value) }
            case is File:           if let value: File          = value as? File        { return .file(key, value) }
            case is [String: Any]:  if let value: [String: Any] = value as? [String: Any] { return .object(key, value)}
            default: break
            }
            return .null
        }
        
        static func from(key: String, mirror: Mirror, with snapshot: [String: Any]) -> ValueType {
            let subjectType: Any.Type = mirror.subjectType
            if subjectType == String.self || subjectType == String?.self {
                if let value: String = snapshot[key] as? String {
                    return .string(key, value)
                }
            } else if subjectType == URL.self || subjectType == URL?.self {
                if
                    let value: String = snapshot[key] as? String,
                    let url: URL = URL(string: value)  {
                    return .url(key, value, url)
                }
            } else if subjectType == Date.self || subjectType == Date?.self {
                if let value: Double = snapshot[key] as? Double {
                    let date: Date = Date(timeIntervalSince1970: TimeInterval(value))
                    return .date(key, value, date)
                }
            } else if subjectType == Double.self || subjectType == Double?.self {
                if let value: Double = snapshot[key] as? Double {
                    return .double(key, Double(value))
                }
            } else if subjectType == Int.self || subjectType == Int?.self {
                if let value: Int = snapshot[key] as? Int {
                    return .int(key, Int(value))
                }
            } else if subjectType == Float.self || subjectType == Float?.self {
                if let value: Float = snapshot[key] as? Float {
                    return .float(key, Float(value))
                }
            } else if subjectType == Bool.self || subjectType == Bool?.self {
                if let value: Bool = snapshot[key] as? Bool {
                    return .bool(key, Bool(value))
                }
            } else if subjectType == [String].self || subjectType == [String]?.self {
                if let value: [String] = snapshot[key] as? [String], !value.isEmpty {
                    return .array(key, value)
                }
            } else if subjectType == Set<String>.self || subjectType == Set<String>?.self {
                if let value: [String: Bool] = snapshot[key] as? [String: Bool], !value.isEmpty {
                    return .relation(key, value, Set(value.keys))
                }
            } else if subjectType == [String: Any].self || subjectType == [String: Any]?.self {
                if let value: [String: Any] = snapshot[key] as? [String: Any] {
                    return .object(key, value)
                }
            } else if subjectType == File.self || subjectType == File?.self {
                if let value: String = snapshot[key] as? String {
                    let file: File = File(name: value)
                    return .file(key, file)
                }
            }
            return .null
        }
    }
    
    // MARK: Referenceable
    
    public class var _modelName: String {
        return String(describing: Mirror(reflecting: self).subjectType).components(separatedBy: ".").first!.lowercased()
    }
    
    public class var _version: String {
        return "v1"
    }
    
    public static var _path: String {
        return "\(self._version)/\(self._modelName)"
    }
    
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
    
    fileprivate var tmpID: String = UUID().uuidString
    fileprivate var _id: String?
    
    public var id: String {
        if let id: String = self.snapshot?.key { return id }
        if let id: String = self._id { return id }
        return tmpID
    }
    
    /// Upload tasks
    public var uploadTasks: [String: FIRStorageUploadTask] = [:]
    
    public var snapshot: FIRDataSnapshot? {
        didSet {
            if let snapshot: FIRDataSnapshot = snapshot {
                self.hasObserve = true
                guard let snapshot: [String: Any] = snapshot.value as? [String: Any] else { return }
                self.serverCreatedAtTimestamp = snapshot["_createdAt"] as? Double
                self.serverUpdatedAtTimestamp = snapshot["_updatedAt"] as? Double
                Mirror(reflecting: self).children.forEach { (key, value) in
                    if let key: String = key {
                        if !self.ignore.contains(key) {
                            if let _: Any = self.decode(key, value: snapshot[key]) {
                                self.addObserver(self, forKeyPath: key, options: [.new, .old], context: nil)
                                return
                            }
                            let mirror: Mirror = Mirror(reflecting: value)
                            switch ValueType.from(key: key, mirror: mirror, with: snapshot) {
                            case .string(let key, let value): self.setValue(value, forKey: key)
                            case .int(let key, let value): self.setValue(value, forKey: key)
                            case .float(let key, let value): self.setValue(value, forKey: key)
                            case .double(let key, let value): self.setValue(value, forKey: key)
                            case .bool(let key, let value): self.setValue(value, forKey: key)
                            case .url(let key, _, let value): self.setValue(value, forKey: key)
                            case .date(let key, _, let value): self.setValue(value, forKey: key)
                            case .array(let key, let value): self.setValue(value, forKey: key)
                            case .relation(let key, _, let value): self.setValue(value, forKey: key)
                            case .file(let key, let file):
                                file.parent = self
                                file.keyPath = key
                                self.setValue(file, forKey: key)
                            case .object(let key, let value): self.setValue(value, forKey: key)
                            case .null: break
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
    
    /**
     The date when this object was created
     */
    public var createdAt: Date {
        if let serverTimestamp: Double = self.serverCreatedAtTimestamp {
            let timestamp: TimeInterval = TimeInterval(serverTimestamp / 1000)
            return Date(timeIntervalSince1970: timestamp)
        }
        return self.localTimestamp
    }
    
    /**
     The date when this object was updated
     */
    public var updatedAt: Date {
        if let serverTimestamp: Double = self.serverUpdatedAtTimestamp {
            let timestamp: TimeInterval = TimeInterval(serverTimestamp / 1000)
            return Date(timeIntervalSince1970: timestamp)
        }
        return self.localTimestamp
    }
    
    fileprivate var localTimestamp: Date
    
    fileprivate var serverCreatedAtTimestamp: Double?
    
    fileprivate var serverUpdatedAtTimestamp: Double?
    
    // MARK: Ignore
    
    public var ignore: [String] {
        return []
    }
    
    fileprivate var hasObserve: Bool = false
    
    public var value: [String: Any] {
        let mirror = Mirror(reflecting: self)
        var object: [String: Any] = [:]
        mirror.children.forEach { (key, value) in
            if let key: String = key {
                if !self.ignore.contains(key) {
                    if let newValue: Any = self.encode(key, value: value) {
                        object[key] = newValue
                        return
                    }
                    
                    switch ValueType.from(key: key, value: value) {
                    case .string(let key, let value): object[key] = value
                    case .double(let key, let value): object[key] = value
                    case .int(let key, let value): object[key] = value
                    case .float(let key, let value): object[key] = value
                    case .bool(let key, let value): object[key] = value
                    case .url(let key, let value, _): object[key] = value
                    case .date(let key, let value, _): object[key] = value
                    case .array(let key, let value): object[key] = value
                    case .relation(let key, let value, _): object[key] = value
                    case .file(let key, let value):
                        value.parent = self
                        value.keyPath = key
                    case .object(let key, let value): object[key] = value
                    case .null: break
                    }
                    
                }
            }
        }
        return object
    }
    
    subscript(property: String) -> Any? {
        let mirror = Mirror(reflecting: self)
        for (key, value) in mirror.children {
            if key == property {
                return value
            }
        }
        return nil
    }
    
    // MARK: Encode, Decode
    
    /// Model -> Firebase
    public func encode(_ key: String, value: Any?) -> Any? {
        return nil
    }
    
    /// Snapshot -> Model
    public func decode(_ key: String, value: Any?) -> Any? {
        return nil
    }
    
    // MARK: Save
    
    public func save() {
        self.save(nil)
    }
    
    /**
     Save the new Object to Firebase. Save will fail in the off-line.
     - parameter completion: If successful reference will return. An error will return if it fails.
     */
    public func save(_ completion: ((FIRDatabaseReference?, Error?) -> Void)?) {
        
        if self.id == self.tmpID || self.id == self._id {
            
            var value: [String: Any] = self.value
            
            let timestamp: AnyObject = FIRServerValue.timestamp() as AnyObject
            
            value["_createdAt"] = timestamp
            value["_updatedAt"] = timestamp
            
            var ref: FIRDatabaseReference
            if let id: String = self._id {
                ref = type(of: self).databaseRef.child(id)
            } else {
                ref = type(of: self).databaseRef.childByAutoId()
            }
            
            ref.runTransactionBlock({ (data) -> FIRTransactionResult in
                
                if data.value != nil {
                    data.value = value
                    return .success(withValue: data)
                }
                
                return .success(withValue: data)
                
            }, andCompletionBlock: { (error, committed, snapshot) in
                
                type(of: self).databaseRef.child(ref.key).observeSingleEvent(of: .value, with: { (snapshot) in
                    self.snapshot = snapshot
                    
                    // File save
                    self.saveFiles(block: { (error) in
                        completion?(ref, error as Error?)
                    })
                    
                })
                
            }, withLocalEvents: false)
            
        } else {
            let error: IngredientError = IngredientError(kind: .invalidId, description: "It has been saved with an invalid ID.")
            completion?(nil, error)
        }
    }
    
    var timeout: Float = 20
    let uploadQueue: DispatchQueue = DispatchQueue(label: "salada.upload.queue")
    
    private func saveFiles(block: ((Error?) -> Void)?) {
        
        DispatchQueue.global(qos: .default).async {
            let group: DispatchGroup = DispatchGroup()
            var uploadTasks: [FIRStorageUploadTask] = []
            var hasError: Error? = nil
            let workItem: DispatchWorkItem = DispatchWorkItem {
                for (key, value) in Mirror(reflecting: self).children {
                    
                    guard let key: String = key else {
                        break
                    }
                    
                    if self.ignore.contains(key) {
                        break
                    }
                    
                    let mirror: Mirror = Mirror(reflecting: value)
                    let subjectType: Any.Type = mirror.subjectType
                    if subjectType == File?.self || subjectType == File.self {
                        if let file: File = value as? File {
                            group.enter()
                            if let task: FIRStorageUploadTask = file.save(key, completion: { (meta, error) in
                                if let error: Error = error {
                                    hasError = error
                                    uploadTasks.forEach({ (task) in
                                        task.cancel()
                                    })
                                    group.leave()
                                    return
                                }
                                group.leave()
                            }) {
                                uploadTasks.append(task)
                            }
                        }
                    }
                }
            }
            
            self.uploadQueue.async(group: group, execute: workItem)
            group.notify(queue: DispatchQueue.main, execute: {
                block?(hasError)
            })
            switch group.wait(timeout: .now() + Double(Int64(4 * Double(NSEC_PER_SEC)))) {
            case .success: break
            case .timedOut:
                uploadTasks.forEach({ (task) in
                    task.cancel()
                })
                let error: IngredientError = IngredientError(kind: .timeout, description: "Save the file timeout.")
                block?(error)
            }
        }
    }
    
    // MARK: - Transaction
    
    /**
     Set new value. Save will fail in the off-line.
     - parameter key:
     - parameter value:
     - parameter completion: If successful reference will return. An error will return if it fails.
     */
    
    private var transactionBlock: ((FIRDatabaseReference?, Error?) -> Void)?
    
    public func transaction(key: String, value: Any, completion: ((FIRDatabaseReference?, Error?) -> Void)?) {
        
        self.transactionBlock = completion
        self.setValue(value, forKey: key)
        
    }
    
    // MARK: Delete
    
    open func remove() {
        let id: String = self.id
        type(of: self).databaseRef.child(id).removeValue()
    }
    
    // MARK: Tasting
    
    /**
     A function that gets all data from DB whose name is model.
     */
    public static func observeSingle(_ eventType: FIRDataEventType, block: @escaping ([Ingredient]) -> Void) {
        self.databaseRef.observeSingleEvent(of: eventType, with: { (snapshot) in
            if snapshot.exists() {
                var children: [Ingredient] = []
                snapshot.children.forEach({ (snapshot) in
                    if let snapshot: FIRDataSnapshot = snapshot as? FIRDataSnapshot {
                        if let tsp: Ingredient = self.init(snapshot: snapshot) {
                            children.append(tsp)
                        }
                    }
                })
                block(children)
            } else {
                block([])
            }
        })
    }
    
    /**
     A function that gets data of ID within the variable form DB selected.
     */
    public static func observeSingle(_ id: String, eventType: FIRDataEventType, block: @escaping (Ingredient?) -> Void) {
        self.databaseRef.child(id).observeSingleEvent(of: eventType, with: { (snapshot) in
            if snapshot.exists() {
                if let tsp: Ingredient = self.init(snapshot: snapshot) {
                    block(tsp)
                }
            } else {
                block(nil)
            }
        })
    }
    
    /**
     A function gets what matches the data stored in childkey.
     */
    public static func observeSingle(child key: String, equal value: String, eventType: FIRDataEventType, block: @escaping ([Ingredient]) -> Void) {
        self.databaseRef.queryOrdered(byChild: key).queryEqual(toValue: value).observeSingleEvent(of: eventType, with: { (snapshot) in
            if snapshot.exists() {
                var children: [Ingredient] = []
                snapshot.children.forEach({ (snapshot) in
                    if let snapshot: FIRDataSnapshot = snapshot as? FIRDataSnapshot {
                        if let tsp: Ingredient = self.init(snapshot: snapshot) {
                            children.append(tsp)
                        }
                    }
                })
                block(children)
            } else {
                block([])
            }
        })
    }
    
    /**
     A function that gets all data from DB whenever DB has been changed.
     */
    public static func observe(_ eventType: FIRDataEventType, block: @escaping ([Ingredient]) -> Void) -> UInt {
        return self.databaseRef.observe(eventType, with: { (snapshot) in
            if snapshot.exists() {
                var children: [Ingredient] = []
                snapshot.children.forEach({ (snapshot) in
                    if let snapshot: FIRDataSnapshot = snapshot as? FIRDataSnapshot {
                        if let tsp: Ingredient = self.init(snapshot: snapshot) {
                            children.append(tsp)
                        }
                    }
                })
            } else {
                block([])
            }
        })
    }
    
    /**
     A function that gets data of ID within the variable from DB whenever data of the ID has been changed.
     */
    public static func observe(_ id: String, eventType: FIRDataEventType, block: @escaping (Ingredient?) -> Void) -> UInt {
        return self.databaseRef.child(id).observe(eventType, with: { (snapshot) in
            if snapshot.exists() {
                if let tsp: Ingredient = self.init(snapshot: snapshot) {
                    block(tsp)
                }
            } else {
                block(nil)
            }
        })
    }
    
    /**
     Remove the observer.
     */
    public static func removeObserver(with handle: UInt) {
        self.databaseRef.removeObserver(withHandle: handle)
    }
    
    /**
     Remove the observer.
     */
    public static func removeObserver(_ id: String, with handle: UInt) {
        self.databaseRef.child(id).removeObserver(withHandle: handle)
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
            
            if let value: Any = object.value(forKey: keyPath) as Any? {
                if let _: File = value as? File {
                    if let change: [NSKeyValueChangeKey: Any] = change as [NSKeyValueChangeKey: Any]? {
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
                } else if let _: Set<String> = value as? Set<String> {
                    
                    if let change: [NSKeyValueChangeKey: Any] = change as [NSKeyValueChangeKey: Any]? {
                        
                        let new: Set<String> = change[.newKey] as! Set<String>
                        let old: Set<String> = change[.oldKey] as! Set<String>
                        
                        // Added
                        new.subtracting(old).forEach({ (id) in
                            updateValue(keyPath, child: id, value: true)
                        })
                        
                        // Remove
                        old.subtracting(new).forEach({ (id) in
                            updateValue(keyPath, child: id, value: nil)
                        })
                        
                    }
                } else if let values: [String] = value as? [String] {
                    if values.isEmpty { return }
                    updateValue(keyPath, child: nil, value: value)
                } else if let value: String = value as? String {
                    updateValue(keyPath, child: nil, value: value)
                } else {
                    updateValue(keyPath, child: nil, value: value)
                }
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    // update value & update timestamp
    // Value will be deleted if the nil.
    private func updateValue(_ keyPath: String, child: String?, value: Any?) {
        let reference: FIRDatabaseReference = type(of: self).databaseRef.child(self.id)
        let timestamp: AnyObject = FIRServerValue.timestamp() as AnyObject
        
        if let value: Any = value {
            var path: String = keyPath
            if let child: String = child {
                path = "\(keyPath)/\(child)"
            }
            //reference.updateChildValues([path: value, "_updatedAt": timestamp])
            reference.updateChildValues([path: value, "_updatedAt": timestamp], withCompletionBlock: { (error, ref) in
                self.transactionBlock?(ref, error)
                self.transactionBlock = nil
            })
        } else {
            if let childKey: String = child {
                reference.child(keyPath).child(childKey).removeValue()
            }
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
    
    override open var description: String {
        let mirror: Mirror = Mirror(reflecting: self)
        let values: String = mirror.children.reduce("") { (result, children) -> String in
            guard let label: String = children.0 else {
                return result
            }
            return result + "  \(label): \(children.1)\n"
        }
        let _self: String = String(describing: Mirror(reflecting: self).subjectType).components(separatedBy: ".").first!
        return "\(_self) {\n\(values)}"
    }
    
    // MARK: -
    
    public class File: NSObject {
        
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
        
        public func save(_ keyPath: String) -> FIRStorageUploadTask? {
            return self.save(keyPath, completion: nil)
        }
        
        public func save(_ keyPath: String, completion: ((FIRStorageMetadata?, Error?) -> Void)?) -> FIRStorageUploadTask? {
            if let data: Data = self.data, let parent: Ingredient = self.parent {
                // If parent have uploadTask cancel
                parent.uploadTasks[keyPath]?.cancel()
                self.downloadTask?.cancel()
                self.uploadTask = self.ref?.put(data, metadata: self.metadata) { (metadata, error) in
                    self.metadata = metadata
                    if let error: Error = error as Error? {
                        completion?(metadata, error)
                        return
                    }
                    type(of: parent).databaseRef.child(parent.id).child(keyPath).setValue(self.name, withCompletionBlock: { (error, ref) in
                        parent.uploadTasks.removeValue(forKey: keyPath)
                        self.uploadTask = nil
                        completion?(metadata, error as Error?)
                    })
                }
                parent.uploadTasks[keyPath] = self.uploadTask
                return self.uploadTask
            } else {
                let error: IngredientError = IngredientError(kind: .invalidFile, description: "It requires data when you save the file")
                completion?(nil, error)
            }
            return nil
        }
        
        // MARK: - Load
        
        public func dataWithMaxSize(_ size: Int64, completion: @escaping (Data?, Error?) -> Void) -> FIRStorageDownloadTask? {
            self.downloadTask?.cancel()
            let task: FIRStorageDownloadTask? = self.ref?.data(withMaxSize: size, completion: { (data, error) in
                self.downloadTask = nil
                completion(data, error as Error?)
            })
            self.downloadTask = task
            return task
        }
        
        public func remove() {
            self.remove(nil)
        }
        
        public func remove(_ completion: ((Error?) -> Void)?) {
            self.ref?.delete(completion: { (error) in
                completion?(error)
            })
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

func == (lhs: Ingredient, rhs: Ingredient) -> Bool {
    return lhs.id == rhs.id
}

public typealias SaladaChange = (deletions: [Int], insertions: [Int], modifications: [Int])

public enum SaladaCollectionChange {
    
    case initial
    
    case update(SaladaChange)
    
    case error(Error)
    
    static func fromObject(change: SaladaChange?, error: Error?) -> SaladaCollectionChange {
        if let error: Error = error {
            return .error(error)
        }
        if let change: SaladaChange = change {
            return .update(change)
        }
        return .initial
    }
}

open class SaladaOptions {
    var limit: UInt = 30
    var ascending: Bool = false
    var isFetchEnabled: Bool = false
    var sortKey: String?
}

/// Datasource class.
/// Observe at a Firebase Database location.
open class Salada<Parent, Child> where Parent: Referenceable, Parent: Ingredient, Child: Referenceable, Child: Ingredient {
    
    /// DatabaseReference
    
    public var databaseRef: FIRDatabaseReference { return FIRDatabase.database().reference() }
    
    public var count: Int {
        return self.isFetchEnabled ? self._fetchedObjects.count : pool.count
    }
    
    internal var pool: [String] = []
    
    public var objects: [String] {
        return self.pool
    }
    
    internal var _fetchedObjects: [Child] = []
    
    public var fetchedObjects: [Child] {
        return self._fetchedObjects
    }
    
    fileprivate(set) var parentRef: FIRDatabaseReference
    
    fileprivate(set) var reference: FIRDatabaseReference
    
    fileprivate(set) var parentKey: String
    
    fileprivate(set) var referenceKey: String
    
    fileprivate(set) var limit: UInt = 30
    
    fileprivate(set) var ascending: Bool = false
    
    fileprivate(set) var isFetchEnabled: Bool = false
    
    fileprivate(set) var sortKey: String = "id"
    
    deinit {
        self.reference.removeAllObservers()
        if let handle: UInt = self.addedHandle {
            self.addReference?.removeObserver(withHandle: handle)
        }
    }
    
    private var addReference: FIRDatabaseQuery?
    
    fileprivate var addedHandle: UInt?
    fileprivate var changedHandle: UInt?
    fileprivate var removedHandle: UInt?
    
    private var changedBlock: (SaladaCollectionChange) -> Void
    
    public init(parentKey: String, referenceKey: String, options: SaladaOptions?, block: @escaping (SaladaCollectionChange) -> Void ) {
        
        if let options: SaladaOptions = options {
            self.limit = options.limit
            self.ascending = options.ascending
            self.isFetchEnabled = options.isFetchEnabled
            if let sortKey: String = options.sortKey {
                self.sortKey = sortKey
            }
        }
        
        self.parentKey = parentKey
        
        self.referenceKey = referenceKey
        
        self.parentRef = Parent.databaseRef.child(parentKey)
        
        self.reference = self.parentRef.child(referenceKey)
        
        self.changedBlock = block
        
        let isFetchEnabled: Bool = self.isFetchEnabled
        
        prev(at: nil, toLast: self.limit, fetched: isFetchEnabled) { [weak self] (change, error) in
            
            block(SaladaCollectionChange.fromObject(change: nil, error: error))
            
            guard let strongSelf = self else { return }
            
            // add
            var addReference: FIRDatabaseQuery = strongSelf.reference
            if let fiarstKey: String = strongSelf.pool.first {
                addReference = addReference.queryOrderedByKey().queryStarting(atValue: fiarstKey)
            }
            strongSelf.addReference = addReference
            strongSelf.addedHandle = addReference.observe(.childAdded, with: { [weak self] (snapshot) in
                objc_sync_enter(self)
                let key: String = snapshot.key
                if !strongSelf.pool.contains(key) {
                    strongSelf.pool.append(key)
                    strongSelf.pool = strongSelf.sortedPool
                    if isFetchEnabled {
                        Child.databaseRef.child(key).observeSingleEvent(of: .value, with: { (snapshot) in
                            if snapshot.exists() {
                                if let tsp: Child = Child(snapshot: snapshot) {
                                    strongSelf._fetchedObjects.append(tsp)
                                    strongSelf._fetchedObjects = strongSelf.sortedFetchedObjects
                                    if let i: Int = strongSelf._fetchedObjects.index(of: tsp) {
                                        block(SaladaCollectionChange.fromObject(change: (deletions: [], insertions: [i], modifications: []), error: nil))
                                    }
                                }
                            }
                        })
                    } else {                        
                        if let i: Int = strongSelf.pool.index(of: key) {
                            block(SaladaCollectionChange.fromObject(change: (deletions: [], insertions: [i], modifications: []), error: nil))
                        }
                    }
                }
                objc_sync_exit(self)
                }, withCancel: { (error) in
                    block(SaladaCollectionChange.fromObject(change: nil, error: error))
            })
            
            // change
            strongSelf.changedHandle = strongSelf.reference.observe(.childChanged, with: { (snapshot) in
                let key: String = snapshot.key
                if isFetchEnabled {
                    Child.databaseRef.child(key).observeSingleEvent(of: .value, with: { (snapshot) in
                        if snapshot.exists() {
                            if let tsp: Child = Child(snapshot: snapshot) {
                                if let removeIndex: Int = strongSelf._fetchedObjects.index(of: tsp) {
                                    strongSelf._fetchedObjects.remove(at: removeIndex)
                                    strongSelf._fetchedObjects.append(tsp)
                                    strongSelf._fetchedObjects = strongSelf.sortedFetchedObjects
                                    if let addIndex: Int = strongSelf._fetchedObjects.index(of: tsp) {
                                        
                                        if removeIndex == addIndex {
                                            block(SaladaCollectionChange.fromObject(change: (deletions: [], insertions: [], modifications: [addIndex]), error: nil))
                                        } else {
                                            block(SaladaCollectionChange.fromObject(change: (deletions: [removeIndex], insertions: [addIndex], modifications: []), error: nil))
                                        }
                                    }
                                }
                            }
                        }
                    })
                } else {
                    if let i: Int = strongSelf.pool.index(of: snapshot.key) {
                        block(SaladaCollectionChange.fromObject(change: (deletions: [], insertions: [], modifications: [i]), error: nil))
                    }
                }
                
            }, withCancel: { (error) in
                block(SaladaCollectionChange.fromObject(change: nil, error: error))
            })
            
            // remove
            strongSelf.removedHandle = strongSelf.reference.observe(.childRemoved, with: { [weak self] (snapshot) in
                objc_sync_enter(self)
                let key: String = snapshot.key
                if isFetchEnabled {
                    if let i: Int = strongSelf.pool.index(of: key) {
                        strongSelf.pool.remove(at: i)
                    }
                    if let tsp: Child = strongSelf[key] {
                        if let i: Int = strongSelf._fetchedObjects.index(of: tsp) {
                            strongSelf._fetchedObjects.remove(at: i)
                            strongSelf.removeObserver(at: i)
                            block(SaladaCollectionChange.fromObject(change: (deletions: [i], insertions: [], modifications: []), error: nil))
                        }
                    }
                } else {
                    if let i: Int = strongSelf.pool.index(of: key) {
                        strongSelf.removeObserver(at: i)
                        strongSelf.pool.remove(at: i)
                        block(SaladaCollectionChange.fromObject(change: (deletions: [i], insertions: [], modifications: []), error: nil))
                    }
                }
                objc_sync_exit(self)
                }, withCancel: { (error) in
                    block(SaladaCollectionChange.fromObject(change: nil, error: error))
            })
            
        }
        
    }
    
    subscript(index: Int) -> String {
        return self.pool[index]
    }
    
    subscript(key: String) -> Child? {
        for (_, object) in self._fetchedObjects.enumerated() {
            if object.id == key {
                return object
            }
        }
        return nil
    }
    
    private var isFirst: Bool = false
    
    // Firebase firstKey
    private var firstKey: String? {
        return self.ascending ? self.pool.last : self.pool.first
    }
    
    // Firebase lastKey
    private var lastKey: String? {
        return self.ascending ? self.pool.first : self.pool.last
    }
    
    // Sorted pool
    private var sortedPool: [String] {
        return self.pool.sorted { self.ascending ? $0 < $1 : $0 > $1 }
    }
    
    // Sorted fetchedObject
    var sortedFetchedObjects: [Child] {
        let sortKey: String = self.sortKey
        let ascending: Bool = self.ascending
        let sortDescriptor: NSSortDescriptor = NSSortDescriptor(key: sortKey, ascending: ascending)
        let sorted: [Child] = self._fetchedObjects.sort(sortDescriptors: [sortDescriptor])
        return sorted
    }
    
    /**
     It gets the oldest subsequent data of the data that are currently obtained.
     */
    public func prev() {
        self.prev(at: self.lastKey, toLast: self.limit, fetched: self.isFetchEnabled) { [weak self](change, error) in
            guard let strongSelf = self else { return }
            strongSelf.changedBlock(SaladaCollectionChange.fromObject(change: change, error: error))
        }
    }
    
    /**
     Load the previous data from the server.
     - parameter lastKey: It gets the data after the Key
     - parameter limit: It the limit of from after the lastKey.
     - parameter fetch: Decide whether to fetch the object. default no.
     - parameter block: block The block that should be called. Change if successful will be returned. An error will return if it fails.
     */
    public func prev(at lastKey: String?, toLast limit: UInt, fetched: Bool = false, block: ((SaladaChange?, Error?) -> Void)?) {
        
        if isFirst {
            block?((deletions: [], insertions: [], modifications: []), nil)
            return
        }
        
        var reference: FIRDatabaseQuery = self.reference.queryOrderedByKey()
        var limit: UInt = limit
        if let lastKey: String = lastKey {
            reference = reference.queryEnding(atValue: lastKey)
            limit = limit + 1
        }
        reference.queryLimited(toLast: limit).observeSingleEvent(of: .value, with: { [weak self] (snapshot) in
            
            guard let strongSelf = self else { return }
            
            if snapshot.childrenCount < limit {
                strongSelf.isFirst = true
            }
            
            objc_sync_enter(self)
            var changes: [Int] = []
            if strongSelf.ascending {
                for (_, child) in snapshot.children.enumerated() {
                    let key: String = (child as AnyObject).key
                    if !strongSelf.pool.contains(key) {
                        strongSelf.pool.append(key)
                        strongSelf.pool = strongSelf.sortedPool
                        if let i: Int = strongSelf.pool.index(of: key) {
                            changes.append(i)
                            
                            // fetch object
                            if fetched {
                                Child.databaseRef.child(key).observeSingleEvent(of: .value, with: { (snapshot) in
                                    if snapshot.exists() {
                                        if let tsp: Child = Child(snapshot: snapshot) {
                                            strongSelf._fetchedObjects.append(tsp)
                                            strongSelf._fetchedObjects = strongSelf.sortedFetchedObjects
                                            if let i: Int = strongSelf._fetchedObjects.index(of: tsp) {
                                                block?((deletions: [], insertions: [i], modifications: []), nil)
                                            }
                                        }
                                    } else {
                                        block?(nil, nil)
                                    }
                                })
                            }
                        }
                    }
                }
            } else {
                for (_, child) in snapshot.children.reversed().enumerated() {
                    let key: String = (child as AnyObject).key
                    if !strongSelf.pool.contains(key) {
                        strongSelf.pool.append(key)
                        strongSelf.pool = strongSelf.sortedPool
                        if let i: Int = strongSelf.pool.index(of: key) {
                            changes.append(i)
                            
                            // fetch object
                            if fetched {
                                Child.databaseRef.child(key).observeSingleEvent(of: .value, with: { (snapshot) in
                                    if snapshot.exists() {
                                        if let tsp: Child = Child(snapshot: snapshot) {
                                            strongSelf._fetchedObjects.append(tsp)
                                            strongSelf._fetchedObjects = strongSelf.sortedFetchedObjects
                                            if let i: Int = strongSelf._fetchedObjects.index(of: tsp) {
                                                block?((deletions: [], insertions: [i], modifications: []), nil)
                                            }
                                        }
                                    } else {
                                        block?(nil, nil)
                                    }
                                })
                            }
                        }
                    }
                }
            }
            objc_sync_exit(self)
            
            if !fetched {
                block?((deletions: [], insertions: changes, modifications: []), nil)
            }
            
        }) { (error) in
            block?(nil, error)
        }
        
    }
    
    /**
     Remove object
     - parameter index: Order of the data source
     - parameter cascade: Also deletes the data of the reference case of `true`.
     - parameter block: block The block that should be called. If there is an error it returns an error.
     */
    public func removeObject(at index: Int, cascade: Bool, block: @escaping (Error?) -> Void) {
        let key: String = self.pool[index]
        
        if cascade {
            let parentPath: AnyHashable = "/\(Parent._path)/\(parentKey)/\(self.reference.key)/\(key)"
            let childPath: AnyHashable = "/\(Child._path)/\(key)"
            
            self.databaseRef.updateChildValues([parentPath : NSNull(), childPath: NSNull()]) { (error, ref) in
                if let error: Error = error {
                    block(error)
                    return
                }
                block(nil)
            }
        } else {
            self.reference.child(key).removeValue(completionBlock: { (error, ref) in
                if let error: Error = error {
                    block(error)
                    return
                }
                block(nil)
            })
        }
        
    }
    
    /**
     Removes all observers at the reference of key
     - parameter index: Order of the data source
     */
    public func removeObserver(at index: Int) {
        if index < self.pool.count {
            let key: String = self.pool[index]
            Child.databaseRef.child(key).removeAllObservers()
        }
    }
    
    public func object(at index: Int) -> Child {
        return self._fetchedObjects[index]
    }
    
    /**
     Get an object from a data source
     - parameter index: Order of the data source
     - parameter block: block The block that should be called.  It is passed the data as a Tsp.
     */
    public func object(at index: Int, block: @escaping (Child?) -> Void) {
        if self.isFetchEnabled {
            let tsp: Child = self._fetchedObjects[index]
            block(tsp)
        } else {
            let key: String = self.pool[index]
            Child.databaseRef.child(key).observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.exists() {
                    if let tsp: Child = Child(snapshot: snapshot) {
                        block(tsp)
                    }
                } else {
                    block(nil)
                }
            })
        }
    }
    
    /**
     Get an object from a data source and observe object changess
     It is need `removeObserver`
     - parameter index: Orderr of the data source
     - parameter block: block The block that should be called.  It is passed the data as a Tsp.
     - see removeObserver
     */
    public func observeObject(at index: Int, block: @escaping (Child?) -> Void) {
        if self.isFetchEnabled {
            let tsp: Child = self._fetchedObjects[index]
            block(tsp)
            let key: String = tsp.id
            Child.databaseRef.child(key).observe(.value, with: { (snapshot) in
                if snapshot.exists() {
                    if let tsp: Child = Child(snapshot: snapshot) {
                        block(tsp)
                    }
                } else {
                    block(nil)
                }
            }) { (error) in
                block(nil)
            }
        } else {
            let key: String = self.pool[index]
            Child.databaseRef.child(key).observe(.value, with: { (snapshot) in
                if snapshot.exists() {
                    if let tsp: Child = Child(snapshot: snapshot) {
                        block(tsp)
                    }
                } else {
                    block(nil)
                }
            }) { (error) in
                block(nil)
            }
        }
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

extension Sequence where Iterator.Element: Ingredient {
    
    public func sort(sortDescriptors theSortDescs: [NSSortDescriptor]) -> [Self.Iterator.Element] {
        let objs = self.flatMap { return $0 }
        return objs.sorted {
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
