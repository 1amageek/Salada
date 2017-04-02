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
import FirebaseDatabase
import FirebaseStorage

open class Salada {
    
    public struct ObjectError: Error {
        enum ErrorKind {
            case invalidId
            case invalidFile
            case timeout
        }
        let kind: ErrorKind
        let description: String
    }
    
    /**
     Object is a class that defines the Scheme to Firebase.
     Once saved Object, save to the server in real time by KVO changes.
     Changes are run even offline.
     
     Please observe the following rules.
     1. Declaration the Element
     1. Class other than the Foundation description 'decode, 'encode'
     */
    open class Object: NSObject, Referenceable {
        
        public typealias Element = Object
        
        enum ValueType {
            
            case string(String, String)
            case int(String, Int)
            case double(String, Double)
            case float(String, Float)
            case bool(String, Bool)
            case date(String, TimeInterval, Date)
            case url(String, String, URL)
            case array(String, [Any])
            case set(String, [String: Bool], Set<String>)
            case relation(String, [String: Bool], Relation)
            case file(String, File)
            case object(String, Any)
            case null
            
            init(key: String, value: Any) {
                switch value.self {
                case is String:         if let value: String        = value as? String      { self = .string(key, value); return }
                case is URL:            if let value: URL           = value as? URL         { self = .url(key, value.absoluteString, value); return }
                case is Date:           if let value: Date          = value as? Date        { self = .date(key, value.timeIntervalSince1970, value); return }
                case is Int:            if let value: Int           = value as? Int         { self = .int(key, Int(value)); return }
                case is Double:         if let value: Double        = value as? Double      { self = .double(key, Double(value)); return }
                case is Float:          if let value: Float         = value as? Float       { self = .float(key, Float(value)); return }
                case is Bool:           if let value: Bool          = value as? Bool        { self = .bool(key, Bool(value)); return }
                case is [String]:       if let value: [String]      = value as? [String], !value.isEmpty { self = .array(key, value) }
                case is Set<String>:    if let value: Set<String>   = value as? Set<String>, !value.isEmpty { self = .set(key, value.toKeys(), value); return }
                case is Relation:       if let value: Relation      = value as? Relation    { self = .relation(key, value.toKeys(), value); return }
                case is File:           if let value: File          = value as? File        { self = .file(key, value); return }
                case is [String: Any]:  if let value: [String: Any] = value as? [String: Any] { self = .object(key, value); return }
                default: self = .null
                }
                self = .null
            }
            
            init(key: String, mirror: Mirror, snapshot: [AnyHashable: Any]) {
                let subjectType: Any.Type = mirror.subjectType
                if subjectType == String.self || subjectType == String?.self {
                    if let value: String = snapshot[key] as? String {
                        self = .string(key, value)
                        return
                    }
                } else if subjectType == URL.self || subjectType == URL?.self {
                    if
                        let value: String = snapshot[key] as? String,
                        let url: URL = URL(string: value)  {
                        self = .url(key, value, url)
                        return
                    }
                } else if subjectType == Date.self || subjectType == Date?.self {
                    if let value: Double = snapshot[key] as? Double {
                        let date: Date = Date(timeIntervalSince1970: TimeInterval(value))
                        self = .date(key, value, date)
                        return
                    }
                } else if subjectType == Double.self || subjectType == Double?.self {
                    if let value: Double = snapshot[key] as? Double {
                        self = .double(key, Double(value))
                        return
                    }
                } else if subjectType == Int.self || subjectType == Int?.self {
                    if let value: Int = snapshot[key] as? Int {
                        self = .int(key, Int(value))
                        return
                    }
                } else if subjectType == Float.self || subjectType == Float?.self {
                    if let value: Float = snapshot[key] as? Float {
                        self = .float(key, Float(value))
                        return
                    }
                } else if subjectType == Bool.self || subjectType == Bool?.self {
                    if let value: Bool = snapshot[key] as? Bool {
                        self = .bool(key, Bool(value))
                        return
                    }
                } else if subjectType == [String].self || subjectType == [String]?.self {
                    if let value: [String] = snapshot[key] as? [String], !value.isEmpty {
                        self = .array(key, value)
                        return
                    }
                } else if subjectType == Set<String>.self || subjectType == Set<String>?.self {
                    if let value: [String: Bool] = snapshot[key] as? [String: Bool], !value.isEmpty {
                        self = .set(key, value, Set<String>(value.keys))
                        return
                    }
                } else if subjectType == Relation.self || subjectType == Relation?.self {
                    if let value: [String: Bool] = snapshot[key] as? [String: Bool], !value.isEmpty {
                        self = .relation(key, value, Relation(value.keys))
                    } else {
                        self = .relation(key, [:], Relation())
                    }
                    return
                } else if subjectType == [String: Any].self || subjectType == [String: Any]?.self {
                    if let value: [String: Any] = snapshot[key] as? [String: Any] {
                        self = .object(key, value)
                        return
                    }
                } else if subjectType == File.self || subjectType == File?.self {
                    if let value: String = snapshot[key] as? String {
                        let file: File = File(name: value)
                        self = .file(key, file)
                        return
                    }
                } else {
                    self = .null
                }
                self = .null
            }
            
        }
        
