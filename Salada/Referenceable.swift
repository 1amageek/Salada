//
//  Referenceable.swift
//  Salada
//
//  Created by 1amageek on 2017/01/05.
//  Copyright © 2017年 Stamp. All rights reserved.
//

import Foundation
import FirebaseDatabase
import FirebaseStorage

/**
 Protocol that holds a reference Firebase
 */
public protocol Referenceable: NSObjectProtocol {
    static var database: DatabaseReference { get }
    static var databaseRef: DatabaseReference { get }
    static var storage: StorageReference { get }
    static var storageRef: StorageReference { get }
    static var _path: String { get }

    var id: String { get }
    var snapshot: DataSnapshot? { get }
    var createdAt: Date { get }
    var value: [AnyHashable: Any] { get }
    var ignore: [String] { get }

    init?(snapshot: DataSnapshot)
}

public extension Referenceable {
    static var database: DatabaseReference { return Database.database().reference() }
    static var databaseRef: DatabaseReference { return self.database.child(self._path) }
    static var storage: StorageReference { return Storage.storage().reference() }
    static var storageRef: StorageReference { return self.storage.child(self._path) }
}
