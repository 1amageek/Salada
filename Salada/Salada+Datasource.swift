//
//  Salada+Datasource.swift
//  Salada
//
//  Created by 1amageek on 2017/01/05.
//  Copyright © 2017年 Stamp. All rights reserved.
//

import Foundation
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

open class SaladaOptions {
    var limit: UInt = 30
    var ascending: Bool = false
}

/// Datasource class.
/// Observe at a Firebase Database location.
open class Datasource<Parent, Child> where Parent: Referenceable, Parent: Salada.Object, Child: Referenceable, Child: Salada.Object {
    
    /// DatabaseReference
    
    public var databaseRef: FIRDatabaseReference { return FIRDatabase.database().reference() }
    
    public var count: Int { return pool.count }
    
    public var parentRef: FIRDatabaseReference {
        return Parent.databaseRef.child(parentKey)
    }
    
    public var reference: FIRDatabaseReference {
        return Parent.databaseRef.child(parentKey).child(referenceKey)
    }
    
    fileprivate(set) var parentKey: String
    
    fileprivate(set) var referenceKey: String
    
    fileprivate(set) var limit: UInt = 30
    
    fileprivate(set) var ascending: Bool = false
    
    deinit {
        self.reference.removeAllObservers()
        if let handle: UInt = self.addedHandle {
            self.addReference?.removeObserver(withHandle: handle)
        }
    }
    
    private var addReference: FIRDatabaseQuery?
    
    fileprivate var addedHandle: UInt?
    fileprivate var changedHandle: UInt?
    fileprivate var removedHandle: UInt?
    
    internal var pool: [String] = []
    
    private var changedBlock: (SaladaCollectionChange) -> Void
    
    public init(parentKey: String, referenceKey: String, options: SaladaOptions?, block: @escaping (SaladaCollectionChange) -> Void ) {
        
        if let options: SaladaOptions = options {
            self.limit = options.limit
            self.ascending = options.ascending
        }
        
        self.parentKey = parentKey
        
        self.referenceKey = referenceKey
        
        self.changedBlock = block
        
        prev(at: nil, toLast: self.limit) { [weak self] (change, error) in
            
            block(SaladaCollectionChange(change: nil, error: error))
            
            guard let strongSelf = self else { return }
            
            // add
            var addReference: FIRDatabaseQuery = strongSelf.reference
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
        
        var reference: FIRDatabaseQuery = self.reference.queryOrderedByKey()
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
    
}

extension Datasource: Collection {
    
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
    
    public subscript(index: Int) -> String {
        return self.pool[index]
    }
    
}
