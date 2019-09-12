//
//  AppDelegate.swift
//  ToDoList
//
//  Created by Swain Molster on 9/6/19.
//  Copyright © 2019 Swain Molster. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    let window = UIWindow()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        let allListsVC = AllListsViewController(viewModel: AllListsViewModel(database: CoreDataDatabase()))
        self.window.rootViewController = UINavigationController(rootViewController: allListsVC)
        self.window.makeKeyAndVisible()
        return true
    }

}

