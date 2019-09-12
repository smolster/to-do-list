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
    var dateLastModified: Date
    var name: String
    
    /// In no particular order!
    var items: [ToDoItem]
}

extension ToDoList: Identifiable {
    typealias ID = Date
    var id: Date { return dateCreated }
}
