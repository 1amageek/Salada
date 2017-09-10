//
//  FetchManager.swift
//  Salada
//
//  Created by 1amageek on 2017/09/03.
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

public class FetchManager<T: Object> {

    public typealias Element = T

    private let fetchQueue: DispatchQueue = DispatchQueue(label: "salada.datasource.fetch.queue")

    /// Options
    private(set) var options: SaladaOptions

    private var reference: DatabaseReference

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

    // Sorted keys
    private var sortedKeys: [String] {
        //return self.keys.sorted { self.options.ascending ? $0 < $1 : $0 > $1 }
        return self.keys.sorted { $0 > $1 }
    }

    internal var keys: [String] = []

    private var changedBlock: ((SaladaCollectionChange) -> Void)?

    public var pool: [Element] = []

    private var filteredPool: [Element] {
        if let predicate: NSPredicate = self.options.predicate {
            return (self.pool as NSArray).filtered(using: predicate) as! [Element]
        }
        return self.pool
    }

    public init(reference: DatabaseReference, options: SaladaOptions = SaladaOptions(), block: ((SaladaCollectionChange) -> Void)?) {

        self.reference = reference

        self.changedBlock = block

        self.options = options

        prev(at: nil, toLast: self.options.limit) { [weak self] (change, error) in

            guard let `self` = self else { return }

            // Called only once when initialized
            // `changes` is always nil
            block?(SaladaCollectionChange(change: change, error: error))

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
                            block?(SaladaCollectionChange(change: (deletions: [], insertions: [i], modifications: []), error: nil))
                        }
                    })
                }
                }, withCancel: { (error) in
                    block?(SaladaCollectionChange(change: nil, error: error))
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
                        block?(SaladaCollectionChange(change: (deletions: [], insertions: [], modifications: [i]), error: nil))
                    }
                })
                }, withCancel: { (error) in
                    block?(SaladaCollectionChange(change: nil, error: error))
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
                    block?(SaladaCollectionChange(change: (deletions: [i], insertions: [], modifications: []), error: nil))
                }
                }, withCancel: { (error) in
                    block?(SaladaCollectionChange(change: nil, error: error))
            })
        }
    }

    /**
     It gets the oldest subsequent data of the data that are currently obtained.
     */
    public func prev() {
        self.prev(at: self.lastKey, toLast: self.options.limit) { [weak self](change, error) in
            guard let `self` = self else { return }
            self.changedBlock?(SaladaCollectionChange(change: change, error: error))
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
