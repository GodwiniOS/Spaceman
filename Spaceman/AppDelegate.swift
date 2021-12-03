//
//  File.swift
//  Spaceman
//
//  Created by Godwin A on 31/07/18.
//  Copyright © 2018 Godwin A. All rights reserved.
//

import UIKit
import SpriteKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func applicationDidEnterBackground(_ application: UIApplication) {
        if let view = window?.rootViewController?.view as? SKView {
            view.isPaused = true
        }
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        if let view = window?.rootViewController?.view as? SKView {
            view.isPaused = false
        }
    }
}
