//
//  AppDelegate.swift
//  CDReader
//
//  Created by changdong cwx889303 on 2020/6/9.
//  Copyright © 2020 (c) Huawei Technologies Co., Ltd. 2012-2019. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        application.statusBarStyle = .lightContent
//        let shadow = NSShadow()
//        shadow.shadowColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0)
//        shadow.shadowOffset = CGSize(width: 0, height: 0)

        let navBar = UINavigationBar.appearance()
        navBar.setBackgroundImage(UIImage(named: "上导航栏-背景@2x"), for: .default)
        var textAttributes:[NSAttributedString.Key:Any] = [:]
        textAttributes[.foregroundColor] = UIColor(red: 251/255.0, green: 248/255.0, blue: 248/255.0, alpha: 1.0)
//        textAttributes[.shadow] = shadow
        textAttributes[.attachment] = UIFont.systemFont(ofSize: 20)
        navBar.titleTextAttributes = textAttributes
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

