//
//  File.swift
//  Salada
//
//  Created by nori on 2017/05/29.
//  Copyright © 2017年 Stamp. All rights reserved.
//

import Firebase

public class File: NSObject {

    public enum MIMEType {
        case plain
        case csv
        case html
        case css
        case javascript
        case octetStream
        case pdf
        case zip
        case tar
        case lzh
        case jpeg
        case png
        case gif
        case mpeg
        case custom(String)

        var rawValue: String {
            switch self {
            case .plain:                 return "text/plain"
            case .csv:                   return "text/csv"
            case .html:                  return "text/html"
            case .css:                   return "text/css"
            case .javascript:            return "text/javascript"
            case .octetStream:           return "application/octet-stream"
            case .pdf:                   return "application/pdf"
            case .zip:                   return "application/zip"
            case .tar:                   return "application/x-tar"
            case .lzh:                   return "application/x-lzh"
            case .jpeg:                  return "image/jpeg"
            case .png:                   return "image/png"
            case .gif:                   return "image/gif"
            case .mpeg:                  return "video/mpeg"
            case .custom(let type):      return type
            }
        }
    }

    /// Save location
    public var ref: StorageReference? {
        if let owner: Object = self.owner {
            return type(of: owner).storageRef.child(owner.id).child(self.name)
        }
        return nil
    }

    /// ConentType
    public var mimeType: MIMEType?

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

    /// DownloadURL
    public var downloadURL: URL? {
        return self.metadata?.downloadURL()
    }

    ///
    public var value: [AnyHashable: Any] {
        var value: [AnyHashable: Any] = ["name": self.name]
        if let downloadURL: URL = self.downloadURL {
            value["url"] = downloadURL
        }
        if let mimeType: String = self.mimeType?.rawValue {
            value["mimeType"] = mimeType
        }
        return value
    }

    /// Firebase uploading task
    public fileprivate(set) weak var uploadTask: StorageUploadTask?

    /// Firebase downloading task
    public fileprivate(set) weak var downloadTask: StorageDownloadTask?

    // MARK: - Initialize

    public init(name: String) {
        self.name = name
    }

    public convenience init(name: String = "\(Int(Date().timeIntervalSince1970 * 1000))",
        data: Data? = nil,
        mimeType: MIMEType? = nil) {
        self.init(name: name)
        self.mimeType = mimeType
        self.data = data
    }

    public convenience init(name: String = "\(Int(Date().timeIntervalSince1970 * 1000))",
        url: URL? = nil,
        mimeType: MIMEType? = nil) {
        self.init(name: name)
        self.mimeType = mimeType
        self.url = url
    }

//
//    public convenience init(name: String, data: Data) {
//        self.init(name: name)
//        self.data = data
//    }
//
//    public convenience init(data: Data) {
//        let name: String = "\(Int(Date().timeIntervalSince1970 * 1000))"
//        self.init(name: name)
//        self.data = data
//    }
//
//    public convenience init(url: URL) {
//        let name: String = "\(Int(Date().timeIntervalSince1970 * 1000))"
//        self.init(name: name)
//        self.url = url
//    }

    // MARK: - Save

    internal func save(_ keyPath: String) -> StorageUploadTask? {
        return self.save(keyPath, completion: nil)
    }

    internal func save(_ keyPath: String, completion: ((StorageMetadata?, Error?) -> Void)?) -> StorageUploadTask? {

        let metadata: StorageMetadata = StorageMetadata()
        if let mimeType: MIMEType = self.mimeType {
            metadata.contentType = mimeType.rawValue
        }

        if let data: Data = self.data, let owner: Object = self.owner {
            self.uploadTask = self.ref?.putData(data, metadata: metadata) { (metadata, error) in
                self.metadata = metadata
                if let error: Error = error as Error? {
                    completion?(metadata, error)
                    return
                }
                if owner.isObserved {
                    owner.updateValue(keyPath, child: nil, value: self.value)
                    completion?(metadata, error as Error?)
                } else {
                    completion?(metadata, error as Error?)
                }
            }
            return self.uploadTask
        } else if let url: URL = self.url, let owner: Object = self.owner {
            self.uploadTask = self.ref?.putFile(from: url, metadata: metadata, completion: { (metadata, error) in
                self.metadata = metadata
                if let error: Error = error as Error? {
                    completion?(metadata, error)
                    return
                }
                if owner.isObserved {
                    owner.updateValue(keyPath, child: nil, value: self.value)
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
