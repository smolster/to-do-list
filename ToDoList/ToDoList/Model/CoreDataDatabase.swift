//
//  CoreDataDatabase.swift
//  ToDoList
//
//  Created by Swain Molster on 9/6/19.
//  Copyright © 2019 Swain Molster. All rights reserved.
//

import Foundation
import CoreData

// TODO: How to handle database errors?
// TODO: Documentation

final class CoreDataDatabase: Database {
    
    func getAllToDoLists() -> DatabaseResult<[ToDoList]> {
        return performOnDatabaseThread { _ in
            let fetchRequest = ToDoListModel.createFetchRequest()
            // Sort by dateCreated
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "dateCreated", ascending: true)]
            
            do {
                let lists = try container.viewContext.fetch(fetchRequest)
                Logger.info("CoreDate: Fetched \(lists.count) ToDoLists.")
                return .success(lists.map { $0.toDoList() })
            } catch let error {
                Logger.error("CoreData: Error fetching ToDoLists: \(error)")
                return .failure(.placeholder)
            }
        }
    }
    
    func getAllToDoItems() -> DatabaseResult<[ToDoItem]> {
        return performOnDatabaseThread { saveChanges in
            let fetchRequest = ToDoItemModel.createFetchRequest()
            // Sort?
            fetchRequest.sortDescriptors = []
            
            do {
                let items = try container.viewContext.fetch(fetchRequest)
                Logger.info("CoreData: Fetched \(items.count) ToDoItems.")
                return .success(items.map { $0.toDoItem() })
            } catch let error {
                Logger.error("CoreData: Error fetching ToDoItems: \(error)")
                return .failure(.placeholder)
            }
        }
    }
    
    func createNewList(name: String) -> DatabaseResult<ToDoList> {
        return performOnDatabaseThread { saveChanges in
            let list = ToDoListModel(context: self.container.viewContext)
            list.name = name
            list.dateCreated = Date()
            
            return saveChanges()
                .flatMap { return .success(list.toDoList()) }
        }
    }
    
    func createNewItem(inListWithName name: String, text: String, dateCompleted: Date?) -> DatabaseResult<ToDoItem> {
        return performOnDatabaseThread { saveChanges in
            // First, need to find list with provided name.
            let listFetchRequest = ToDoListModel.createFetchRequest()
            listFetchRequest.predicate = NSPredicate(format: "name == %@", name)
            do {
                // Data model is marked unique for `name` property, so just try to grab first.
                guard let list = try self.container.viewContext.fetch(listFetchRequest).first else {
                    fatalError("CoreData Programmer Error: Could not create new item in list with name '\(name)', no list found.")
                }
                
                let item = ToDoItemModel(context: container.viewContext)
                item.list = list
                item.dateCreated = Date()
                item.text = text
                item.dateCompleted = dateCompleted
                
                return saveChanges()
                    .flatMap { return .success(item.toDoItem())}
            } catch let error {
                Logger.error("CoreData: Couldn't create new item \(name). Error Message: \(error)")
                return .failure(.placeholder)
            }
        }
    }
    
    func updateListName(oldName: String, newName: String) -> DatabaseResult<ToDoList> {
        return performOnDatabaseThread { saveChanges in
            
            return loadModels(forListsWithNames: [oldName])
                .flatMap { models in
                    
                    guard let model = models.first else {
                        Logger.error("CoreData Programmer Error: Found no ToDoListModel with name \(oldName)")
                        fatalError()
                    }
                    model.name = newName
                    
                    return saveChanges()
                        .flatMap { return .success(model.toDoList()) }
                }
        }
    }
    
    func updateItem(havingDateCreated dateCreated: Date, newText: String, dateCompleted: Date?) -> DatabaseResult<ToDoItem> {
        return performOnDatabaseThread { saveChanges in
            return loadModels(forItemsWithIds: [dateCreated])
                .flatMap { itemModels in
                    guard let model = itemModels.first else {
                        Logger.error("CoreData Programmer Error: Found no ToDoItemModel with dateCreated \(dateCreated)")
                        fatalError()
                    }
                    model.text = newText
                    model.dateCompleted = dateCompleted
                    
                    return saveChanges()
                        .flatMap { return .success(model.toDoItem()) }
                }
        }
    }
    
    func delete(items: ToDoItem...) -> DatabaseResult<Void> {
        return performOnDatabaseThread { saveChanges in
            return loadModels(forItemsWithIds: items.map { $0.dateCreated })
                .flatMap { itemModels in
                    itemModels.forEach(container.viewContext.delete)
                    return saveChanges()
                }
        }
    }
    
    func delete(lists: ToDoList...) -> DatabaseResult<Void> {
        return performOnDatabaseThread { saveChanges in
            return loadModels(forListsWithNames: lists.map { $0.name })
                .flatMap { listModels in
                    listModels.forEach(container.viewContext.delete)
                    return saveChanges()
                }
        }
    }
    
    
    private let container: NSPersistentContainer
    private let accessQueue: DispatchQueue
    
    init() {
        accessQueue = DispatchQueue(label: "database", qos: .userInitiated)
        
        container = NSPersistentContainer(name: "ToDoList")
        container.loadPersistentStores { storeDescription, error in
            self.container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            
            if let error = error {
                // TODO: How to handle this?
                Logger.error("CoreData Error: \(error)")
            }
        }
    }
    
    
}

