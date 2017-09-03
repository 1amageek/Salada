//
//  DataSource.swift
//  Salada
//
//  Created by nori on 2017/05/29.
//  Copyright © 2017年 Stamp. All rights reserved.
//

import FirebaseDatabase
import FirebaseStorage

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

    /// Number to be referenced at one time
    public var limit: UInt = 30

    /// Fetch timeout
    public var timeout: Int = SaladaApp.shared.timeout

    /// Predicate
    public var predicate: NSPredicate?

    /// Sort order
    public var sortDescirptors: [NSSortDescriptor] = [NSSortDescriptor(key: "id", ascending: false)]

    public init() { }
}

/// DataSource class.
/// Observe at a Firebase DataSource location.
public class DataSource<T: Object> {

    public typealias Element = T

    /// DatabaseReference
    public var databaseRef: DatabaseReference { return Database.database().reference() }

    /// Count
    public var count: Int { return pool.count }

    /// Reference of element
    private(set) var reference: DatabaseReference

    /// Options
    private(set) var options: SaladaOptions

    private let fetchQueue: DispatchQueue = DispatchQueue(label: "salada.datasource.fetch.queue")

    private var addReference: DatabaseQuery?

    private var addedHandle: UInt?

    private var changedHandle: UInt?

    private var removedHandle: UInt?

    private var isFirst: Bool = true

    /// Firebase firstKey. Recently Created Key
    private var firstKey: String? {
        return self.keys.first
    }

    /// Firebase lastKey. The oldest Key in keys
    private var lastKey: String? {
        return self.keys.last
    }

    private var previousLastKey: String?

    // Sorted keys
    private var sortedKeys: [String] {
        return self.keys.sorted { $0 > $1 }
    }

    internal var keys: [String] = []

    private var changedBlock: (SaladaCollectionChange) -> Void

    public var pool: [Element] = []

    private var filteredPool: [Element] {
        if let predicate: NSPredicate = self.options.predicate {
            return (self.pool as NSArray).filtered(using: predicate) as! [Element]
        }
        return self.pool
    }

    /**
     
     DataSource observes its value by defining a parent-child relationship.
     If there is a change in the value, it will receive and notify you of the change.
     
     Handler blocks are called on the same thread that they were added on, and may only be added on threads which are
     currently within a run loop. Unless you are specifically creating and running a run loop on a background thread,
     this will normally only be the main thread.

     - parameter parentKey: Key of parent node to reference
     - parameter keyPath: Key of child node to reference
     - parameter options: DataSource Options
     - parameter block: A block which is called to process Firebase change evnet.
     */
//    public convenience init(parentKey: String, keyPath: KeyPath<T, Set<String>>, options: SaladaOptions = SaladaOptions(), block: @escaping (SaladaCollectionChange) -> Void ) {
//        self.init(parentKey: parentKey, childKey: keyPath._kvcKeyPathString!, options: options, block: block)
//    }
//
//    /**
//
//     DataSource observes its value by defining a parent-child relationship.
//     If there is a change in the value, it will receive and notify you of the change.
//
//     Handler blocks are called on the same thread that they were added on, and may only be added on threads which are
//     currently within a run loop. Unless you are specifically creating and running a run loop on a background thread,
//     this will normally only be the main thread.
//
//     - parameter parentKey: Key of parent node to reference
//     - parameter childKey: Key of child node to reference
//     - parameter options: DataSource Options
//     - parameter block: A block which is called to process Firebase change evnet.
//     */
//    public convenience init(parentKey: String, childKey: String, options: SaladaOptions = SaladaOptions(), block: @escaping (SaladaCollectionChange) -> Void ) {
//
//        self.parentKey = parentKey
//
//        self.referenceKey = childKey
//
//        self.options = options
//
//        self.parentRef = Parent.databaseRef.child(parentKey)
//
//        self.reference = self.parentRef.child(self.referenceKey)
//
//        self.changedBlock = block
//    }

    public init(_ reference: DatabaseReference, options: SaladaOptions = SaladaOptions(), block: @escaping (SaladaCollectionChange) -> Void ) {

        self.reference = reference

        self.options = options

        self.changedBlock = block

        prev(at: nil, toLast: self.options.limit) { [weak self] (change, error) in

            guard let `self` = self else { return }

            // Called only once when initialized
            // `changes` is always nil
            block(SaladaCollectionChange(change: change, error: error))

            // add
            var addReference: DatabaseQuery = self.reference
            if let firstKey: String = self.keys.first {
                addReference = addReference.queryOrderedByKey().queryStarting(atValue: firstKey)
            }
            self.addReference = addReference
            self.addedHandle = addReference.observe(.childAdded, with: { [weak self] (snapshot) in
                guard let `self` = self else { return }
                let key: String = snapshot.key
                if !self.keys.contains(key) {
                    self.keys.append(key)
                    self.keys = self.sortedKeys
                    Element.observeSingle(key, eventType: .value, block: { (element) in
                        guard let element: Element = element else {
                            return
                        }
                        self.pool.append(element)
                        self.pool = self.filteredPool.sort(sortDescriptors: self.options.sortDescirptors)
                        if let i: Int = self.pool.index(of: element) {
                            block(SaladaCollectionChange(change: (deletions: [], insertions: [i], modifications: []), error: nil))
                        }
                    })
                }
                }, withCancel: { (error) in
                    block(SaladaCollectionChange(change: nil, error: error))
            })

            // change
            self.changedHandle = self.reference.observe(.childChanged, with: { [weak self] (snapshot) in
                guard let `self` = self else { return }
                let key: String = snapshot.key
                Element.observeSingle(key, eventType: .value, block: { (element) in
                    guard let element: Element = element else { return }
                    self.pool.append(element)
                    self.pool = self.filteredPool.sort(sortDescriptors: self.options.sortDescirptors)
                    if let i: Int = self.pool.index(of: element) {
                        block(SaladaCollectionChange(change: (deletions: [], insertions: [], modifications: [i]), error: nil))
                    }
                })
                }, withCancel: { (error) in
                    block(SaladaCollectionChange(change: nil, error: error))
            })

            // remove
            self.removedHandle = self.reference.observe(.childRemoved, with: { [weak self] (snapshot) in
                guard let `self` = self else { return }
                let key: String = snapshot.key
                if let i: Int = self.keys.index(of: key) {
                    self.keys.remove(at: i)
                }
                if let i: Int = self.pool.index(of: key) {
                    self.pool.remove(at: i)
                    block(SaladaCollectionChange(change: (deletions: [i], insertions: [], modifications: []), error: nil))
                }
                }, withCancel: { (error) in
                    block(SaladaCollectionChange(change: nil, error: error))
            })
        }
    }

