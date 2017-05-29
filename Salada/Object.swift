//
//  Object.swift
//  Salada
//
//  Created by nori on 2017/05/29.
//  Copyright © 2017年 Stamp. All rights reserved.
//

import Firebase

open class Object: Seed, Referenceable {

    private(set) var createdAt: Date

    private(set) var updatedAt: Date

    private(set) var isObserved: Bool = false

    public var timeout: Int {
        return 20
    }

    public var ignore: [String] {
        return []
    }

    public let uploadQueue: DispatchQueue = DispatchQueue(label: "salada.upload.queue")

    // MARK: - Initialize

    public var key: String

    private(set) var ref: DatabaseReference

    public override init() {
        self.createdAt = Date()
        self.updatedAt = Date()
        self.ref = type(of: self).databaseRef.childByAutoId()
        self.key = self.ref.key
    }

    convenience required public init?(snapshot: DataSnapshot) {
        self.init()
        _setSnapshot(snapshot)
    }

    convenience required public init?(key: String) {
        self.init()
        self.key = key
        self.ref = type(of: self).databaseRef.child(key)
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

    public var value: [AnyHashable: Any] {
        let mirror = Mirror(reflecting: self)
        var object: [AnyHashable: Any] = [:]
        mirror.children.forEach { (key, value) in
            if let key: String = key {
                if !self.ignore.contains(key) {
                    if let newValue: Any = self.encode(key, value: value) {
                        object[key] = newValue
                        return
                    }
                    switch ValueType(key: key, value: value) {
                    case .bool      (let key, let value):       object[key] = value
                    case .int       (let key, let value):       object[key] = value
                    case .uint      (let key, let value):       object[key] = value
                    case .double    (let key, let value):       object[key] = value
                    case .float     (let key, let value):       object[key] = value
                    case .string    (let key, let value):       object[key] = value
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

    // MARK: - Snapshot

    public var snapshot: DataSnapshot? {
        didSet {
            if let snapshot: DataSnapshot = snapshot {
                self.isObserved = true
                guard let snapshot: [String: Any] = snapshot.value as? [String: Any] else { return }

                let createdAtTimestamp: TimeInterval = snapshot["_createdAt"] as! TimeInterval
                let updatedAtTimestamp: TimeInterval = snapshot["_updatedAt"] as! TimeInterval

                self.createdAt = Date(timeIntervalSince1970: createdAtTimestamp)
                self.updatedAt = Date(timeIntervalSince1970: updatedAtTimestamp)

                Mirror(reflecting: self).children.forEach { (key, value) in
                    if let key: String = key {
                        if !self.ignore.contains(key) {
                            if let _: Any = self.decode(key, value: snapshot[key]) {
                                self.addObserver(self, forKeyPath: key, options: [.new, .old], context: nil)
                                return
                            }
                            let mirror: Mirror = Mirror(reflecting: value)
                            switch ValueType(key: key, mirror: mirror, snapshot: snapshot) {
                            case .bool(let key, let value): self.setValue(value, forKey: key)
                            case .int(let key, let value): self.setValue(value, forKey: key)
                            case .uint(let key, let value): self.setValue(value, forKey: key)
                            case .float(let key, let value): self.setValue(value, forKey: key)
                            case .double(let key, let value): self.setValue(value, forKey: key)
                            case .string(let key, let value): self.setValue(value, forKey: key)
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

    fileprivate func _setSnapshot(_ snapshot: DataSnapshot) {
        self.snapshot = snapshot
        self.ref.keepSynced(true)
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
                        } else {
                            new.parent = self
                            new.keyPath = keyPath
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


                if let values: [Any] = value as? [Any] {
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
    internal func updateValue(_ keyPath: String, child: String?, value: Any?) {
        let reference: DatabaseReference = self.ref
        let timestamp: AnyObject = ServerValue.timestamp() as AnyObject

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

    // MARK: - Save

    @discardableResult
    public func save() -> [String: StorageUploadTask] {
        return self.save(nil)
    }

    /**
     Save the new Object to Firebase. Save will fail in the off-line.
     - parameter completion: If successful reference will return. An error will return if it fails.
     */
    @discardableResult
    public func save(_ completion: ((DatabaseReference?, Error?) -> Void)?) -> [String: StorageUploadTask] {

        var value: [AnyHashable: Any] = self.value
        let timestamp: [AnyHashable : Any] = ServerValue.timestamp() as [AnyHashable : Any]

        value["_createdAt"] = timestamp
        value["_updatedAt"] = timestamp

        let ref: DatabaseReference = self.ref

        return self.saveFiles(block: { (error) in
            if let error = error {
                completion?(ref, error)
                return
            }

            ref.runTransactionBlock({ (data) -> TransactionResult in
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
    }

    // MARK: - Transaction

    /**
     Set new value. Save will fail in the off-line.
     - parameter key:
     - parameter value:
     - parameter completion: If successful reference will return. An error will return if it fails.
     */

    private var transactionBlock: ((DatabaseReference?, Error?) -> Void)?

    public func transaction(key: String, value: Any, completion: ((DatabaseReference?, Error?) -> Void)?) {
        self.transactionBlock = completion
        self.setValue(value, forKey: key)
    }

    // MARK: - Remove

    public func remove() {
        self.ref.removeValue()
        self.ref.removeAllObservers()
    }

    // MARK: - File

    /**

    */
    private func saveFiles(block: ((Error?) -> Void)?) -> [String: StorageUploadTask] {

        let group: DispatchGroup = DispatchGroup()
        var uploadTasks: [String: StorageUploadTask] = [:]

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
                    if let task: StorageUploadTask = file.save(key, completion: { (meta, error) in
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

        uploadQueue.async {
            group.notify(queue: DispatchQueue.main, execute: {
                block?(hasError)
            })
            switch group.wait(timeout: .now() + .seconds(self.timeout)) {
            case .success: break
            case .timedOut:
                uploadTasks.forEach({ (_, task) in
                    task.cancel()
                })
                let error: ObjectError = ObjectError(kind: .timeout, description: "Save the file timeout.")
                DispatchQueue.main.async {
                    block?(error)
                }
            }
        }
        return uploadTasks
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
    public class func removeObserver(_ key: String, with handle: UInt) {
        self.databaseRef.child(key).removeObserver(withHandle: handle)
    }

    // MARK: - deinit

    deinit {
        if self.isObserved {
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

extension Object {
    open override var hashValue: Int {
        return self.key.hash
    }
}

public func == (lhs: Object, rhs: Object) -> Bool {
    return lhs.key == rhs.key
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

extension Sequence where Iterator.Element: Object {
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
