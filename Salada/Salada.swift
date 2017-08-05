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

    static let shared: Salada = Salada()

    private(set) var isConnected: Bool = false

    class func configure(isPersistenceEnabled: Bool = false) {
        let shared = Salada.shared
        Database.database().isPersistenceEnabled = isPersistenceEnabled
        Database.database().reference(withPath: ".info/connected").observe(.value) { (snapshot) in
            debugPrint("[Salada] .info/connected", snapshot)
            shared.isConnected = snapshot.value as? Bool ?? false
        }
    }

    class var isPersistenced: Bool {
        return Database.database().isPersistenceEnabled
    }

}
