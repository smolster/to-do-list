//
//  Database.swift
//  ToDoList
//
//  Created by Swain Molster on 9/6/19.
//  Copyright © 2019 Swain Molster. All rights reserved.
//

import Foundation
import CoreData

class Database {
    
    static let shared = Database()
    
    fileprivate let container: NSPersistentContainer
    
    private init() {
        container = NSPersistentContainer.init(name: "ToDoList")
        container.loadPersistentStores { storeDescription, error in
            if let error = error {
                Logger.error("CoreData Error: \(error)")
            }
        }
    }
    
    private func saveChangesToDisk() {
        if container.viewContext.hasChanges {
            do {
                try container.viewContext.save()
            } catch let error {
                Logger.error("Error saving CoreData viewContext: \(error)")
            }
        }
    }
}

extension ToDoItem {
    static func create(in database: Database) -> ToDoItem {
        return ToDoItem(context: database.container.viewContext)
    }
}
