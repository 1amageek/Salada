//
//  AppDelegate.swift
//  SaladBar
//
//  Created by 1amageek on 2017/05/20.
//  Copyright © 2017年 Stamp Inc. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    var handle: AuthStateDidChangeListenerHandle?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        FirebaseApp.configure()
        
        if let _: User = Auth.auth().currentUser {
            self.window = UIWindow(frame: UIScreen.main.bounds)
            self.window?.rootViewController = mainViewController()
            self.window?.makeKeyAndVisible()
        } else {
            self.window = UIWindow(frame: UIScreen.main.bounds)
            self.window?.rootViewController = startViewController()
            self.window?.makeKeyAndVisible()
        }
        
        handle = Auth.auth().addStateDidChangeListener({ [unowned self] (auth, user) in
            debugPrint("Auth change status", auth)
            guard let _: User = user else {
                self.crossDissolveWindow(with: self.startViewController())
                return
            }
            guard let currentViewController = self.window?.rootViewController else {
                return
            }
            if !(currentViewController is UITabBarController) {
                self.crossDissolveWindow(with: self.mainViewController())
            }
        })
        
        return true
    }
    
    func crossDissolveWindow(with viewController: UIViewController) {
        if let currentWindow: UIWindow = self.window,
            let currentViewController: UIViewController = currentWindow.rootViewController {
            if currentViewController.self != viewController.self {
                let newWindow = UIWindow(frame: UIScreen.main.bounds)
                newWindow.rootViewController = viewController
                newWindow.alpha = 0
                newWindow.makeKeyAndVisible()
                UIView.animate(withDuration: 0.3, animations: { () -> Void in
                    newWindow.alpha = 1
                    currentWindow.alpha = 0
                }, completion: { (finished) -> Void in
                    self.window = newWindow
                })
            }
        }
    }
    
    func startViewController() -> EntranceViewController {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Entrance", bundle: nil)
        let viewController: EntranceViewController = storyBoard.instantiateInitialViewController() as! EntranceViewController
        return viewController
    }
    
    func mainViewController() -> UITabBarController {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController: UITabBarController = storyBoard.instantiateInitialViewController() as! UITabBarController
        return viewController
    }

}

