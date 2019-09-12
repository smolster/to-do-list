//
//  DatabaseProtocol.swift
//  ToDoList
//
//  Created by Swain Molster on 9/7/19.
//  Copyright © 2019 Swain Molster. All rights reserved.
//

import Foundation

typealias DatabaseResult<T> = Result<T, DatabaseError>

/// Enumerates different errors that can occur within the database.
enum DatabaseError: Error {
    /// No item was found in the database with the provided ID.
    case noItemFound(withID: ToDoItem.ID)
    /// No list was found in the database with the provided ID.
    case noListFound(withID: ToDoList.ID)
    /// An uncategorized error occured.
    case uncategorized(Error)
}

/// Enumerates the different atomic changes that can happen in the database.
enum DatabaseChange {
    case itemCreated(ToDoItem)
    case listCreated(ToDoList)
    case itemUpdated(ToDoItem)
    case listUpdated(ToDoList)
    case itemsDeleted(ids: [ToDoItem.ID])
    case listsDeleted(ids: [ToDoList.ID])
}

protocol Database: class {
    
    /// A handler that will be called any time the database changes.
    var databaseChangeHandler: ((DatabaseChange) -> Void)? { get set }
    
    /// Returns all of the to-do lists in the database.
    func getAllToDoLists() -> DatabaseResult<[ToDoList]>
    
    /// Creates a new to-do list with the information provided.
    func createNewList(name: String) -> DatabaseResult<ToDoList>
    
    /**
     Creates a new to-do item with the information provided.
     
     - Parameters:
        - id: The `ID` of the `ToDoList` the item should be created within.
        - text: The text of the to-do.
        - dateCompleted: The date the to-do was completed, or `nil` if it is not yet complete.
     
     - Returns: A `DatabaseResult` over the created `ToDoItem`.
     */
    func createNewItem(inListWithID id: ToDoList.ID, text: String, dateCompleted: Date?) -> DatabaseResult<ToDoItem>
    
    /**
     Updates a to-do list in the database with the provided information.
     
     - Parameters:
        - id: The `ID` of the `ToDoList` being updated.
        - text: The new name of the list.
        - dateLastModified: The new "last modified" date.
     
     - Returns: A `DatabaseResult` over the updated `ToDoList`.
     */
    @discardableResult
    func updateList(withID id: ToDoList.ID, newName: String, dateLastModified: Date) -> DatabaseResult<ToDoList>
    
    /**
     Updates a to-do item in the database with the provided information
     
     - Parameters:
        - id: The `ID` of the `ToDoItem` being updated.
        - newText: The new text of the to-do.
        - dateLastModified: The new "last modified" date.
        - dateCompleted: The date the to-do was completed, or `nil` if it is not yet complete.
     
     - Returns: A `DatabaseResult` over the updated `ToDoItem`.
     */
    @discardableResult
    func updateItem(withID id: ToDoItem.ID, newText: String, dateLastModified: Date, dateCompleted: Date?) -> DatabaseResult<ToDoItem>
    
    /**
     Deletes a set of items in the database.
     
     - Parameters:
        - ids: The unique identifiers of the items to be deleted.
     
     - Returns: A `DatabaseResult` over `Void`.
     */
    @discardableResult
    func deleteItems(withIDs ids: [ToDoItem.ID]) -> DatabaseResult<Void>
    
    /**
     Deletes a set of lists in the database, and any items contained within those lists.
     
     - Parameters:
        - ids: The unique identifiers of the lists to be deleted.
     
     - Returns: A `DatabaseResult` over `Void`.
     */
    @discardableResult
    func deleteLists(withIDs ids: [ToDoList.ID]) -> DatabaseResult<Void>
    
}
