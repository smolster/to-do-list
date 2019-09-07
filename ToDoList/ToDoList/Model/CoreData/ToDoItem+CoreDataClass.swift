//
//  ToDoItemModel+CoreDataClass.swift
//  ToDoList
//
//  Created by Swain Molster on 9/6/19.
//  Copyright © 2019 Swain Molster. All rights reserved.
//
//

import Foundation
import CoreData

public class ToDoItemModel: NSManagedObject {

}

extension ToDoItemModel {
    
    @nonobjc public class func createFetchRequest() -> NSFetchRequest<ToDoItemModel> {
        return NSFetchRequest<ToDoItemModel>(entityName: "ToDoItemModel")
    }
    
    @NSManaged public var dateCompleted: Date?
    @NSManaged public var text: String
    @NSManaged public var dateCreated: Date
    @NSManaged public var list: ToDoListModel
    
    public var isComplete: Bool {
        return dateCompleted != nil
    }
}
