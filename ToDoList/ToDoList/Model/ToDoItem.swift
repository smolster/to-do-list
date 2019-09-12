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
    var dateLastModified: Date
    var dateCompleted: Date?
    var listID: ToDoList.ID
}

extension ToDoItem {
    var isComplete: Bool { return dateCompleted != nil }
}

extension ToDoItem: Identifiable {
    typealias ID = Date
    var id: Date { return self.dateCreated }
}
