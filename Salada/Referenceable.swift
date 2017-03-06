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
    static var database: FIRDatabaseReference { get }
    static var databaseRef: FIRDatabaseReference { get }
    static var storage: FIRStorageReference { get }
    static var storageRef: FIRStorageReference { get }
    static var _path: String { get }

    var id: String { get }
    var snapshot: FIRDataSnapshot? { get }
    var createdAt: Date { get }
    var value: [AnyHashable: Any] { get }
    var ignore: [String] { get }

    init?(snapshot: FIRDataSnapshot)
}

public extension Referenceable {
    static var database: FIRDatabaseReference { return FIRDatabase.database().reference() }
    static var databaseRef: FIRDatabaseReference { return self.database.child(self._path) }
    static var storage: FIRStorageReference { return FIRStorage.storage().reference() }
    static var storageRef: FIRStorageReference { return self.storage.child(self._path) }
}
