//
//  Object.swift
//  Salada
//
//  Created by nori on 2017/05/29.
//  Copyright © 2017年 Stamp. All rights reserved.
//

import FirebaseDatabase
import FirebaseStorage

open class Object: Base, Referenceable {
    internal struct Const {
        static let createdAtKey = "_createdAt"
        static let updatedAtKey = "_updatedAt"
    }

    // MARK: -

    /// Date the Object was created
    @objc private(set) var createdAt: Date

    /// Date when Object was updated
    @objc private(set) var updatedAt: Date

    /// Object monitors the properties as they are saved.
    private(set) var _isObserved: Bool = false

    /// If all File savings do not end within this time, save will be canceled. default 20 seconds.
    open var timeout: Int {
        return SaladaApp.shared.timeout
    }

    /// If propery is set with String, its property will not be written to Firebase.
    open var ignore: [String] {
        return []
    }

    /// It is Qeueu of File upload.
    public let uploadQueue: DispatchQueue = DispatchQueue(label: "salada.upload.queue")

    /// The IndexKey of the Object.
    @objc public var id: String

    private var _ref: DatabaseReference

    /// A reference to Object.
    public var ref: DatabaseReference {
        return _ref
    }

    /// Has Files
    private var hasFiles: Bool {
        let mirror = Mirror(reflecting: self)
        for (_, child) in mirror.children.enumerated() {
            if let key: String = child.label {
                switch ValueType(key: key, value: child.value) {
                case .file: return true
                default: continue
                }
            }
        }
        return false
    }

    // MARK: - Initialize

    private func _init() {
        let mirror: Mirror = Mirror(reflecting: self)
        mirror.children.forEach { (child) in
            if child.value is Relationable {
                var relation: Relationable = child.value as! Relationable
                relation.parent = self
                relation.keyPath = child.label
            }
        }
    }

    /// Initialize Object
    public override init() {
        self.createdAt = Date()
        self.updatedAt = Date()
        self._ref = type(of: self).databaseRef.childByAutoId()
        self.id = self._ref.key
        super.init()
        self._init()
    }

    /// Initialize Object from snapshot.
    convenience required public init?(snapshot: DataSnapshot) {
        self.init()
        _setSnapshot(snapshot)
    }

