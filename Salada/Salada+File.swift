//
//  Salada+File.swift
//  Salada
//
//  Created by 1amageek on 2017/01/05.
//  Copyright © 2017年 Stamp. All rights reserved.
//

import Foundation
import Firebase

extension Salada {
    
    public class File: NSObject {

        /// Save location
        open var ref: FIRStorageReference? {
            if let parent: Object = self.parent {
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
        open var parent: Object?

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
            if let data: Data = self.data, let parent: Object = self.parent {
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
                let error: ObjectError = ObjectError(kind: .invalidFile, description: "It requires data when you save the file")
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