        // MARK: Referenceable
        
        open class var _modelName: String {
            return String(describing: Mirror(reflecting: self).subjectType).components(separatedBy: ".").first!.lowercased()
        }
        
        open class var _version: String {
            return "v1"
        }
        
        open class var _path: String {
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
                                switch ValueType(key: key, mirror: mirror, snapshot: snapshot) {
                                case .string(let key, let value): self.setValue(value, forKey: key)
                                case .int(let key, let value): self.setValue(value, forKey: key)
                                case .float(let key, let value): self.setValue(value, forKey: key)
                                case .double(let key, let value): self.setValue(value, forKey: key)
                                case .bool(let key, let value): self.setValue(value, forKey: key)
                                case .url(let key, _, let value): self.setValue(value, forKey: key)
                                case .date(let key, _, let value): self.setValue(value, forKey: key)
                                case .array(let key, let value): self.setValue(value, forKey: key)
                                case .set(let key, _, let value): self.setValue(value, forKey: key)
                                case .relation(let key, _, let relation):
                                    relation.owner = self
                                    relation.keyPath = key
                                    self.setValue(relation, forKey: key)
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
            type(of: self).databaseRef.child(self.id).keepSynced(true)
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
        
        open var ignore: [String] {
            return []
        }
        
        private(set) var hasObserve: Bool = false
        
        public var value: [AnyHashable: Any] {
            let mirror = Mirror(reflecting: self)
            var object: [String: Any] = [:]
            mirror.children.forEach { (key, value) in
                if let key: String = key {
                    if !self.ignore.contains(key) {
                        if let newValue: Any = self.encode(key, value: value) {
                            object[key] = newValue
                            return
                        }
                        
                        switch ValueType(key: key, value: value) {
                        case .string    (let key, let value):       object[key] = value
                        case .double    (let key, let value):       object[key] = value
                        case .int       (let key, let value):       object[key] = value
                        case .float     (let key, let value):       object[key] = value
                        case .bool      (let key, let value):       object[key] = value
                        case .url       (let key, let value, _):    object[key] = value
                        case .date      (let key, let value, _):    object[key] = value
                        case .array     (let key, let value):       object[key] = value
                        case .set       (let key, let value, _):    object[key] = value
                        case .relation  (let key, let value, _):    object[key] = value
                        case .file      (let key, let value):
                            object[key] = value.name
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
        
        // MARK: - Encode, Decode
        
        /// Model -> Firebase
        open func encode(_ key: String, value: Any?) -> Any? {
            return nil
        }
        
        /// Snapshot -> Model
        open func decode(_ key: String, value: Any?) -> Any? {
            return nil
        }
        
        // MARK: - Save
        
        @discardableResult
        public func save() -> [String: FIRStorageUploadTask] {
            return self.save(nil)
        }
        
        /**
         Save the new Object to Firebase. Save will fail in the off-line.
         - parameter completion: If successful reference will return. An error will return if it fails.
         */
        @discardableResult
        public func save(_ completion: ((FIRDatabaseReference?, Error?) -> Void)?) -> [String: FIRStorageUploadTask] {
            
            if self.id == self.tmpID || self.id == self._id {
                
                var value: [AnyHashable: Any] = self.value
                
                let timestamp: AnyObject = FIRServerValue.timestamp() as AnyObject
                
                value["_createdAt"] = timestamp
                value["_updatedAt"] = timestamp
                
                var ref: FIRDatabaseReference
                if let id: String = self._id {
                    ref = type(of: self).databaseRef.child(id)
                } else {
                    ref = type(of: self).databaseRef.childByAutoId()
                }
                
                self.tmpID = ref.key
                
                return self.saveFiles(block: { (error) in
                    if let error = error {
                        completion?(ref, error)
                        return
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
                            completion?(ref, error)
                        })
                        
                    }, withLocalEvents: false)
                    
                })
                
            } else {
                let error: ObjectError = ObjectError(kind: .invalidId, description: "It has been saved with an invalid ID.")
                completion?(nil, error)
                return [:]
            }
            
        }
        
        var timeout: Float = 20
        let uploadQueue: DispatchQueue = DispatchQueue(label: "salada.upload.queue")
        
        private func saveFiles(block: ((Error?) -> Void)?) -> [String: FIRStorageUploadTask] {
            
            let group: DispatchGroup = DispatchGroup()
            var uploadTasks: [String: FIRStorageUploadTask] = [:]
            
            var hasError: Error? = nil
            
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
                                uploadTasks.forEach({ (_, task) in
                                    task.cancel()
                                })
                                group.leave()
                                return
                            }
                            group.leave()
                        }) {
                            uploadTasks[key] = task
                        }
                    }
                }
            }
            