    /// Initialize the object with the specified ID.
    convenience required public init?(id: String) {
        self.init()
        self.id = id
        self._ref = type(of: self).databaseRef.child(id)
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

    /// Object raw value
    public var rawValue: [AnyHashable: Any] {
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
                    case .double    (let key, let value):       object[key] = value
                    case .float     (let key, let value):       object[key] = value
                    case .string    (let key, let value):       object[key] = value
                    case .url       (let key, let value, _):    object[key] = value
                    case .date      (let key, let value, _):    object[key] = value
                    case .array     (let key, let value):       object[key] = value
                    case .set       (let key, let value, _):    object[key] = value
                    case .file      (let key, let value):
                        object[key] = value.value
                        value.owner = self
                        value.keyPath = key
                    case .nestedString(let key, let value):     object[key] = value
                    case .nestedInt(let key, let value):        object[key] = value
                    case .object(let key, let value):           object[key] = value
                    case .relation(let key, _, let relation):   object[key] = relation.value
                    case .null: break
                    }
                }
            }
        }
        return object
    }

    /// Object value
    public var value: [AnyHashable: Any] {
        var value: [AnyHashable: Any] = self.rawValue
        let timestamp: [AnyHashable : Any] = ServerValue.timestamp() as [AnyHashable : Any]
        value[Const.createdAtKey] = timestamp
        value[Const.updatedAtKey] = timestamp
        return value
    }

    /// Package
    public func pack() -> Package {
        var package: Package = Package(self)
        let mirror: Mirror = Mirror(reflecting: self)
        mirror.children.forEach { (child) in
            if child.value is Relationable {
                let relation: Relationable = child.value as! Relationable
                package.merge(relation.pack())
            }
        }
        return package
    }

    // MARK: - Snapshot

    public var snapshot: DataSnapshot? {
        didSet {
            if let snapshot: DataSnapshot = snapshot {

                self._ref = snapshot.ref
                self.id = snapshot.key

                guard let snapshot: [String: Any] = snapshot.value as? [String: Any] else { return }

                let createdAt: Double = snapshot[Const.createdAtKey] as! Double
                let updatedAt: Double = snapshot[Const.updatedAtKey] as! Double

                let createdAtTimestamp: TimeInterval = (createdAt / 1000)
                let updatedAtTimestamp: TimeInterval = (updatedAt / 1000)

                self.createdAt = Date(timeIntervalSince1970: createdAtTimestamp)
                self.updatedAt = Date(timeIntervalSince1970: updatedAtTimestamp)

                Mirror(reflecting: self).children.forEach { (key, value) in
                    if let key: String = key {
                        if !self.ignore.contains(key) {
                            if let _: Any = self.decode(key, value: snapshot[key]) {
                                self.addObserver(self, forKeyPath: key, options: [.new, .old], context: nil)
                                return
                            }
                            switch ValueType(key: key, value: value, snapshot: snapshot) {
                            case .bool(let key, let value): self.setValue(value, forKey: key)
                            case .int(let key, let value): self.setValue(value, forKey: key)
                            case .float(let key, let value): self.setValue(value, forKey: key)
                            case .double(let key, let value): self.setValue(value, forKey: key)
                            case .string(let key, let value): self.setValue(value, forKey: key)
                            case .url(let key, _, let value): self.setValue(value, forKey: key)
                            case .date(let key, _, let value): self.setValue(value, forKey: key)
                            case .array(let key, let value): self.setValue(value, forKey: key)
                            case .set(let key, _, let value): self.setValue(value, forKey: key)
                            case .file(let key, let file):
                                file.owner = self
                                file.keyPath = key
                                self.setValue(file, forKey: key)
                            case .nestedString(let key, let value): self.setValue(value, forKey: key)
                            case .nestedInt(let key, let value): self.setValue(value, forKey: key)
                            case .object(let key, let value): self.setValue(value, forKey: key)
                            case .relation(let key, let value, let relation): relation.setValue(value, forKey: key)
                            case .null: break
                            }
                            self.addObserver(self, forKeyPath: key, options: [.new, .old], context: nil)
                        }
                    }
                }
                self._isObserved = true
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
                                old.owner = self
                                old.keyPath = keyPath
                                old.remove()
                            }
                            return
                        }
                        if let old: File = change[.oldKey] as? File {
                            if old.name != new.name {
                                new.owner = self
                                new.keyPath = keyPath
                                old.owner = self
                                old.keyPath = keyPath
                            }
                        } else {
                            new.owner = self
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

                if let values: [Any] = value as? [Any] {
                    if values.isEmpty { return }
                    updateValue(keyPath, child: nil, value: value)
                } else if let value: String = value as? String {
                    updateValue(keyPath, child: nil, value: value)
                } else if let value: Date = value as? Date {
                    updateValue(keyPath, child: nil, value: value.timeIntervalSince1970)
                } else if let value: URL = value as? URL {
                    updateValue(keyPath, child: nil, value: value.absoluteString)
                } else {
                    updateValue(keyPath, child: nil, value: value)
                }
            } else {
                // remove value
                updateValue(keyPath, child: nil, value: nil)
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }

    /**
     Update the data on Firebase.
     When this function is called, updatedAt of Object is updated at the same time.

     - parameter keyPath: Target key path
     - parameter child: Target child
     - parameter value: Save to value. If you enter nil, the data will be deleted.
     */
    internal func updateValue(_ keyPath: String, child: String?, value: Any?) {
        let reference: DatabaseReference = self.ref
        let timestamp: [AnyHashable : Any] = ServerValue.timestamp() as [AnyHashable : Any]
        SaladaApp.cache?.removeObject(forKey: reference.url as AnyObject)
        let updateValue: Any = value.map { $0 } ?? NSNull()
        let path = child.map { "\(keyPath)/\($0)" } ?? keyPath
        reference.updateChildValues([path: updateValue, Const.updatedAtKey: timestamp], withCompletionBlock: {_,_ in
            // Nothing
        })
    }

    // MARK: - Save

    @discardableResult
    /**
     Save the new Object to Firebase.
     */
    public func save() -> [String: StorageUploadTask] {
        return self.save(nil)
    }

    /**
     Save the new Object to Firebase. Save will fail in the off-line.
     - parameter completion: If successful reference will return. An error will return if it fails.
     */
    @discardableResult
    public func save(_ block: ((DatabaseReference?, Error?) -> Void)?) -> [String: StorageUploadTask] {
        if isObserved {
            fatalError("[Salada.Object] *** error: \(type(of: self)) has already been saved.")
        }
        let ref: DatabaseReference = self.ref
        if self.hasFiles {
            return self.saveFiles { (error) in
                if let error = error {
                    block?(ref, error)
                    return
                }
                self._save(block)
            }
        } else {
            _save(block)
            return [:]
        }
    }

    private func _save(_ block: ((DatabaseReference?, Error?) -> Void)?) {
        self.pack().submit { (ref, error) in
            self.ref.observeSingleEvent(of: .value, with: { (snapshot) in
                self.snapshot = snapshot
                block?(snapshot.ref, error)
            })
        }
    }

    // MARK: - Transaction

    /**
     Save failing when offline
     */
    @available(*, deprecated, message: "use save")
    public func transactionSave(_ block: ((DatabaseReference?, Error?) -> Void)?) -> [String: StorageUploadTask] {
        return self._transactionSave(block)
    }

    private func _transactionSave(_ block: ((DatabaseReference?, Error?) -> Void)?) -> [String: StorageUploadTask] {
        let ref: DatabaseReference = self.ref
        let value: [AnyHashable: Any] = self.value
        if self.hasFiles {
            return self.saveFiles { (error) in
                if let error = error {
                    block?(nil, error)
                    return
                }
                ref.runTransactionBlock({ (currentData) -> TransactionResult in
                    currentData.value = value
                    return .success(withValue: currentData)
                }, andCompletionBlock: { (error, committed, snapshot) in
                    if committed {
                        ref.observeSingleEvent(of: .value, with: { (snapshot) in
                            self.snapshot = snapshot
                            block?(snapshot.ref, nil)
                        })
                    } else {
                        let error: ObjectError = ObjectError(kind: .offlineTransaction, description: "A transaction can not be executed when it is offline.")
                        block?(nil, error)
                    }
                }, withLocalEvents: false)
            }
        } else {
            ref.runTransactionBlock({ (currentData) -> TransactionResult in
                currentData.value = value
                return .success(withValue: currentData)
            }, andCompletionBlock: { (error, committed, snapshot) in
                if committed {
                    block?(snapshot?.ref, nil)
                } else {
                    let error: ObjectError = ObjectError(kind: .offlineTransaction, description: "A transaction can not be executed when it is offline.")
                    block?(nil, error)
                }
            }, withLocalEvents: false)
            return [:]
        }
    }

    // MARK: - Remove

    public func remove() {
        SaladaApp.cache?.removeObject(forKey: ref.url as AnyObject)
        self.ref.removeValue()
        self.ref.removeAllObservers()
    }

    // MARK: - File

    /**
     Save the file set in the object.

     - parameter block: If saving succeeds or fails, this callback will be called.
     - returns: Returns the StorageUploadTask set in the property.
     */
    private func saveFiles(_ block: ((Error?) -> Void)?) -> [String: StorageUploadTask] {

        let group: DispatchGroup = DispatchGroup()
        var uploadTasks: [String: StorageUploadTask] = [:]

        var hasError: Error? = nil

        for (_, child) in Mirror(reflecting: self).children.enumerated() {

            guard let key: String = child.label else { break }
            if self.ignore.contains(key) { break }
            let value = child.value

            let mirror: Mirror = Mirror(reflecting: value)
            let subjectType: Any.Type = mirror.subjectType
            if subjectType == File?.self || subjectType == File.self {
                if let file: File = value as? File {
                    file.owner = self
                    file.keyPath = key
                    group.enter()
                    if let task: StorageUploadTask = file.save(key, completion: { (meta, error) in
                        if let error: Error = error {
                            hasError = error
                            uploadTasks.forEach({ (_, task) in
                                task.cancel()
                            })
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

    // MARK: - deinit

    deinit {
        if self._isObserved {
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

        let base: String =
            "  key: \(self.id)\n" +
                "  createdAt: \(self.createdAt)\n" +
        "  updatedAt: \(self.updatedAt)\n"

        let values: String = Mirror(reflecting: self).children.reduce(base) { (result, children) -> String in
            guard let label: String = children.0 else {
                return result
            }
            return result + "  \(label): \(children.1)\n"
        }
        let _self: String = String(describing: Mirror(reflecting: self).subjectType).components(separatedBy: ".").first!
        return "\(_self) {\n\(values)}"
    }

    public subscript(key: String) -> Any? {
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
        return self.id.hash
    }

    public static func == (lhs: Object, rhs: Object) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: -

extension Collection where Iterator.Element == String {
    func toKeys() -> [String: Bool] {
        return reduce(into: [:]) { $0[$1] = true }
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
