//
//  Firebase+User.swift
//  SaladBar
//
//  Created by 1amageek on 2017/05/20.
//  Copyright © 2017年 Stamp Inc. All rights reserved.
//

import Foundation
import Firebase
import FirebaseAuth
import Salada

extension SaladBar {
    class User: Salada.Object {
        
        typealias Element = User
        
        dynamic var profileImage: Salada.File?
        
        dynamic var name: String?
        
        dynamic var feeds: Set<String> = []
        
    }
}

extension SaladBar.User {
    static func current(_ completionHandler: @escaping ((SaladBar.User?) -> Void)) {
        guard let user: User = Auth.auth().currentUser else {
            completionHandler(nil)
            return
        }
        SaladBar.User.observeSingle(user.uid, eventType: .value, block: { (user) in
            guard let user: SaladBar.User = user as? SaladBar.User else {
                _ = try? Auth.auth().signOut()
                completionHandler(nil)
                return
            }
            completionHandler(user)
        })
    }
}
