//
//  Disposer.swift
//  Salada
//
//  Created by suguru-kishimoto on 2017/08/21.
//  Copyright © 2017年 Stamp. All rights reserved.
//

import FirebaseDatabase

/// A protocol for disposer
public protocol ReferenceObservationDisposable {
    /// Execute T.removeObserver()
    func dispose()

    /// get observe id
    var observeID: UInt? { get }

    /// get child_id
    var id: String? { get }
}

/// Disposer
/// Handle removing observer using handle_id (and child_id) on `deinit` automatically.
public final class Disposer<T: Referenceable>: ReferenceObservationDisposable {
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

    public func toAny() -> AnyDisposer {
        return .init(self)
    }

    deinit {
        dispose()
    }
}

///  A type-erased `Disposer`.
public final class AnyDisposer: ReferenceObservationDisposable {

    public let base: ReferenceObservationDisposable

    public init(_ base: ReferenceObservationDisposable = NoDisposer()) {
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

/// A disposer that do nothing.
public final class NoDisposer: ReferenceObservationDisposable {
    public init() {
    }

    public func dispose() {
    }

    public let observeID: UInt? = nil
    public let id: String? = nil
}