extension CoreDataDatabase {
    /**
     Synchronously performs a provided `block` on the `CoreDataDatabase`'s private queue.
     
     - parameter block: The block to perform.
     - parameter saveFunction: A function that can be called to save any changes to the database. Returns `nil` in the case of a successful save. Otherwise, returns a `DatabaseError`.
     */
    private func performOnDatabaseThread<T>(_ block: (_ saveFunction: () -> DatabaseResult<Void>) -> T) -> T {
        return accessQueue.sync {
            return block {
                guard container.viewContext.hasChanges else {
                    // Nothing to save, just return.
                    return .success(())
                }
                do {
                    try container.viewContext.save()
                    Logger.info("CoreData: Successfully saved viewContext.")
                    return .success(())
                } catch let error {
                    Logger.error("CoreData: Error saving viewContext: \(error)")
                    return .failure(.placeholder)
                }
            }
        }
    }
}

extension CoreDataDatabase {
    /**
     Loads the database models associated with the provided item ids.
     
     - parameter items: The desired model object information.
     
     */
    private func loadModels(forItemsWithIds creationDates: [Date]) -> DatabaseResult<[ToDoItemModel]> {
        do {
            var itemModels: [ToDoItemModel] = []
            for date in creationDates {
                let fetchRequest = ToDoItemModel.createFetchRequest()
                fetchRequest.predicate = NSPredicate(format: "dateCreated == %@", date as NSDate)
                
                guard let model = try container.viewContext.fetch(fetchRequest).first else {
                    Logger.error("CoreData Programmer Error: Found no ToDoItemModel with dateCreated \(date)")
                    fatalError()
                }
                
                itemModels.append(model)
            }
            
            return .success(itemModels)
        } catch let error {
            Logger.error("CoreData: Error loading ToDoItemModels -- \(error)")
            return .failure(.placeholder)
        }
    }
    
    private func loadModels(forListsWithNames names: [String]) -> DatabaseResult<[ToDoListModel]> {
        do {
            var listModels: [ToDoListModel] = []
            for name in names {
                let fetchRequest = ToDoListModel.createFetchRequest()
                fetchRequest.predicate = NSPredicate(format: "name == %@", name)
                
                guard let model = try container.viewContext.fetch(fetchRequest).first else {
                    Logger.error("CoreData Programmer Error: Found no ToDoListModel with name \(name)")
                    fatalError()
                }
                
                listModels.append(model)
            }
            
            return .success(listModels)
        } catch let error {
            // TODO: Handle error.
            Logger.error("CoreData: Error loading ToDoItemLists -- \(error)")
            return .failure(.placeholder)
        }
    }
}
