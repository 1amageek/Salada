//
//  Object.swift
//  Salada
//
//  Created by nori on 2017/05/29.
//  Copyright © 2017年 Stamp. All rights reserved.
//

import Firebase



open class Object: Seed {

    private(set) var key: String

    private(set) var ref: DatabaseReference

    private(set) var createdAt: Date

    private(set) var updatedAt: Date

    private(set) var isObserved: Bool = false

    public var timeout: Int {
        return 20
    }

    public let uploadQueue: DispatchQueue = DispatchQueue(label: "salada.upload.queue")

    // MARK: Initialize

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

    // MARK: Encode, Decode

    /// Model -> Firebase
    open func encode(_ key: String, value: Any?) -> Any? {
        return nil
    }

    /// Snapshot -> Model
    open func decode(_ key: String, value: Any?) -> Any? {
        return nil
    }

    // MARK: Save

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

    // MARK: Remove

    public func remove() {
        self.ref.removeValue()
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
            switch group.wait(timeout: .now() + .secounds(timeout)) {
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
}
