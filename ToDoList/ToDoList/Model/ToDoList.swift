//
//  ToDoList.swift
//  ToDoList
//
//  Created by Swain Molster on 9/7/19.
//  Copyright © 2019 Swain Molster. All rights reserved.
//

import Foundation

struct ToDoList {
    var dateCreated: Date
    var name: String
    var items: [ToDoItem]
}

extension ToDoListModel {
    func toDoList() -> ToDoList {
        // TODO: Get items from set.
        return ToDoList(dateCreated: self.dateCreated, name: self.name, items: [])
    }
}
