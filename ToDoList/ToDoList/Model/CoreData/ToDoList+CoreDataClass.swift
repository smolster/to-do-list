//
//  ToDoListModel+CoreDataClass.swift
//  ToDoList
//
//  Created by Swain Molster on 9/6/19.
//  Copyright © 2019 Swain Molster. All rights reserved.
//
//

import Foundation
import CoreData

public class ToDoListModel: NSManagedObject {

}

extension ToDoListModel {
    
    @nonobjc public class func createFetchRequest() -> NSFetchRequest<ToDoListModel> {
        return NSFetchRequest<ToDoListModel>(entityName: "ToDoListModel")
    }
    
    @NSManaged public var dateCreated: Date
    @NSManaged public var name: String
    @NSManaged public var items: NSSet
    
}

// MARK: Generated accessors for items
extension ToDoListModel {
    
    @objc(addItemsObject:)
    @NSManaged public func addToItems(_ value: ToDoItemModel)
    
    @objc(removeItemsObject:)
    @NSManaged public func removeFromItems(_ value: ToDoItemModel)
    
    @objc(addItems:)
    @NSManaged public func addToItems(_ values: NSSet)
    
    @objc(removeItems:)
    @NSManaged public func removeFromItems(_ values: NSSet)
    
}
