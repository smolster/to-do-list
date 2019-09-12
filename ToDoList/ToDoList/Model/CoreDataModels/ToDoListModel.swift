//
//  ToDoListModel.swift
//  ToDoList
//
//  Created by Swain Molster on 9/6/19.
//  Copyright © 2019 Swain Molster. All rights reserved.
//

import Foundation
import CoreData

public class ToDoListModel: NSManagedObject {

    @nonobjc public class func createFetchRequest() -> NSFetchRequest<ToDoListModel> {
        return NSFetchRequest<ToDoListModel>(entityName: "ToDoListModel")
    }
    
    @NSManaged public var dateCreated: Date
    @NSManaged public var name: String
    @NSManaged public var dateLastModified: Date
    @NSManaged public var items: NSSet
}

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

extension ToDoListModel {
    func toDoList() -> ToDoList {
        guard let itemModels = self.items as? Set<ToDoItemModel> else {
            // TODO: Better message here.
            Logger.error("Something wrong here")
            fatalError()
        }
        return ToDoList(dateCreated: self.dateCreated, dateLastModified: self.dateLastModified, name: self.name, items: itemModels.map { $0.toDoItem() })
    }
}
