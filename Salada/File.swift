//
//  File.swift
//  Salada
//
//  Created by nori on 2017/05/29.
//  Copyright © 2017年 Stamp. All rights reserved.
//

import Firebase

public class File: NSObject {

    /// Save location
    public var ref: StorageReference? {
        if let owner: Object = self.owner {
            return type(of: owner).storageRef.child(owner.id).child(self.name)
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
    public var metadata: StorageMetadata?

    /// Parent to hold the location where you want to save
    public var owner: Object?

    /// Property name to save
    public var keyPath: String?

    /// Firebase uploading task
    public fileprivate(set) weak var uploadTask: StorageUploadTask?

    /// Firebase downloading task
    public fileprivate(set) weak var downloadTask: StorageDownloadTask?

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

    internal func save(_ keyPath: String) -> StorageUploadTask? {
        return self.save(keyPath, completion: nil)
    }

    internal func save(_ keyPath: String, completion: ((StorageMetadata?, Error?) -> Void)?) -> StorageUploadTask? {
        if let data: Data = self.data, let owner: Object = self.owner {
            self.uploadTask = self.ref?.putData(data, metadata: self.metadata) { (metadata, error) in
                self.metadata = metadata
                if let error: Error = error as Error? {
                    completion?(metadata, error)
                    return
                }
                if owner.isObserved {
                    owner.updateValue(keyPath, child: nil, value: self.name)
                    completion?(metadata, error as Error?)
                } else {
                    completion?(metadata, error as Error?)
                }
            }
            return self.uploadTask
        } else if let url: URL = self.url, let owner: Object = self.owner {
            self.uploadTask = self.ref?.putFile(from: url, metadata: self.metadata, completion: { (metadata, error) in
                self.metadata = metadata
                if let error: Error = error as Error? {
                    completion?(metadata, error)
                    return
                }
                if owner.isObserved {
                    owner.updateValue(keyPath, child: nil, value: self.name)
                    completion?(metadata, error as Error?)
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

    public func save(completion: ((StorageMetadata?, Error?) -> Void)?) -> StorageUploadTask? {
        guard let _: Object = self.owner, let keyPath: String = self.keyPath else {
            let error: ObjectError = ObjectError(kind: .invalidFile, description: "It requires data when you save the file")
            completion?(nil, error)
            return nil
        }

        return self.save(keyPath, completion: completion)
    }

    // MARK: - Load

    public func dataWithMaxSize(_ size: Int64, completion: @escaping (Data?, Error?) -> Void) -> StorageDownloadTask? {
        self.downloadTask?.cancel()
        let task: StorageDownloadTask? = self.ref?.getData(maxSize: size, completion: { (data, error) in
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
        self.owner = nil
    }

    // MARK: -

    override public var description: String {
        return "Salada.File"
    }

}
