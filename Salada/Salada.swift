//
//  Salada.swift
//  Salada
//
//  Created by 1amageek on 2017/08/04.
//  Copyright © 2017年 Stamp. All rights reserved.
//

import Foundation
import Firebase

class Salada: NSObject {

    private(set) static var shared: Salada = Salada()

    private(set) var isConnected: Bool = false

    override init() {
        super.init()
    }

    convenience init(isPersistenceEnabled: Bool = false) {
        self.init()
        Database.database().isPersistenceEnabled = isPersistenceEnabled
        _connectedHandle = Database.database().reference(withPath: ".info/connected").observe(.value) { (snapshot) in
            debugPrint("[Salada] .info/connected", snapshot)
            self.isConnected = snapshot.value as? Bool ?? false
        }
    }

    class func configure(isPersistenceEnabled: Bool = false) {
        self.shared = Salada(isPersistenceEnabled: isPersistenceEnabled)
    }

    class var isPersistenced: Bool {
        return Database.database().isPersistenceEnabled
    }

    private(set) var _connectedHandle: DatabaseHandle!

    deinit {
        Database.database().reference(withPath: ".info/connected").removeObserver(withHandle: _connectedHandle)
    }

}
