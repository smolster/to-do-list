//
//  AllListsViewModel.swift
//  ToDoList
//
//  Created by Swain Molster on 9/6/19.
//  Copyright © 2019 Swain Molster. All rights reserved.
//

import Foundation

protocol AllListsViewModelInputs: class {
    /// Call at end of viewDidLoad.
    func viewDidLoad()
    
    /// Call when the user taps the "+" button.
    func userTappedAddButton()
    
    /// Call when the user taps "OK" from the new list creation view.
    func userFinishedEditingNewList(name: String)
    
    /// Call when the user finishes editing the name of a list.
    func userFinishedEditingExistingList(at index: Int, newName: String)
    
    /// Call when the user taps a list.
    func userSelectedList(at index: Int)
    
    /// Call when user attempts to delete a list.
    func userAttemptedToDeleteList(at index: Int)
    
    /// Call when the user answers the delete confirmation.
    func userAnsweredDeleteConfirmation(shouldDelete: Bool)
}

protocol AllListsViewModelOutputs: class {
    
    /// Returns a title for the navigation item.
    var title: String { get }
    
    /// Outputs when the provided lists should be displayed in the UI.
    var displayLists: OutputFunction<[ToDoListDisplay]>? { get set }
    
    /// Outputs when the list at the provided index should be removed from the UI.
    var removeListAtIndex: OutputFunction<Int>? { get set }
    
    /// Outputs when the provided list should be inserted at the provided index in the UI.
    var insertListAtIndex: OutputFunction<(list: ToDoListDisplay, index: Int)>? { get set }
    
    /// Outputs when the user should be shown the new list creation modal.
    var showNewListCreationModal: OutputFunction<Void>? { get set }
    
    /// Outputs when the user should be shown a modal with the provided title and message.
    var showDeleteConfirmation: OutputFunction<(title: String, message: String)>? { get set }
    
    /// Outputs when a single-list detail view should be shown to the user, with the provided view model.
    var showSingleListViewWithViewModel: OutputFunction<SingleListViewModelType>? { get set }
    
    /// Outputs when an alert should be shown to the user, with the provided information.
    var displayAlert: OutputFunction<UserAlert>? { get set }
}

protocol AllListsViewModelType: class {
    var inputs: AllListsViewModelInputs { get }
    var outputs: AllListsViewModelOutputs { get }
}

final class AllListsViewModel: AllListsViewModelInputs, AllListsViewModelOutputs, AllListsViewModelType {
    
    var inputs: AllListsViewModelInputs { return self }
    var outputs: AllListsViewModelOutputs { return self }
    
    /// Sorting algorithm for descending dateModified order. Most recently to least recently.
    private let descendingDateModifiedOrder: (ToDoList, ToDoList) -> Bool = { a, b in
        return a.dateLastModified >= b.dateLastModified
    }
    
    private let database: Database
    
    /// Backing models.
    private var lists: [ToDoList] = []
    
    private let dateModifiedFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        return dateFormatter
    }()
    
    private var indexOfListStagedForDeletion: Int?
    
    init(database: Database) {
        self.database = database
    }
    
    // MARK: Outputs
    
    var title: String { return "To-Do Lists" }
    var displayLists: OutputFunction<[ToDoListDisplay]>?
    var removeListAtIndex: OutputFunction<Int>?
    var insertListAtIndex: OutputFunction<(list: ToDoListDisplay, index: Int)>?
    var showNewListCreationModal: OutputFunction<Void>?
    var showDeleteConfirmation: OutputFunction<(title: String, message: String)>?
    var showSingleListViewWithViewModel: OutputFunction<SingleListViewModelType>?
    var displayAlert: OutputFunction<UserAlert>?
    
    // MARK: Inputs
    
    func viewDidLoad() {
        // We need to assign a handler to our database, so that we can keep our in-memory model up-to-date in response to changes that may happen on subsequent view models (e.g. SingleList).
        database.databaseChangeHandler = { [weak self] change in
            switch change {
            // These are managed by us, so we can respond to them elsewhere. Just return.
            case .listCreated, .listsDeleted, .listUpdated:
                return
            // These, however, are not managed by us. Need to updated our view when they change.
            case .itemCreated, .itemsDeleted, .itemUpdated:
                self?.fetchAndDisplayLists()
            }
        }
        
        // Load lists.
        self.fetchAndDisplayLists()
    }
    
    func userTappedAddButton() {
        self.outputs.showNewListCreationModal?(())
    }
    
    func userFinishedEditingNewList(name: String) {
        database.createNewList(name: name)
            .handle(using: self.handleDatabaseError(_:)) { newList in
            // Put newList at the top, since it was just modified.
                self.lists.insert(newList, at: 0)
                self.outputs.insertListAtIndex?((display(from: newList), 0))
            }
    }
    
    func userFinishedEditingExistingList(at index: Int, newName: String) {
        database.updateList(withID: self.lists[index].id, newName: newName, dateLastModified: Date())
            .handle(using: self.handleDatabaseError(_:)) { updatedList in
            // Put updatedList at the top, since it was just modified.
                self.lists.remove(at: index)
                self.lists.insert(updatedList, at: 0)
            }
    }
    
    func userSelectedList(at index: Int) {
        self.showSingleListViewWithViewModel?(SingleListViewModel(list: lists[index], database: database))
    }
    
    func userAttemptedToDeleteList(at index: Int) {
        self.indexOfListStagedForDeletion = index
        self.outputs.showDeleteConfirmation?(
            ("Delete \(lists[index].name)", "Are you sure you want to delete your to-do list titled \(lists[index].name)?")
        )
    }
    
    func userAnsweredDeleteConfirmation(shouldDelete: Bool) {
        guard shouldDelete else { return }
        database.deleteLists(withIDs: [lists[indexOfListStagedForDeletion!].id])
            .handle(using: self.handleDatabaseError(_:)) {
                self.lists.remove(at: indexOfListStagedForDeletion!)
                outputs.removeListAtIndex?(indexOfListStagedForDeletion!)
            }
    }
    
    // MARK: - Private Functions
    
    /// Fetches lists from the database, and displays to the user.
    fileprivate func fetchAndDisplayLists() {
        database.getAllToDoLists()
            .handle(using: self.handleDatabaseError(_:)) { fetchedLists in
                self.lists = fetchedLists.sorted(by: self.descendingDateModifiedOrder)
                self.outputs.displayLists?(self.lists.map(self.display(from:)))
            }
    }
    
    /// Handles a provided `error`, displaying an alert to the user.
    private func handleDatabaseError(_ error: DatabaseError) {
        self.outputs.displayAlert?(UserAlert(
            style: .alert,
            title: "Internal Error",
            message: "Oops! Looks like we encountered an error in our internal database. Please try again.",
            options: [.ok(action: { dismiss in
                dismiss()
                self.fetchAndDisplayLists()
            })]
        ))
    }
    
    func display(from list: ToDoList) -> ToDoListDisplay {
        return (list.name, "(\(list.items.count) items)", "Updated \(dateModifiedFormatter.string(from: list.dateLastModified))")
    }
}
