//
//  DataSource.swift
//  Salada
//
//  Created by nori on 2017/05/29.
//  Copyright © 2017年 Stamp. All rights reserved.
//

import FirebaseDatabase
import FirebaseStorage

public typealias Change = (deletions: [Int], insertions: [Int], modifications: [Int])

public enum CollectionChange {

    case initial

    case update(Change)

    case error(Error)

    init(change: Change?, error: Error?) {
        if let error: Error = error {
            self = .error(error)
            return
        }
        if let change: Change = change {
            self = .update(change)
            return
        }
        self = .initial
    }
}

/**
 Options class
 */
public class Options {

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
public class DataSource<T: Object>: ExpressibleByArrayLiteral {

    public typealias ArrayLiteralElement = T

    public typealias Element = ArrayLiteralElement

    /// DatabaseReference
    public var databaseRef: DatabaseReference { return Database.database().reference() }

    /// Objects held in the client
    public var objects: [Element] = []

    /// Count
    public var count: Int { return objects.count }

    /// Reference of element
    private(set) var reference: DatabaseReference

    /// Options
    private(set) var options: Options

    private let fetchQueue: DispatchQueue = DispatchQueue(label: "salada.datasource.fetch.queue")

    private var addReference: DatabaseQuery?

    private var addedHandle: UInt?

    private var changedHandle: UInt?

    private var removedHandle: UInt?

    private var isFirst: Bool = true

    private(set) var parentRef: DatabaseReference?

    private(set) var propertyKey: String?

    /// Key of all Objects
    internal var keys: [String] = []

    /// Firebase firstKey. Recently Created Key
    private var firstKey: String? {
        return self.keys.first
    }

    /// Firebase lastKey. The oldest Key in keys
    private var lastKey: String? {
        return self.keys.last
    }

    /// Holds the Key previously sent to Firebase.
    private var previousLastKey: String?

    /// Sorted keys
    private var sortedKeys: [String] {
        return self.keys.sorted { $0 > $1 }
    }

    /// Block called when there is a change in DataSource
    private var changedBlock: ((CollectionChange) -> Void)?

    /// Applies the NSPredicate specified by option.
    private func filtered() -> [Element] {
        if let predicate: NSPredicate = self.options.predicate {
            return (self.objects as NSArray).filtered(using: predicate) as! [Element]
        }
        return self.objects
    }

    /**
     DataSource retrieves data from the referenced data. Change the acquisition of data by setting Options.
     If there is a change in the value, it will receive and notify you of the change.

     Handler blocks are called on the same thread that they were added on, and may only be added on threads which are
     currently within a run loop. Unless you are specifically creating and running a run loop on a background thread,
     this will normally only be the main thread.

     - parameter object: Set the object to be referenced.
     - parameter keyPath: Sets the property of the object to be referenced.
     - parameter options: DataSource Options
     - parameter block: A block which is called to process Firebase change evnet.
     */
    public convenience init<T: Object>(object: T, keyPath: KeyPath<T, Set<String>>, options: Options = Options(), block: ((CollectionChange) -> Void)?) {
        self.init(object: object, propertyKey: keyPath._kvcKeyPathString!, options: options, block: block)
    }

    /**
     DataSource retrieves data from the referenced data. Change the acquisition of data by setting Options.
     If there is a change in the value, it will receive and notify you of the change.

     Handler blocks are called on the same thread that they were added on, and may only be added on threads which are
     currently within a run loop. Unless you are specifically creating and running a run loop on a background thread,
     this will normally only be the main thread.

     - parameter object: Set the object to be referenced.
     - parameter propertyKey: Sets the property of the object to be referenced.
     - parameter options: DataSource Options
     - parameter block: A block which is called to process Firebase change evnet.
     */
    public convenience init<T: Object>(object: T, propertyKey: String, options: Options = Options(), block: ((CollectionChange) -> Void)?) {
        let reference: DatabaseReference = object.ref.child(propertyKey)
        self.init(reference: reference, options: options, block: block)
        self.parentRef = object.ref
        self.propertyKey = propertyKey
    }

    /**
     DataSource retrieves data from the referenced data. Change the acquisition of data by setting Options.
     If there is a change in the value, it will receive and notify you of the change.

     Handler blocks are called on the same thread that they were added on, and may only be added on threads which are
     currently within a run loop. Unless you are specifically creating and running a run loop on a background thread,
     this will normally only be the main thread.

     - parameter reference: Set DatabaseDeference
     - parameter options: DataSource Options
     - parameter block: A block which is called to process Firebase change evnet.
     */
    public init(reference: DatabaseReference, options: Options = Options(), block: ((CollectionChange) -> Void)?) {
        self.reference = reference
        self.options = options
        self.changedBlock = block
        self.on(block).observe()
    }

