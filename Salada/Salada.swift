//
//  Salada.swift
//  Salada
//
//  Created by 1amageek on 2017/08/04.
//  Copyright © 2017年 Stamp. All rights reserved.
//

import Foundation
import Firebase

class Salada {

    static let shared: Salada = Salada()

    class func configure(isPersistenceEnabled: Bool = false) {
        _ = Salada.shared
        Database.database().isPersistenceEnabled = isPersistenceEnabled
    }

    class var isPersistenced: Bool {
        return Database.database().isPersistenceEnabled
    }

}
