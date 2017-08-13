//
//  Referenceable.swift
//  Salada
//
//  Created by 1amageek on 2017/01/05.
//  Copyright © 2017年 Stamp. All rights reserved.
//

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

    init?(snapshot: DataSnapshot)
}

public extension Referenceable {
    static var database: DatabaseReference { return Database.database().reference() }
    static var databaseRef: DatabaseReference { return self.database.child(self._path) }
    static var storage: StorageReference { return Storage.storage().reference() }
    static var storageRef: StorageReference { return self.storage.child(self._path) }
}

public extension Referenceable {

    // MARK: - Observe

    /**
     A function that gets all data from DB whose name is model.
     
     - parameter eventType: Set the event to be observed.
     - parameter block: If the specified event fires, this callback is invoked.
     */
    public static func observeSingle(_ eventType: DataEventType, block: @escaping ([Self]) -> Void) {
        self.databaseRef.observeSingleEvent(of: eventType, with: { (snapshot) in
            if snapshot.exists() {
                var children: [Self] = []
                snapshot.children.forEach({ (snapshot) in
                    if let snapshot: DataSnapshot = snapshot as? DataSnapshot {
                        if let object: Self = Self(snapshot: snapshot) {
                            children.append(object)
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
     A function that gets data of key within the variable form DB selected.
     
     - parameter id: Observe the Object of the specified Key.
     - parameter eventType: Set the event to be observed.
     - parameter block: If the specified event fires, this callback is invoked.
     */
    public static func observeSingle(_ id: String, eventType: DataEventType, block: @escaping (Self?) -> Void) {
        self.databaseRef.child(id).observeSingleEvent(of: eventType, with: { (snapshot) in
            if snapshot.exists() {
                if let object: Self = Self(snapshot: snapshot) {
                    block(object)
                }
            } else {
                block(nil)
            }
        })
    }

    /**
     A functions that gets data whose property values match.
     This property must be set to indexOn.
     
     - parameter property: Enter the property name to be scanned.
     - parameter value: Enter the value to scan.
     - parameter block: This is a callback when scanning is over. Matched data will be returned.
     */
    public static func observeSingle(child property: String, equal value: Any, eventType: DataEventType, block: @escaping ([Self]) -> Void) {
        self.databaseRef.queryOrdered(byChild: property).queryEqual(toValue: value).observeSingleEvent(of: eventType, with: { (snapshot) in
            if snapshot.exists() {
                var children: [Self] = []
                snapshot.children.forEach({ (snapshot) in
                    if let snapshot: DataSnapshot = snapshot as? DataSnapshot {
                        if let object: Self = Self(snapshot: snapshot) {
                            children.append(object)
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
     
     - parameter eventType: Set the event to be observed.
     - parameter block: If the specified event fires, this callback is invoked.
     - returns: A handle used to unregister this block later using removeObserverWithHandle:
     */
    public static func observe(_ eventType: DataEventType, block: @escaping ([Self]) -> Void) -> UInt {
        return self.databaseRef.observe(eventType, with: { (snapshot) in
            if snapshot.exists() {
                var children: [Self] = []
                snapshot.children.forEach({ (snapshot) in
                    if let snapshot: DataSnapshot = snapshot as? DataSnapshot {
                        if let object: Self = Self(snapshot: snapshot) {
                            children.append(object)
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
     A function that gets data of key within the variable from DB whenever data of the key has been changed.
     
     - parameter key: Observe the Object of the specified Key.
     - parameter eventType: Set the event to be observed.
     - parameter block: If the specified event fires, this callback is invoked.
     - returns: A handle used to unregister this block later using removeObserverWithHandle:
     */
    public static func observe(_ id: String, eventType: DataEventType, block: @escaping (Self?) -> Void) -> UInt {
        return self.databaseRef.child(id).observe(eventType, with: { (snapshot) in
            if snapshot.exists() {
                if let object: Self = Self(snapshot: snapshot) {
                    block(object)
                }
            } else {
                block(nil)
            }
        })
    }
}
