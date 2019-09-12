//
//  CoreDataDatabase.swift
//  ToDoList
//
//  Created by Swain Molster on 9/6/19.
//  Copyright © 2019 Swain Molster. All rights reserved.
//

import Foundation
import CoreData

/// An implementation of our `Database` protocol that uses CoreData for storage.
final class CoreDataDatabase: Database {
    
    /// Our `NSPersistentContainer` instance.
    private let container: NSPersistentContainer
    
    var databaseChangeHandler: ((DatabaseChange) -> Void)?
    
    init() {
        container = NSPersistentContainer(name: "ToDoList")
        container.loadPersistentStores { storeDescription, error in
            self.container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            if let error = error {
                Logger.error("CoreData Error: \(error)")
            }
        }
    }
    
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
                return .failure(.uncategorized(error))
            }
        }
    }
    
    func createNewList(name: String) -> DatabaseResult<ToDoList> {
        return performOnDatabaseThread { saveChanges in
            let list = ToDoListModel(context: self.container.viewContext)
            list.name = name
            let now = Date()
            list.dateCreated = now
            list.dateLastModified = now
            
            let toDoList = list.toDoList()
            return saveChanges([.listCreated(toDoList)])
                .flatMap { return .success(toDoList) }
        }
    }
    
    func createNewItem(inListWithID id: ToDoList.ID, text: String, dateCompleted: Date?) -> DatabaseResult<ToDoItem> {
        return performOnDatabaseThread { saveChanges in
            // First, need to find list with provided name.
            let listFetchRequest = ToDoListModel.createFetchRequest()
            listFetchRequest.predicate = NSPredicate(format: "dateCreated == %@", id as NSDate)
            do {
                // Data model is marked unique for `name` property, so just try to grab first.
                guard let list = try self.container.viewContext.fetch(listFetchRequest).first else {
                    fatalError("CoreData Programmer Error: Could not create new item in list with dateCreated '\(id)', no list found.")
                }
                
                let item = ToDoItemModel(context: container.viewContext)
                item.list = list
                item.text = text
                item.dateCompleted = dateCompleted
                
                let now = Date()
                item.dateCreated = now
                item.dateLastModified = now
                list.dateLastModified = now
                
                list.addToItems(item)
                
                let toDoItem = item.toDoItem()
                return saveChanges([.itemCreated(toDoItem)])
                    .flatMap { return .success(toDoItem)}
            } catch let error {
                Logger.error("CoreData: Couldn't create new item \(text). Error Message: \(error)")
                return .failure(.uncategorized(error))
            }
        }
    }
    
    func updateList(withID id: ToDoList.ID, newName: String, dateLastModified: Date) -> DatabaseResult<ToDoList> {
        return performOnDatabaseThread { saveChanges in
            return loadModels(forListsWithIDs: [id])
                .flatMap { models in
                    guard let model = models.first else {
                        return .failure(.noListFound(withID: id))
                    }
                    model.name = newName
                    model.dateLastModified = dateLastModified
                    
                    let list = model.toDoList()
                    return saveChanges([.listUpdated(list)])
                        .flatMap { return .success(list) }
                }
        }
    }
    
    func updateItem(withID id: ToDoItem.ID, newText: String, dateLastModified: Date, dateCompleted: Date?) -> DatabaseResult<ToDoItem> {
        return performOnDatabaseThread { saveChanges in
            return loadModels(forItemsWithIDs: [id])
                .flatMap { itemModels in
                    guard let model = itemModels.first else {
                        return .failure(.noItemFound(withID: id))
                    }
                    model.text = newText
                    model.dateCompleted = dateCompleted
                    
                    if model.dateLastModified != dateLastModified {
                        model.dateLastModified = dateLastModified
                        model.list.dateLastModified = dateLastModified
                    }
                    
                    let item = model.toDoItem()
                    return saveChanges([.itemUpdated(item)])
                        .flatMap { return .success(item) }
                }
        }
    }
    
    func deleteItems(withIDs ids: [ToDoItem.ID]) -> DatabaseResult<Void> {
        return performOnDatabaseThread { saveChanges in
            return loadModels(forItemsWithIDs: ids)
                .flatMap { itemModels in
                    itemModels.forEach(container.viewContext.delete)
                    return saveChanges([.itemsDeleted(ids: itemModels.map { $0.dateCreated })])
                }
        }
    }
    
    func deleteLists(withIDs ids: [ToDoList.ID]) -> DatabaseResult<Void> {
        return performOnDatabaseThread { saveChanges in
            return loadModels(forListsWithIDs: ids)
                .flatMap { listModels in
                    // First, delete all of the item Models.
                    let itemModels = listModels.flatMap { $0.items.allObjects as! [ToDoItemModel] }
                    itemModels.forEach(container.viewContext.delete)
                    listModels.forEach(container.viewContext.delete)
                    return saveChanges([
                        .itemsDeleted(ids: itemModels.map { $0.dateCreated }),
                        .listsDeleted(ids: listModels.map { $0.dateCreated })
                    ])
                }
        }
    }
    
}

