//
//  DataSource.swift
//  Salada
//
//  Created by nori on 2017/05/29.
//  Copyright © 2017年 Stamp. All rights reserved.
//

import Firebase

public typealias SaladaChange = (deletions: [Int], insertions: [Int], modifications: [Int])

public enum SaladaCollectionChange {

    case initial

    case update(SaladaChange)

    case error(Error)

    init(change: SaladaChange?, error: Error?) {
        if let error: Error = error {
            self = .error(error)
            return
        }
        if let change: SaladaChange = change {
            self = .update(change)
            return
        }
        self = .initial
    }

}

public class SaladaOptions {
    public var limit: UInt = 30
    public var ascending: Bool = false
    public init() { }
}

/// DataSource class.
/// Observe at a Firebase DataSource location.
public class DataSource<Parent, Child> where Parent: Referenceable, Parent: Object, Child: Referenceable, Child: Object {

    /// DatabaseReference
    public var databaseRef: DatabaseReference { return Database.database().reference() }

    /// Count
    public var count: Int { return pool.count }

    /// Reference of parent
    private(set) var parentRef: DatabaseReference

    /// Reference of child
    private(set) var reference: DatabaseReference

    /// Key of parent of reference node
    private(set) var parentKey: String

    /// Key of the node to be reference
    private(set) var referenceKey: String

    /// Number to be referenced at one time
    private(set) var limit: UInt = 30

    /// Sort order
    private(set) var ascending: Bool = false

    private var addReference: DatabaseQuery?

    private var addedHandle: UInt?

    private var changedHandle: UInt?

    private var removedHandle: UInt?

    private var isFirst: Bool = false

    // Firebase firstKey
    private var firstKey: String? {
        return self.ascending ? self.pool.last : self.pool.first
    }

    // Firebase lastKey
    private var lastKey: String? {
        return self.ascending ? self.pool.first : self.pool.last
    }

    // Sorted pool
    private var sortedPool: [String] {
        return self.pool.sorted { self.ascending ? $0 < $1 : $0 > $1 }
    }

    internal var pool: [String] = []

    private var changedBlock: (SaladaCollectionChange) -> Void

    /**
     
     DataSource observes its value by defining a parent-child relationship.
     If there is a change in the value, it will receive and notify you of the change.
     
     Handler blocks are called on the same thread that they were added on, and may only be added on threads which are
     currently within a run loop. Unless you are specifically creating and running a run loop on a background thread,
     this will normally only be the main thread.

     - parameter parentKey: Key of parent node to reference
     - parameter referenceKey: Key of child node to reference
     - parameter options: DataSource Options
     - parameter block: A block which is called to process Firebase change evnet.
     */
    public init(parentKey: String, referenceKey: String, options: SaladaOptions?, block: @escaping (SaladaCollectionChange) -> Void ) {

        if let options: SaladaOptions = options {
            self.limit = options.limit
            self.ascending = options.ascending
        }

        self.parentKey = parentKey

        self.referenceKey = referenceKey

        self.parentRef = Parent.databaseRef.child(parentKey)

        self.reference = self.parentRef.child(referenceKey)

        self.changedBlock = block

        prev(at: nil, toLast: self.limit) { [weak self] (change, error) in

            block(SaladaCollectionChange(change: nil, error: error))

            guard let strongSelf = self else { return }

            // add
            var addReference: DatabaseQuery = strongSelf.reference
            if let fiarstKey: String = strongSelf.pool.first {
                addReference = addReference.queryOrderedByKey().queryStarting(atValue: fiarstKey)
            }
            strongSelf.addReference = addReference
            strongSelf.addedHandle = addReference.observe(.childAdded, with: { [weak self] (snapshot) in
                objc_sync_enter(self)
                let key: String = snapshot.key
                if !strongSelf.pool.contains(key) {
                    strongSelf.pool.append(key)
                    strongSelf.pool = strongSelf.sortedPool
                    if let i: Int = strongSelf.pool.index(of: key) {
                        block(SaladaCollectionChange(change: (deletions: [], insertions: [i], modifications: []), error: nil))
                    }
                }
                objc_sync_exit(self)
                }, withCancel: { (error) in
                    block(SaladaCollectionChange(change: nil, error: error))
            })

            // change
            strongSelf.changedHandle = strongSelf.reference.observe(.childChanged, with: { (snapshot) in
                if let i: Int = strongSelf.pool.index(of: snapshot.key) {
                    block(SaladaCollectionChange(change: (deletions: [], insertions: [], modifications: [i]), error: nil))
                }
            }, withCancel: { (error) in
                block(SaladaCollectionChange(change: nil, error: error))
            })

            // remove
            strongSelf.removedHandle = strongSelf.reference.observe(.childRemoved, with: { [weak self] (snapshot) in
                objc_sync_enter(self)
                if let i: Int = strongSelf.pool.index(of: snapshot.key) {
                    strongSelf.removeObserver(at: i)
                    strongSelf.pool.remove(at: i)
                    block(SaladaCollectionChange(change: (deletions: [i], insertions: [], modifications: []), error: nil))
                }
                objc_sync_exit(self)
                }, withCancel: { (error) in
                    block(SaladaCollectionChange(change: nil, error: error))
            })
        }
    }

    /**
     It gets the oldest subsequent data of the data that are currently obtained.
     */
    public func prev() {
        self.prev(at: self.lastKey, toLast: self.limit) { [weak self](change, error) in
            guard let strongSelf = self else { return }
            strongSelf.changedBlock(SaladaCollectionChange(change: change, error: error))
        }
    }

