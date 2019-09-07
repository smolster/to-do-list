//
//  ToDoItem.swift
//  ToDoList
//
//  Created by Swain Molster on 9/7/19.
//  Copyright © 2019 Swain Molster. All rights reserved.
//

import Foundation

struct ToDoItem {
    var text: String
    var dateCreated: Date
    var dateCompleted: Date?
    var listName: String
}

extension ToDoItem {
    var isComplete: Bool { return dateCompleted != nil }
}

extension ToDoItemModel {
    func toDoItem() -> ToDoItem {
        return ToDoItem(text: self.text, dateCreated: self.dateCreated, dateCompleted: self.dateCompleted, listName: self.list.name)
    }
}
