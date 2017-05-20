//
//  FeedGenerator.swift
//  SaladBar
//
//  Created by 1amageek on 2017/05/20.
//  Copyright © 2017年 Stamp Inc. All rights reserved.
//

import Foundation
import FirebaseAuth
import Firebase
import Salada

class FeedGenerator {
    
    static let shared: FeedGenerator = FeedGenerator()
    
    let queue: DispatchQueue = DispatchQueue(label: "salada.feed.queue")
    
    var processing: Bool = false
    
    static let greetings: [String] = [
        "Hello!! 😁",
        "Whats up😎",
        "What’s new?",
        "What’s going on?",
        "Hey 🌤",
        "How’s everything ?",
        "How are things?",
        "Nice to see you😃",
        "Good morning",
        "Good afternoon"
    ]
    
    let createTask: DispatchWorkItem = DispatchWorkItem { 
        SaladBar.User.current({ (me) in
            guard let me: SaladBar.User = me else {
                return
            }
            let random: Int = Int(arc4random() % 10)
            let greeting: String = FeedGenerator.greetings[random]
            let feed: SaladBar.Feed = SaladBar.Feed()
            feed.userID = me.id
            feed.text = greeting
            feed.save { (ref, error) in
                if let error = error {
                    debugPrint(error)
                    return
                }
                me.feeds.insert(ref!.key)
            }
        })
    }
    
    class func start() {
        shared.start()
    }
    
    class func stop() {
        shared.processing = false
    }
    
    func start() {
        self.processing = true
        self.queue.async {
            repeat {
                DispatchQueue.main.async(execute: self.createTask)
                sleep(3)
            } while self.processing
        }
    }
    
}