    /**
     It gets the oldest subsequent data of the data that are currently obtained.
     */
    public func prev() {
        self.prev(at: self.lastKey, toLast: self.options.limit) { [weak self](change, error) in
            guard let `self` = self else { return }
            self.changedBlock(SaladaCollectionChange(change: change, error: error))
        }
    }

    /**
     Load the previous data from the server.
     - parameter lastKey: It gets the data after the Key
     - parameter limit: It the limit of from after the lastKey.
     - parameter block: block The block that should be called. Change if successful will be returned. An error will return if it fails.
     */
    public func prev(at lastKey: String?, toLast limit: UInt, block: ((SaladaChange?, Error?) -> Void)?) {
        var reference: DatabaseQuery = self.reference.queryOrderedByKey()
        var limit: UInt = limit
        if let lastKey: String = lastKey {
            if previousLastKey == lastKey {
                block?(nil, nil)
                return
            }
            previousLastKey = lastKey
            reference = reference.queryEnding(atValue: lastKey)
            limit = limit + 1
        }

        reference.queryLimited(toLast: limit).observeSingleEvent(of: .value, with: { [weak self] (snapshot) in
            guard let `self` = self else { return }

            let group: DispatchGroup = DispatchGroup()

            for (_, element) in snapshot.children.enumerated() {
                let key: String = (element as AnyObject).key
                if !self.keys.contains(key) {
                    self.keys.append(key)
                    self.keys = self.sortedKeys
                    group.enter()
                    Element.observeSingle(key, eventType: .value, block: { (element) in
                        guard let element: Element = element else { return }
                        self.pool.append(element)
                        self.pool = self.filteredPool.sort(sortDescriptors: self.options.sortDescirptors)
                        group.leave()
                    })
                }
            }
            self.fetchQueue.async {
                switch group.wait(timeout: .now() + .seconds(self.options.timeout)) {
                case .success:
                    DispatchQueue.main.async {
                        block?(nil, nil)
                    }
                case .timedOut:
                    DispatchQueue.main.async {
                        let error: ObjectError = ObjectError(kind: .timeout, description: "Data source acquisition exceeded \(self.options.timeout) seconds.")
                        block?(nil, error)
                    }
                }
            }
        }) { (error) in
            block?(nil, error)
        }
    }

    /**
     Remove object
     - parameter index: Order of the data source
     - parameter parent: Also deletes the data of the reference case of `true`.
     - parameter block: block The block that should be called. If there is an error it returns an error.
     */
    public func removeObject<T: Referenceable>(at index: Int, parent: T.Type? = nil, block: @escaping (String, Error?) -> Void) {
        let key: String = self.keys[index]

        if let parent = parent {
            // TODO: ここの処理の検証
            var values: [AnyHashable: Any] = [:]
            if let parentKey: String = self.reference.parent?.parent?.key {
                let parentPath: AnyHashable = "/\(parent._path)/\(parentKey)/\(self.reference.key)/\(key)"
                values[parentPath] = NSNull()
            }
            let childPath: AnyHashable = "/\(Element._path)/\(key)"
            values[childPath] = NSNull()
            self.databaseRef.updateChildValues(values) { (error, ref) in
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
     Get an object from a data source and observe object changess
     It is need `removeObserver`
     - parameter index: Orderr of the data source
     - parameter block: block The block that should be called.  It is passed the data as a Tsp.
     - see removeObserver
     */
    public func observeObject(at index: Int, block: @escaping (Element?) -> Void) -> Disposer<Element> {
        let key: String = self.keys[index]
        let element: Element = self[index]
        var isFirst: Bool = true
        block(element)
        return Element.observe(key, eventType: .value) { (element) in
            if isFirst {
                isFirst = false
                return
            }
            block(element)
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

    public var startIndex: Int {
        return 0
    }

    public var endIndex: Int {
        return self.pool.count
    }

    public func index(after i: Int) -> Int {
        return i + 1
    }

    public var first: Element? {
        if self.pool.isEmpty { return nil }
        return self.pool[startIndex]
    }

    public var last: Element? {
        if self.pool.isEmpty { return nil }
        return self.pool[endIndex - 1]
    }

    public subscript(index: Int) -> Element {
        return self.pool[index]
    }
}

extension Array where Element: Object {

    public var keys: [String] {
        return self.flatMap { return $0.id }
    }

    public func index(of key: String) -> Int? {
        return self.keys.index(of: key)
    }
}
