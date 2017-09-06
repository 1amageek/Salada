//
//  SaladaApp.swift
//  Salada
//
//  Created by 1amageek on 2017/08/04.
//  Copyright © 2017年 Stamp. All rights reserved.
//

import FirebaseDatabase
import FirebaseStorage

public class SaladaApp: NSObject, NSCacheDelegate {

    static let shared: SaladaApp = SaladaApp()

    private(set) var isConnected: Bool = false

    public var timeout: Int = 20

    private var _cache: NSCache<AnyObject, AnyObject>?

    private override init() {
        super.init()
        _connectedHandle = Database.database().reference(withPath: ".info/connected").observe(.value) { [weak self] (snapshot) in
            self?.isConnected = snapshot.value as? Bool ?? false
        }
    }

    public class func configure(_ isCacheEnabled: Bool = true) {
        let app: SaladaApp = SaladaApp.shared
        if isCacheEnabled {
            app._cache = NSCache()
            app._cache?.delegate = app
        }
    }

    public class var cache: NSCache<AnyObject, AnyObject>? {
        return shared._cache
    }

    public class var isPersistenced: Bool {
        return Database.database().isPersistenceEnabled
    }

    private(set) var _connectedHandle: DatabaseHandle?

    deinit {
        if let connectedHandle: DatabaseHandle = self._connectedHandle {
            Database.database().reference(withPath: ".info/connected").removeObserver(withHandle: connectedHandle)
        }
    }
}
