//
//  Tasting.swift
//  Salada
//
//  Created by 1amageek on 2017/01/05.
//  Copyright © 2017年 Stamp. All rights reserved.
//

import Foundation
import Firebase

/**
 Protocol to retrieve the data from Firebase
 */
public protocol Tasting {
    associatedtype Element: Referenceable
    static func observeSingle(_ eventType: FIRDataEventType, block: @escaping ([Element]) -> Void)
    static func observeSingle(_ id: String, eventType: FIRDataEventType, block: @escaping (Element?) -> Void)
    static func observe(_ eventType: FIRDataEventType, block: @escaping ([Element]) -> Void) -> UInt
    static func observe(_ id: String, eventType: FIRDataEventType, block: @escaping (Element?) -> Void) -> UInt
}

public extension Tasting where Element == Self, Element: Referenceable {

    /**
     A function that gets all data from DB whose name is model.
     */
    public static func observeSingle(_ eventType: FIRDataEventType, block: @escaping ([Element]) -> Void) {
        self.databaseRef.observeSingleEvent(of: eventType, with: { (snapshot) in
            if snapshot.exists() {
                var children: [Element] = []
                snapshot.children.forEach({ (snapshot) in
                    if let snapshot: FIRDataSnapshot = snapshot as? FIRDataSnapshot {
                        if let tsp: Element = Element(snapshot: snapshot) {
                            children.append(tsp)
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
     A function that gets data of ID within the variable form DB selected.
     */
    public static func observeSingle(_ id: String, eventType: FIRDataEventType, block: @escaping (Element?) -> Void) {
        self.databaseRef.child(id).observeSingleEvent(of: eventType, with: { (snapshot) in
            if snapshot.exists() {
                if let tsp: Element = Element(snapshot: snapshot) {
                    block(tsp)
                }
            } else {
                block(nil)
            }
        })
    }

    public static func observeSingle(child key: String, equal value: String, eventType: FIRDataEventType, block: @escaping ([Element]) -> Void) {
        self.databaseRef.queryOrdered(byChild: key).queryEqual(toValue: value).observeSingleEvent(of: eventType, with: { (snapshot) in
            if snapshot.exists() {
                var children: [Element] = []
                snapshot.children.forEach({ (snapshot) in
                    if let snapshot: FIRDataSnapshot = snapshot as? FIRDataSnapshot {
                        if let tsp: Element = Element(snapshot: snapshot) {
                            children.append(tsp)
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
     */
    public static func observe(_ eventType: FIRDataEventType, block: @escaping ([Element]) -> Void) -> UInt {
        return self.databaseRef.observe(eventType, with: { (snapshot) in
            if snapshot.exists() {
                var children: [Element] = []
                snapshot.children.forEach({ (snapshot) in
                    if let snapshot: FIRDataSnapshot = snapshot as? FIRDataSnapshot {
                        if let tsp: Element = Element(snapshot: snapshot) {
                            children.append(tsp)
                        }
                    }
                })
            } else {
                block([])
            }
        })
    }

    /**
     A function that gets data of ID within the variable from DB whenever data of the ID has been changed.
     */
    public static func observe(_ id: String, eventType: FIRDataEventType, block: @escaping (Element?) -> Void) -> UInt {
        return self.databaseRef.child(id).observe(eventType, with: { (snapshot) in
            if snapshot.exists() {
                if let tsp: Element = Element(snapshot: snapshot) {
                    block(tsp)
                }
            } else {
                block(nil)
            }
        })
    }

    /**
     Remove the observer.
     */
    public static func removeObserver(with handle: UInt) {
        self.databaseRef.removeObserver(withHandle: handle)
    }

    /**
     Remove the observer.
     */
    public static func removeObserver(_ id: String, with handle: UInt) {
        self.databaseRef.child(id).removeObserver(withHandle: handle)
    }

}
