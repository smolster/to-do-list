//
//  ToDoItem.swift
//  ToDoList
//
//  Created by Swain Molster on 9/6/19.
//  Copyright © 2019 Swain Molster. All rights reserved.
//

import Foundation

struct ToDoItem {
    var id: String
    var text: String
    var isComplete: Bool
}

struct ToDoList {
    var id: String
    var name: String
    var toDos: [ToDoItem]
}