    /**
     Load the previous data from the server.
     - parameter lastKey: It gets the data after the Key
     - parameter limit: It the limit of from after the lastKey.
     - parameter block: block The block that should be called. Change if successful will be returned. An error will return if it fails.
     */
    public func prev(at lastKey: String?, toLast limit: UInt, block: ((SaladaChange?, Error?) -> Void)?) {

        if isFirst {
            block?((deletions: [], insertions: [], modifications: []), nil)
            return
        }

        var reference: DatabaseQuery = self.reference.queryOrderedByKey()
        var limit: UInt = limit
        if let lastKey: String = lastKey {
            reference = reference.queryEnding(atValue: lastKey)
            limit = limit + 1
        }
        reference.queryLimited(toLast: limit).observeSingleEvent(of: .value, with: { [weak self] (snapshot) in

            guard let strongSelf = self else { return }

            if snapshot.childrenCount < limit {
                strongSelf.isFirst = true
            }

            objc_sync_enter(self)
            var changes: [Int] = []
            if strongSelf.ascending {
                for (_, child) in snapshot.children.enumerated() {
                    let key: String = (child as AnyObject).key
                    if !strongSelf.pool.contains(key) {
                        strongSelf.pool.append(key)
                        strongSelf.pool = strongSelf.sortedPool
                        if let i: Int = strongSelf.pool.index(of: key) {
                            changes.append(i)
                        }
                    }
                }
            } else {
                for (_, child) in snapshot.children.reversed().enumerated() {
                    let key: String = (child as AnyObject).key
                    if !strongSelf.pool.contains(key) {
                        strongSelf.pool.append(key)
                        strongSelf.pool = strongSelf.sortedPool
                        if let i: Int = strongSelf.pool.index(of: key) {
                            changes.append(i)
                        }
                    }
                }
            }
            objc_sync_exit(self)
            block?((deletions: [], insertions: changes, modifications: []), nil)
        }) { (error) in
            block?(nil, error)
        }

    }

    /**
     Remove object
     - parameter index: Order of the data source
     - parameter cascade: Also deletes the data of the reference case of `true`.
     - parameter block: block The block that should be called. If there is an error it returns an error.
     */
    public func removeObject(at index: Int, cascade: Bool, block: @escaping (String, Error?) -> Void) {
        let key: String = self.pool[index]

        if cascade {
            let parentPath: AnyHashable = "/\(Parent._path)/\(parentKey)/\(self.reference.key)/\(key)"
            let childPath: AnyHashable = "/\(Child._path)/\(key)"

            self.databaseRef.updateChildValues([parentPath : NSNull(), childPath: NSNull()]) { (error, ref) in
                if let error: Error = error {
                    block(key, error)
                    return
                }
                block(key, nil)
            }
        } else {
            self.reference.child(key).removeValue(completionBlock: { (error, ref) in
                if let error: Error = error {
                    block(key, error)
                    return
                }
                block(key, nil)
            })
        }

    }

    /**
     Removes all observers at the reference of key
     - parameter index: Order of the data source
     */
    public func removeObserver(at index: Int) {
        if index < self.pool.count {
            let key: String = self.pool[index]
            Child.databaseRef.child(key).removeAllObservers()
        }
    }

    /**
     Get an object from a data source
     - parameter index: Order of the data source
     - parameter block: block The block that should be called.  It is passed the data as a Tsp.
     */
    public func object(at index: Int, block: @escaping (Child?) -> Void) {
        let key: String = self.pool[index]
        Child.databaseRef.child(key).observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.exists() {
                if let tsp: Child = Child(snapshot: snapshot) {
                    block(tsp)
                }
            } else {
                block(nil)
            }
        })
    }

    /**
     Get an object from a data source and observe object changess
     It is need `removeObserver`
     - parameter index: Orderr of the data source
     - parameter block: block The block that should be called.  It is passed the data as a Tsp.
     - see removeObserver
     */
    public func observeObject(at index: Int, block: @escaping (Child?) -> Void) {
        let key: String = self.pool[index]
        Child.databaseRef.child(key).observe(.value, with: { (snapshot) in
            if snapshot.exists() {
                if let tsp: Child = Child(snapshot: snapshot) {
                    block(tsp)
                }
            } else {
                block(nil)
            }
        }) { (error) in
            block(nil)
        }
    }

    // MARK: - deinit

    deinit {
        if let handle: UInt = self.addedHandle {
            self.addReference?.removeObserver(withHandle: handle)
        }
        if let handle: UInt = self.changedHandle {
            self.reference.removeObserver(withHandle: handle)
        }
        if let handle: UInt = self.removedHandle {
            self.reference.removeObserver(withHandle: handle)
        }
    }
}

/**
 DataSource conforms to Collection
 */
extension DataSource: Collection {

    typealias Element = String

    public var startIndex: Int {
        return 0
    }

    public var endIndex: Int {
        return self.pool.count
    }

    public func index(after i: Int) -> Int {
        return i + 1
    }

    public var first: String? {
        if 0 < self.pool.count {
            return self.pool[startIndex]
        }
        return nil
    }

    public var last: String? {
        if 0 < self.pool.count {
            return self.pool[endIndex - 1]
        }
        return nil
    }

    public subscript(index: Int) -> String {
        return self.pool[index]
    }

}
