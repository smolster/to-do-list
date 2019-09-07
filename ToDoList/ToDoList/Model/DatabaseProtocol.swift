//
//  DatabaseProtocol.swift
//  ToDoList
//
//  Created by Swain Molster on 9/7/19.
//  Copyright © 2019 Swain Molster. All rights reserved.
//

import Foundation

typealias DatabaseResult<T> = Result<T, DatabaseError>

enum DatabaseError: Error {
    // TODO: Remove
    case placeholder
}

protocol Database {
    
    func getAllToDoLists() -> DatabaseResult<[ToDoList]>
    func getAllToDoItems() -> DatabaseResult<[ToDoItem]>
    
    func createNewList(name: String) -> DatabaseResult<ToDoList>
    func createNewItem(inListWithName name: String, text: String, dateCompleted: Date?) -> DatabaseResult<ToDoItem>
    
    func updateListName(oldName: String, newName: String) -> DatabaseResult<ToDoList>
    func updateItem(havingDateCreated dateCreated: Date, newText: String, dateCompleted: Date?) -> DatabaseResult<ToDoItem>
    
    @discardableResult
    func delete(items: ToDoItem...) -> DatabaseResult<Void>
    @discardableResult
    func delete(lists: ToDoList...) -> DatabaseResult<Void>
    
}
