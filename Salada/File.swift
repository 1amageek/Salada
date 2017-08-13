//
//  File.swift
//  Salada
//
//  Created by nori on 2017/05/29.
//  Copyright © 2017年 Stamp. All rights reserved.
//

import FirebaseDatabase
import FirebaseStorage

public class File: NSObject {

    public enum MIMEType {
        case plain
        case csv
        case html
        case css
        case javascript
        case octetStream(String)
        case pdf
        case zip
        case tar
        case lzh
        case jpeg
        case pjpeg
        case png
        case gif
        case mp4
        case custom(String, String)

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
            case .pjpeg:                 return "image/pjpeg"
            case .png:                   return "image/png"
            case .gif:                   return "image/gif"
            case .mp4:                   return "video/mp4"
            case .custom(let type, _):   return type
            }
        }

        var fileExtension: String {
            switch self {
            case .plain:                 return "txt"
            case .csv:                   return "csv"
            case .html:                  return "html"
            case .css:                   return "css"
            case .javascript:            return "js"
            case .octetStream(let ext):  return ext
            case .pdf:                   return "pdf"
            case .zip:                   return "zip"
            case .tar:                   return "tar"
            case .lzh:                   return "lzh"
            case .jpeg:                  return "jpg"
            case .pjpeg:                 return "jpg"
            case .png:                   return "png"
            case .gif:                   return "gif"
            case .mp4:                   return "mp4"
            case .custom(_, let ext):    return ext
            }
        }

        init?(rawValue: String, ext: String? = nil) {
            switch rawValue {
            case "text/plain":                  self = .plain
            case "text/csv":                    self = .csv
            case "text/html":                   self = .html
            case "text/css":                    self = .css
            case "text/javascript":             self = .javascript
            case "application/octet-stream":    self = .octetStream(ext ?? "")
            case "application/pdf":             self = .pdf
            case "application/zip":             self = .zip
            case "application/x-tar":           self = .tar
            case "application/x-lzh":           self = .lzh
            case "image/jpeg":                  self = .jpeg
            case "image/pjpeg":                 self = .pjpeg
            case "image/png":                   self = .png
            case "image/gif":                   self = .gif
            case "video/mp4":                   self = .mp4
            default:                            self = .custom(rawValue, ext ?? "")
            }
        }
    }

    /// Save location
    public var ref: StorageReference? {
        if let owner: Object = self.owner, let keyPath: String = self.keyPath {
            return type(of: owner).storageRef.child(owner.id).child(keyPath).child(self.name)
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
        if let url: URL = self._downloadURL {
            return url
        }
        return self.metadata?.downloadURL()
    }

    /// private downloadURL
    private var _downloadURL: URL?

    private var hasExtension: Bool = true

    /// File detail value
    public var value: [AnyHashable: Any] {
        var value: [AnyHashable: Any] = ["name": self.name]
        if let downloadURL: URL = self.downloadURL {
            value["url"] = downloadURL.absoluteString
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

    public convenience init(name: String? = nil,
        data: Data,
        mimeType: MIMEType? = nil) {
        let fileName: String = File.generateFileName(name ?? "\(Int(Date().timeIntervalSince1970 * 1000))", mimeType: mimeType)
        self.init(name: fileName)
        self.mimeType = mimeType
        self.data = data
    }

    public convenience init(name: String? = nil,
        url: URL,
        mimeType: MIMEType? = nil) {
        let fileName: String = File.generateFileName(name ?? "\(Int(Date().timeIntervalSince1970 * 1000))", mimeType: mimeType)
        self.init(name: fileName)
        self.mimeType = mimeType
        self.url = url
    }

    internal convenience init?(propery: [AnyHashable: String]) {
        guard let name: String = propery["name"] else { return nil }
        self.init(name: name)
        if let mimeType: String = propery["mimeType"] {
            self.mimeType = MIMEType(rawValue: mimeType)
        }
        if let downloadURL: String = propery["url"] {
            self._downloadURL = URL(string: downloadURL)
        }
    }

    class func generateFileName(_ name: String, mimeType: MIMEType?) -> String {
        var fileName: String = name
        if let mimeType: MIMEType = mimeType {
            let url: URL = URL(string: name)!
            fileName = url.pathExtension.isEmpty ? url.appendingPathExtension(mimeType.fileExtension).absoluteString : name
        }
        return fileName
    }

    // MARK: - Save

    internal func save(_ keyPath: String) -> StorageUploadTask? {
        return self.save(keyPath, completion: nil)
    }

    internal func save(_ keyPath: String, completion: ((StorageMetadata?, Error?) -> Void)?) -> StorageUploadTask? {

        let metadata: StorageMetadata = StorageMetadata()
        if let mimeType: MIMEType = self.mimeType {
            metadata.contentType = mimeType.rawValue
        }

        if let data: Data = self.data {
            self.uploadTask = self.ref?.putData(data, metadata: metadata) { (metadata, error) in
                self.metadata = metadata
                if let error: Error = error as Error? {
                    completion?(metadata, error)
                    return
                }
                if let owner: Object = self.owner, owner.isObserved {
                    owner.updateValue(keyPath, child: nil, value: self.value)
                    completion?(metadata, error as Error?)
                } else {
                    completion?(metadata, error as Error?)
                }
            }
            return self.uploadTask
        } else if let url: URL = self.url {
            self.uploadTask = self.ref?.putFile(from: url, metadata: metadata, completion: { (metadata, error) in
                self.metadata = metadata
                if let error: Error = error as Error? {
                    completion?(metadata, error)
                    return
                }
                if let owner: Object = self.owner, owner.isObserved {
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

    public func update(completion: ((StorageMetadata?, Error?) -> Void)?) -> StorageUploadTask? {
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