extension CoreDataDatabase {
    /**
     Synchronously performs a provided `block` on the `CoreDataDatabase`'s private queue. The provided `block` will be passed a closure parameter that can be used to save changes in the `viewContext`.
     
     - parameter block: The block to perform.
     - parameter saveFunction: A function that can be called to save any changes to the database. Returns `nil` in the case of a successful save. Otherwise, returns a `DatabaseError`.
     - parameter changes: The changes to be saved.
     */
    private func performOnDatabaseThread<T>(_ block: (_ saveFunction: (_ changes: [DatabaseChange]) -> DatabaseResult<Void>) -> T) -> T {
        var returnValue: T!
        self.container.viewContext.performAndWait {
            returnValue = block { changes in
                guard self.container.viewContext.hasChanges else {
                    // Nothing to save, just return.
                    return .success(())
                }
                do {
                    try self.container.viewContext.save()
                    Logger.info("CoreData: Successfully saved viewContext.")
                    
                    // Broadcast updates on a global queue.
                    DispatchQueue.global().async {
                        Logger.info("Database changes: \(changes)")
                        changes.forEach { self.databaseChangeHandler?($0) }
                    }
                    return .success(())
                } catch let error {
                    Logger.error("CoreData: Error saving viewContext: \(error)")
                    return .failure(.uncategorized(error))
                }
            }
        }
        
        return returnValue
    }
}

extension CoreDataDatabase {
    /**
     Loads the item models associated with the provided `ids`. Objects are returned in-order corresponding to the order of the provided array of ids.
     
     - parameter ids: The unique identifiers of the desired items.
     - returns: A `DatabaseResult` over the models.
     */
    private func loadModels(forItemsWithIDs ids: [ToDoItem.ID]) -> DatabaseResult<[ToDoItemModel]> {
        do {
            var itemModels: [ToDoItemModel] = []
            for id in ids {
                let fetchRequest = ToDoItemModel.createFetchRequest()
                fetchRequest.predicate = NSPredicate(format: "dateCreated == %@", id as NSDate)
                
                guard let model = try container.viewContext.fetch(fetchRequest).first else {
                    return .failure(.noItemFound(withID: id))
                }
                
                itemModels.append(model)
            }
            
            return .success(itemModels)
        } catch let error {
            Logger.error("CoreData: Error loading ToDoItemModels: \(error)")
            return .failure(.uncategorized(error))
        }
    }
    
    /**
     Loads the list models associated with the provided `ids`. Objects are returned in-order corresdponding to the order of the provided array of ids.
     
     - parameter ids: The unique identifiers of the desired lists.
     - returns: A `DatabaseResult` over the models.
     */
    private func loadModels(forListsWithIDs ids: [ToDoList.ID]) -> DatabaseResult<[ToDoListModel]> {
        do {
            var listModels: [ToDoListModel] = []
            for id in ids {
                let fetchRequest = ToDoListModel.createFetchRequest()
                fetchRequest.predicate = NSPredicate(format: "dateCreated == %@", id as NSDate)
                
                guard let model = try container.viewContext.fetch(fetchRequest).first else {
                    return .failure(.noListFound(withID: id))
                }
                
                listModels.append(model)
            }
            
            return .success(listModels)
        } catch let error {
            Logger.error("CoreData: Error loading ToDoItemLists: \(error)")
            return .failure(.uncategorized(error))
        }
    }
}
