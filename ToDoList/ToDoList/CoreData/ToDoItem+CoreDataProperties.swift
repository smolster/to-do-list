//
//  ToDoItem+CoreDataProperties.swift
//  ToDoList
//
//  Created by Swain Molster on 9/6/19.
//  Copyright © 2019 Swain Molster. All rights reserved.
//

import Foundation
import CoreData

extension ToDoItem {

    @nonobjc public class func createFetchRequest() -> NSFetchRequest<ToDoItem> {
        return NSFetchRequest<ToDoItem>(entityName: "ToDoItem")
    }

    @NSManaged public var dateCompleted: Date
    @NSManaged public var id: UUID
    @NSManaged public var isComplete: Bool
    @NSManaged public var text: String

}
