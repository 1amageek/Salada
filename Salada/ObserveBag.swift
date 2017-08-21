//
//  ObserveBag.swift
//  Salada
//
//  Created by suguru-kishimoto on 2017/08/21.
//  Copyright © 2017年 Stamp. All rights reserved.
//

import Foundation
import Firebase

protocol ReferenceObserverDisposable {
    func dispose()
    var observeID: UInt? { get }
    var id: String? { get }
}

final class ObserveBag<T: Object>: ReferenceObserverDisposable {
    enum ObserveType {
        case none
        case array(UInt)
        case value(String, UInt)

        var observeID: UInt? {
            switch self {
            case .array(let observeID):
                return observeID
            case .value(_, let observeID):
                return observeID
            default:
                return nil
            }
        }

        var id: String? {
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

    init(_ type: ObserveType = .none) {
        self.type = type
        if case .none = type {
            isDisposed = true
        }
    }

    init(observeID: UInt) {
        self.type = .array(observeID)
    }

    init(id: String, observeID: UInt) {
        self.type = .value(id, observeID)
    }

    func dispose() {
        lock.lock(); defer { lock.unlock() }
        if isDisposed { return }
        switch type {
        case .array(let observeID):
            T.removeObserver(with: observeID)
            assert({
                print("disposed observer(array)", T.self, observeID)
                return true
                }())
        case .value(let id, let observeID):
            T.removeObserver(id, with: observeID)
            assert({
                print("disposed observer(value)", T.self, id, observeID)
                return true
                }())
        default:
            break
        }
        isDisposed = true
    }

    var observeID: UInt? {
        return type.observeID
    }

    var id: String? {
        return type.id
    }

    func toAny() -> AnyObserveBag {
        return .init(self)
    }

    deinit {
        assert({
            if !isDisposed {
                print("disposed on deinit")
            }
            return true
            }())
        dispose()
    }
}

final class AnyObserveBag: ReferenceObserverDisposable {

    let base: ReferenceObserverDisposable
    init(_ base: ReferenceObserverDisposable = NopObserveBag()) {
        self.base = base
    }
    func dispose() {
        base.dispose()
    }

    var observeID: UInt? {
        return base.observeID
    }

    var id: String? {
        return base.id
    }

    deinit {
        dispose()
    }
}

final class NopObserveBag: ReferenceObserverDisposable {
    func dispose() {
    }

    let observeID: UInt? = nil
    let id: String? = nil
}

extension Referenceable where Self: Object {
    static func addObserver(_ eventType: DataEventType, block: @escaping ([Self]) -> Void) -> ObserveBag<Self> {
        return .init(.array(observe(eventType, block: block)))
    }

    static func addObserver(_ id: String, eventType: DataEventType, block: @escaping (Self?) -> Void) -> ObserveBag<Self> {
        return .init(.value(id, observe(id, eventType: eventType, block: block)))
    }
}

