//
//  SingleListViewModel.swift
//  ToDoList
//
//  Created by Swain Molster on 9/7/19.
//  Copyright © 2019 Swain Molster. All rights reserved.
//

import Foundation

protocol SingleListViewModelInputs: class {
    /// Call at end of viewDidLoad.
    func viewDidLoad()
    
    /// Call when the user changes the completion state of an item.
    func userChangedCompleteStateOfItem(at index: Int, to newValue: Bool)
    
    /// Call when the user taps the add button.
    func userTappedAddButton()
    
    /// Call when the user finishes editing a new item.
    func userFinishedEditingNewItem(newText: String)
    
    /// Call when the user finishes editing an existing item.
    func userFinishedEditingExistingItem(at index: Int, newText: String)
    
    /// Call when the user attempts to delete an item
    func userDeletedItem(at index: Int)
}

protocol SingleListViewModelOutputs: class {
    /// Returns the screen's title.
    var title: String { get }
    
    /// Outputs when the provided items should be displayed.
    var displayItems: OutputFunction<[ToDoItemDisplay]>? { get set }
    
    /// Outputs when the user should begin editing a new item.
    var beginEditingNewItem: OutputFunction<Void>? { get set }
    
    /// Outputs when the provided item should be inserted into the table at the provided index..
    var insertItemAtIndex: OutputFunction<(item: ToDoItemDisplay, index: Int)>? { get set }
    
    /// Outputs when the provided item should be updated into the table at the given index.
    var updateItemAtIndex: OutputFunction<(item: ToDoItemDisplay, index: Int)>? { get set }
    
    /// Outputs when an item at the provided index needs to be removed from the table.
    var removeItemAtIndex: OutputFunction<Int>? { get set }
    
    /// Outputs when the user should be taken back to the previous screen.
    var goBack: OutputFunction<Void>? { get set }
    
    /// Outputs when the provided alert should be displayed.
    var displayAlert: OutputFunction<UserAlert>? { get set }
}

protocol SingleListViewModelType: class {
    var inputs: SingleListViewModelInputs { get }
    var outputs: SingleListViewModelOutputs { get }
}

final class SingleListViewModel: SingleListViewModelInputs, SingleListViewModelOutputs, SingleListViewModelType {
    
    var inputs: SingleListViewModelInputs { return self }
    var outputs: SingleListViewModelOutputs { return self }
    
    /// Sorting algorithm for descending dateCreated order. Most recently to least recently.
    private let descendingDateCreatedOrder: (ToDoItem, ToDoItem) -> Bool = { a, b in
        return a.dateCreated > b.dateCreated
    }
    
    /// Database instance for updating.
    private let database: Database
    
    /// The list being viewed.
    private var list: ToDoList
    
    init(list: ToDoList, database: Database) {
        self.list = list
        self.database = database
    }
    
    // MARK: Outputs
    var title: String { return list.name }
    var displayItems: OutputFunction<[ToDoItemDisplay]>?
    var beginEditingNewItem: OutputFunction<Void>?
    var insertItemAtIndex: OutputFunction<(item: ToDoItemDisplay, index: Int)>?
    var updateItemAtIndex: OutputFunction<(item: ToDoItemDisplay, index: Int)>?
    var removeItemAtIndex: OutputFunction<Int>?
    var goBack: OutputFunction<Void>?
    var displayAlert: OutputFunction<UserAlert>?
    
    // MARK: Inputs
    
    func viewDidLoad() {
        // Time to sort the items, and probably a good idea to get off the main thread to do that sorting.
        DispatchQueue.global().sync {
            list.items.sort(by: descendingDateCreatedOrder)
            self.outputs.displayItems?(self.list.items.map(display(from:)))
        }
    }
    
    func userChangedCompleteStateOfItem(at index: Int, to newValue: Bool) {
        let item = self.list.items[index]
        let now = Date()
        database.updateItem(withID: item.id, newText: item.text, dateLastModified: now, dateCompleted: newValue ? now : nil)
            .handle(using: self.handleDatabaseError(_:)) { updatedItem in
                self.list.items[index] = updatedItem
                self.outputs.updateItemAtIndex?((display(from: updatedItem), index))
            }
    }
    
    func userTappedAddButton() {
        self.outputs.beginEditingNewItem?(())
    }
    
    func userFinishedEditingNewItem(newText: String) {
        if newText.isEmpty {
            self.outputs.removeItemAtIndex?(0)
        } else {
            database.createNewItem(inListWithID: self.list.id, text: newText, dateCompleted: nil)
                .handle(using: self.handleDatabaseError(_:)) { newItem in
                    // SWAIN: Better explanation.
                    // We expect the UI to not need to know about this insert.
                    self.list.items.insert(newItem, at: 0)
                }
        }
    }
    
    func userFinishedEditingExistingItem(at index: Int, newText: String) {
        if newText.isEmpty {
        // User set text to empty, so we delete the item.
            database.deleteItems(withIDs: [self.list.items[index].id])
                .handle(using: self.handleDatabaseError(_:)) {
                    self.list.items.remove(at: index)
                    self.outputs.removeItemAtIndex?(index)
                }
        } else {
        // Otherwise, update.
            database.updateItem(withID: list.items[index].id, newText: newText, dateLastModified: Date(), dateCompleted: list.items[index].dateCompleted)
                .handle(using: self.handleDatabaseError(_:)) { updatedItem in
                    self.list.items[index] = updatedItem
                }
        }
    }
    
    func userDeletedItem(at index: Int) {
        database.deleteItems(withIDs: [list.items[index].id])
            .handle(using: self.handleDatabaseError(_:)) {
                self.list.items.remove(at: index)
                self.outputs.removeItemAtIndex?(index)
            }
    }
    
    // MARK: - Private Functions
    
    /// Handles a provided `error`, displaying an alert to the user.
    private func handleDatabaseError(_ error: DatabaseError) {
        self.outputs.displayAlert?(UserAlert(
            style: .alert,
            title: "Internal Error",
            message: "Oops! Looks like we encountered an error in our internal database. Please try again.",
            options: [.ok(action: { dismiss in
                dismiss()
                self.outputs.goBack?(())
            })]
        ))
    }
}

func display(from item: ToDoItem) -> ToDoItemDisplay {
    return (item.text, item.isComplete)
}