            DispatchQueue.global(qos: .default).async {
                group.notify(queue: DispatchQueue.main, execute: {
                    block?(hasError)
                })
                switch group.wait(timeout: .now() + Double(Int64(4 * Double(NSEC_PER_SEC)))) {
                case .success: break
                case .timedOut:
                    uploadTasks.forEach({ (_, task) in
                        task.cancel()
                    })
                    let error: ObjectError = ObjectError(kind: .timeout, description: "Save the file timeout.")
                    block?(error)
                }
            }
            
            return uploadTasks
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
        
        // MARK: - Delete
        
        public func remove() {
            let id: String = self.id
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
                
                if let value: Any = object.value(forKey: keyPath) as Any? {
                    
                    // File
                    if let _: File = value as? File {
                        if let change: [NSKeyValueChangeKey: Any] = change as [NSKeyValueChangeKey: Any]? {
                            guard let new: File = change[.newKey] as? File else {
                                if let old: File = change[.oldKey] as? File {
                                    old.parent = self
                                    old.keyPath = keyPath
                                    old.remove()
                                }
                                return
                            }
                            if let old: File = change[.oldKey] as? File {
                                if old.name != new.name {
                                    new.parent = self
                                    new.keyPath = keyPath
                                    old.parent = self
                                    old.keyPath = keyPath
                                }
                            }
                        }
                        return
                    }
                    
                    // Set
                    if let _: Set<String> = value as? Set<String> {
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
                        return
                    }
                    
                    // Relation
                    // TODO:
                    /*
                     if let _: Relation = value as? Relation {
                     if let change: [NSKeyValueChangeKey: Any] = change as [NSKeyValueChangeKey: Any]? {
                     
                     let new: Relation = change[.newKey] as! Relation
                     let old: Relation = change[.oldKey] as! Relation
                     
                     // TODO:
                     }
                     return
                     }*/
                    
                    
                    if let values: [String] = value as? [String] {
                        if values.isEmpty { return }
                        updateValue(keyPath, child: nil, value: value)
                    } else if let value: String = value as? String {
                        updateValue(keyPath, child: nil, value: value)
                    } else if let value: Date = value as? Date {
                        updateValue(keyPath, child: nil, value: value.timeIntervalSince1970)
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
        fileprivate func updateValue(_ keyPath: String, child: String?, value: Any?) {
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
        
        // MARK: - Observe
        
        /**
         A function that gets all data from DB whose name is model.
         */
        public class func observeSingle(_ eventType: FIRDataEventType, block: @escaping ([Object]) -> Void) {
            self.databaseRef.observeSingleEvent(of: eventType, with: { (snapshot) in
                if snapshot.exists() {
                    var children: [Object] = []
                    snapshot.children.forEach({ (snapshot) in
                        if let snapshot: FIRDataSnapshot = snapshot as? FIRDataSnapshot {
                            if let tsp: Object = self.init(snapshot: snapshot) {
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
        public class func observeSingle(_ id: String, eventType: FIRDataEventType, block: @escaping (Object?) -> Void) {
            self.databaseRef.child(id).observeSingleEvent(of: eventType, with: { (snapshot) in
                if snapshot.exists() {
                    if let tsp: Object = self.init(snapshot: snapshot) {
                        block(tsp)
                    }
                } else {
                    block(nil)
                }
            })
        }
        
        public class func observeSingle(child key: String, equal value: String, eventType: FIRDataEventType, block: @escaping ([Object]) -> Void) {
            self.databaseRef.queryOrdered(byChild: key).queryEqual(toValue: value).observeSingleEvent(of: eventType, with: { (snapshot) in
                if snapshot.exists() {
                    var children: [Object] = []
                    snapshot.children.forEach({ (snapshot) in
                        if let snapshot: FIRDataSnapshot = snapshot as? FIRDataSnapshot {
                            if let tsp: Object = self.init(snapshot: snapshot) {
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
        public class func observe(_ eventType: FIRDataEventType, block: @escaping ([Object]) -> Void) -> UInt {
            return self.databaseRef.observe(eventType, with: { (snapshot) in
                if snapshot.exists() {
                    var children: [Object] = []
                    snapshot.children.forEach({ (snapshot) in
                        if let snapshot: FIRDataSnapshot = snapshot as? FIRDataSnapshot {
                            if let tsp: Object = self.init(snapshot: snapshot) {
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
         A function that gets data of ID within the variable from DB whenever data of the ID has been changed.
         */
        public class func observe(_ id: String, eventType: FIRDataEventType, block: @escaping (Object?) -> Void) -> UInt {
            return self.databaseRef.child(id).observe(eventType, with: { (snapshot) in
                if snapshot.exists() {
                    if let tsp: Object = self.init(snapshot: snapshot) {
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
        public class func removeObserver(with handle: UInt) {
            self.databaseRef.removeObserver(withHandle: handle)
        }
        
        /**
         Remove the observer.
         */
        public class func removeObserver(_ id: String, with handle: UInt) {
            self.databaseRef.child(id).removeObserver(withHandle: handle)
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
        
        subscript(key: String) -> Any? {
            get {
                return self.value(forKey: key)
            }
            set(newValue) {
                self.setValue(newValue, forKey: key)
            }
        }
        
    }
    
}

extension Salada {
    
    public class File: NSObject {
        
        /// Save location
        public var ref: FIRStorageReference? {
            if let parent: Object = self.parent {
                return type(of: parent).storageRef.child(parent.id).child(self.name)
            }
            return nil
        }
        
        /// Save data
        public var data: Data?
        
        /// Save URL
        public var url: URL?
        
        /// File name
        public var name: String
        
        /// File metadata
        public var metadata: FIRStorageMetadata?
        
        /// Parent to hold the location where you want to save
        public var parent: Object?
        
        /// Property name to save
        public var keyPath: String?
        
        /// Firebase uploading task
        public fileprivate(set) weak var uploadTask: FIRStorageUploadTask?
        
        /// Firebase downloading task
        public fileprivate(set) weak var downloadTask: FIRStorageDownloadTask?
        
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
        
        public convenience init(url: URL) {
            let name: String = "\(Int(Date().timeIntervalSince1970 * 1000))"
            self.init(name: name)
            self.url = url
        }
        
        // MARK: - Save
        
        fileprivate func save(_ keyPath: String) -> FIRStorageUploadTask? {
            return self.save(keyPath, completion: nil)
        }
        
        fileprivate func save(_ keyPath: String, completion: ((FIRStorageMetadata?, Error?) -> Void)?) -> FIRStorageUploadTask? {
            if let data: Data = self.data, let parent: Object = self.parent {
                self.uploadTask = self.ref?.put(data, metadata: self.metadata) { (metadata, error) in
                    self.metadata = metadata
                    if let error: Error = error as Error? {
                        completion?(metadata, error)
                        return
                    }
                    if parent.hasObserve {
                        parent.updateValue(keyPath, child: nil, value: self.name)
                    } else {
                        completion?(metadata, error as Error?)
                    }
                }
                return self.uploadTask
            } else if let url: URL = self.url, let parent: Object = self.parent {
                self.uploadTask = self.ref?.putFile(url, metadata: self.metadata, completion: { (metadata, error) in
                    self.metadata = metadata
                    if let error: Error = error as Error? {
                        completion?(metadata, error)
                        return
                    }
                    if parent.hasObserve {
                        parent.updateValue(keyPath, child: nil, value: self.name)
                    } else {
                        completion?(metadata, error as Error?)
                    }
                })
                return self.uploadTask
            } else {
                let error: ObjectError = ObjectError(kind: .invalidFile, description: "It requires data when you save the file")
                completion?(nil, error)
            }
            return nil
        }
        
        public func save(completion: ((FIRStorageMetadata?, Error?) -> Void)?) -> FIRStorageUploadTask? {
            guard let parent: Object = self.parent else {
                let error: ObjectError = ObjectError(kind: .invalidFile, description: "It requires data when you save the file")
                completion?(nil, error)
                return nil
            }
            
            var task: FIRStorageUploadTask?
            for (key, value) in Mirror(reflecting: parent).children {
                
                guard let key: String = key else {
                    break
                }
                
                if parent.ignore.contains(key) {
                    break
                }
                
                let mirror: Mirror = Mirror(reflecting: value)
                let subjectType: Any.Type = mirror.subjectType
                if subjectType == File?.self || subjectType == File.self {
                    if let file: File = value as? File {
                        if file == self {
                            task = self.save(key, completion: completion)
                        }
                    }
                }
            }
            return task
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
        
        // MARK: -
        
        override public var description: String {
            return "Salada.File"
        }
        
    }
}

extension Salada.Object {
    open override var hashValue: Int {
        return self.id.hash
    }
}

public func == (lhs: Salada.Object, rhs: Salada.Object) -> Bool {
    return lhs.id == rhs.id
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

extension Sequence where Iterator.Element: Salada.Object {
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
