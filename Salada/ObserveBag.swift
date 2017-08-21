//
//  ObserveBag.swift
//  Salada
//
//  Created by suguru-kishimoto on 2017/08/21.
//  Copyright © 2017年 Stamp. All rights reserved.
//

import Foundation
import Firebase

public protocol ReferenceObserverDisposable {
    func dispose()
    var observeID: UInt? { get }
    var id: String? { get }
}

public final class ObserveBag<T: Object>: ReferenceObserverDisposable {
    public enum ObserveType {
        case none
        case array(UInt)
        case value(String, UInt)

        public var observeID: UInt? {
            switch self {
            case .array(let observeID):
                return observeID
            case .value(_, let observeID):
                return observeID
            default:
                return nil
            }
        }

        public var id: String? {
            switch self {
            case .value(let id, _):
                return id
            default:
                return nil
            }
        }
    }

    private let type: ObserveType
    private var isDisposed = false
    private let lock = NSLock()

    public init(_ type: ObserveType = .none) {
        self.type = type
        if case .none = type {
            isDisposed = true
        }
    }

    public init(observeID: UInt) {
        self.type = .array(observeID)
    }

    public init(id: String, observeID: UInt) {
        self.type = .value(id, observeID)
    }

    public func dispose() {
        lock.lock(); defer { lock.unlock() }
        if isDisposed { return }
        switch type {
        case .array(let observeID):
            T.removeObserver(with: observeID)
        case .value(let id, let observeID):
            T.removeObserver(id, with: observeID)
        default:
            break
        }
        isDisposed = true
    }

    public var observeID: UInt? {
        return type.observeID
    }

    public var id: String? {
        return type.id
    }

    public func toAny() -> AnyObserveBag {
        return .init(self)
    }

    deinit {
        dispose()
    }
}

public final class AnyObserveBag: ReferenceObserverDisposable {

    public let base: ReferenceObserverDisposable

    public init(_ base: ReferenceObserverDisposable = NopObserveBag()) {
        self.base = base
    }

    public func dispose() {
        base.dispose()
    }

    public var observeID: UInt? {
        return base.observeID
    }

    public var id: String? {
        return base.id
    }

    deinit {
        dispose()
    }
}

public final class NopObserveBag: ReferenceObserverDisposable {
    public init() {

    }

    public func dispose() {
    }

    public let observeID: UInt? = nil
    public let id: String? = nil
}

extension Referenceable where Self: Object {
    public static func addObserver(_ eventType: DataEventType, block: @escaping ([Self]) -> Void) -> ObserveBag<Self> {
        return .init(.array(observe(eventType, block: block)))
    }

    public static func addObserver(_ id: String, eventType: DataEventType, block: @escaping (Self?) -> Void) -> ObserveBag<Self> {
        return .init(.value(id, observe(id, eventType: eventType, block: block)))
    }
}