    /// Initializing the DataSource
    public required convenience init(arrayLiteral elements: Element...) {
        self.init(elements)
    }

    /// Initializing the DataSource
    public init(_ elements: [Element]) {
        self.reference = Element.databaseRef
        self.options = Options()
        self.objects = elements
    }

    /// Set the Block to receive the change of the DataSource.
    public func on(_ block: ((CollectionChange) -> Void)?) -> Self {
        self.changedBlock = block
        return self
    }

    /// Monitor changes in the DataSource.
    public func observe() {
        guard let block: (CollectionChange) -> Void = self.changedBlock else {
            fatalError("[Salada.DataSource] *** error: You need to define Changeblock to start observe.")
        }
        prev(at: nil, toLast: self.options.limit) { [weak self] (change, error) in

            guard let `self` = self else { return }

            // Called only once when initialized
            // `changes` is always nil
            block(CollectionChange(change: change, error: error))

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
                        self.objects.append(element)
                        self.objects = self.filtered().sort(sortDescriptors: self.options.sortDescirptors)
                        if let i: Int = self.objects.index(of: element) {
                            block(CollectionChange(change: (deletions: [], insertions: [i], modifications: []), error: nil))
                        }
                    })
                }
                }, withCancel: { (error) in
                    block(CollectionChange(change: nil, error: error))
            })

            // change
            self.changedHandle = self.reference.observe(.childChanged, with: { [weak self] (snapshot) in
                guard let `self` = self else { return }
                let key: String = snapshot.key
                Element.observeSingle(key, eventType: .value, block: { (element) in
                    guard let element: Element = element else { return }
                    if let i: Int = self.objects.index(of: element.id) {
                        self.objects.remove(at: i)
                    }
                    self.objects.append(element)
                    self.objects = self.filtered().sort(sortDescriptors: self.options.sortDescirptors)
                    if let i: Int = self.objects.index(of: element) {
                        block(CollectionChange(change: (deletions: [], insertions: [], modifications: [i]), error: nil))
                    }
                })
                }, withCancel: { (error) in
                    block(CollectionChange(change: nil, error: error))
            })

            // remove
            self.removedHandle = self.reference.observe(.childRemoved, with: { [weak self] (snapshot) in
                guard let `self` = self else { return }
                let key: String = snapshot.key
                if let i: Int = self.keys.index(of: key) {
                    self.keys.remove(at: i)
                }
                if let i: Int = self.objects.index(of: key) {
                    self.objects.remove(at: i)
                    block(CollectionChange(change: (deletions: [i], insertions: [], modifications: []), error: nil))
                }
                }, withCancel: { (error) in
                    block(CollectionChange(change: nil, error: error))
            })
        }
    }

    /**
     It gets the oldest subsequent data of the data that are currently obtained.
     */
    public func prev() {
        self.prev(at: self.lastKey, toLast: self.options.limit) { [weak self](change, error) in
            guard let `self` = self else { return }
            self.changedBlock?(CollectionChange(change: change, error: error))
        }
    }

    /**
     Load the previous data from the server.
     - parameter lastKey: It gets the data after the Key
     - parameter limit: It the limit of from after the lastKey.
     - parameter block: block The block that should be called. Change if successful will be returned. An error will return if it fails.
     */
    public func prev(at lastKey: String?, toLast limit: UInt, block: ((Change?, Error?) -> Void)?) {
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
                        self.objects.append(element)
                        self.objects = self.filtered().sort(sortDescriptors: self.options.sortDescirptors)
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
    public func removeObject(at index: Int, block: @escaping (String, Error?) -> Void) {
        let key: String = self.keys[index]
        if let parentRef: DatabaseReference = self.parentRef, let propertyKey: String = self.propertyKey {
            var values: [AnyHashable: Any] = [:]
            let parentPath: AnyHashable = "\(parentRef._path)/\(propertyKey)/\(key)"
            values[parentPath] = NSNull()
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
        return self.objects.count
    }

    public func index(after i: Int) -> Int {
        return i + 1
    }

    public func index(where predicate: (T) throws -> Bool) rethrows -> Int? {
        if self.objects.isEmpty { return nil}
        return try self.objects.index(where: predicate)
    }

    public var first: Element? {
        if self.objects.isEmpty { return nil }
        return self.objects[startIndex]
    }

    public var last: Element? {
        if self.objects.isEmpty { return nil }
        return self.objects[endIndex - 1]
    }

    public func insert(_ newMember: Element) {
        if !self.objects.contains(newMember) {
            self.objects.append(newMember)
        }
    }

    public func remove(_ member: Element) {
        if let index: Int = self.objects.index(of: member) {
            self.objects.remove(at: index)
        }
    }

    public subscript(index: Int) -> Element {
        return self.objects[index]
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

