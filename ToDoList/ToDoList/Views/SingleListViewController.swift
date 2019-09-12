//
//  SingleListViewController.swift
//  ToDoList
//
//  Created by Swain Molster on 9/6/19.
//  Copyright © 2019 Swain Molster. All rights reserved.
//

import UIKit

/// `UIViewController` subclass for displaying a single to-do list.
final class SingleListViewController: UITableViewController {
    
    /// Enumerates all of the possible "editing" states of this view.
    private enum ItemTextEditingState {
        /// Not editing anything.
        case notEditing
        /// Editing (creating) a new item.
        case editingNew(currentText: String)
        /// Editing an existing item.
        case editingExisting(index: Int, currentText: String)
    }
    
    // MARK: - Private Properites.
    
    /// Our view model!
    private let viewModel: SingleListViewModelType
    
    /// Backing data source for table view.
    private var items: [ToDoItemDisplay] = []
    
    /// The receiver's current editing state.
    private var itemTextEditingState: ItemTextEditingState = .notEditing
    
    init(viewModel: SingleListViewModelType) {
        self.viewModel = viewModel
        super.init(style: .grouped)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.register(nibLoadableType: ItemTableViewCell.self)
        
        // Create and set add button.
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addButtonWasTapped(_:)))
        
        // MARK: - Output Handlers
        
        self.title = self.viewModel.outputs.title
        
        self.viewModel.outputs.displayItems = { [weak self] items in
            guard let self = self else { return }
            dispatchToMainIfNeeded {
                self.items = items
                self.tableView.reloadData()
            }
        }
        
        self.viewModel.outputs.removeItemAtIndex = { [weak self] index in
            guard let self = self else { return }
            dispatchToMainIfNeeded {
                let indexPath = self.indexPathForItem(withIndex: index)
                self.items.remove(at: index)
                self.tableView.deleteRows(at: [indexPath], with: .automatic)
            }
        }
        
        self.viewModel.outputs.beginEditingNewItem = { [weak self] _ in
            guard let self = self else { return }
            dispatchToMainIfNeeded {
                self.itemTextEditingState = .editingNew(currentText: "")
                self.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
            }
        }
        
        self.viewModel.outputs.displayAlert = self.displayAlert
        
        self.viewModel.inputs.viewDidLoad()
    }
    
    // MARK: Selector Functions
    
    @objc func addButtonWasTapped(_ button: UIBarButtonItem) {
        self.viewModel.inputs.userTappedAddButton()
    }
    
    // MARK: Table View Functions

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch self.itemTextEditingState {
        case .notEditing, .editingExisting:
            return items.count
        case .editingNew:
            return items.count + 1 // Account for new item being edited at index 0.
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(ofType: ItemTableViewCell.self, for: indexPath)
        
        // Special case: loading the first cell, and using it to edit a new item.
        if indexPath.row == 0, case .editingNew(let text) = self.itemTextEditingState {
            // Yes, configure the cell for editing (with no toggle), and link the callback to the correct view model input.
            cell.configure(as: .editing(
                currentText: text,
                toggle: nil,
                textEditingEnded: { [weak self] newText in
                    guard let self = self else { return }
                    // Call view model input.
                    self.viewModel.inputs.userFinishedEditingNewItem(newText: newText)
                    
                    // Update backing model.
                    self.items.insert((newText, false), at: 0)
                    self.itemTextEditingState = .notEditing
                    
                    // Update the cell to standard display.
                    self.tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
                }
            ))
        
        // Now, more normal cases.
        } else {
            // First, we need to tune up our indexing in the case that we are editing a new item.
            let indexToMatch = indexForItem(displayedAtIndexPath: indexPath)
            
            // Are we editing an existing item at this index?
            if case .editingExisting(let editingIndex, let currentText) = self.itemTextEditingState, editingIndex == indexToMatch {
                // Yes, configure for editing, and link the callback to the correct view model input.
                cell.configure(as: .editing(
                    currentText: currentText,
                    toggle: (items[editingIndex].isComplete, self.toggleChangedHandler(forItemIndex: editingIndex)),
                    textEditingEnded: self.editingEndedForExistingItemHandler(forItemIndex: editingIndex)
                ))
            // We aren't editing, so just configure as standard item display, and link toggle callback to correct view model input.
            } else {
                cell.configure(as: .display(
                    item: self.items[indexToMatch],
                    toggleChanged: self.toggleChangedHandler(forItemIndex: indexToMatch)
                ))
            }
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // First row is not selectable while being used to create a new item.
        if case .editingNew = self.itemTextEditingState, indexPath.row == 0 {
            return
        }
        
        // Configuring directly here, rather than just changing the .itemTextEditingState and reloading,
        // works better in the UI experience.
        guard let cell = self.tableView.cellForRow(at: indexPath) as? ItemTableViewCell else {
            return
        }
        let itemIndex = indexForItem(displayedAtIndexPath: indexPath)
        
        cell.configure(as: .editing(
            currentText: items[itemIndex].text,
            toggle: (items[itemIndex].isComplete, self.toggleChangedHandler(forItemIndex: itemIndex)),
            textEditingEnded: self.editingEndedForExistingItemHandler(forItemIndex: itemIndex)
        ))
        
        // Update backing model.
        self.itemTextEditingState = .editingExisting(index: itemIndex, currentText: items[itemIndex].text)
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // No editing the first row while it's being used to create a new item.
        if case .editingNew = self.itemTextEditingState, indexPath.row == 0 {
            return false
        }
        // Everything else is cool.
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            self.viewModel.inputs.userDeletedItem(at: indexForItem(displayedAtIndexPath: indexPath))
        }
    }
    
    // MARK: - Private Functions
    
    /// Note: We use the two functions below to help offset our indexing during the time when
    /// we're editing a new item (which occupies the zero-index cell & index path).
    
    /// Returns the data source index for the item currently displayed at the provided `indexPath`
    private func indexForItem(displayedAtIndexPath indexPath: IndexPath) -> Int {
        if case .editingNew = self.itemTextEditingState {
            // We ARE editing a new item, but we're loading a regular cell further down. So, we need to match for indexPath.row-1.
            return indexPath.row - 1
        } else {
            return indexPath.row
        }
    }
    
    /// Returns the `IndexPath` of the cell displaying the item at the provided data source `index`.
    private func indexPathForItem(withIndex index: Int) -> IndexPath {
        if case .editingNew = self.itemTextEditingState {
            return .init(row: index + 1, section: 0)
        } else {
            return .init(row: index, section: 0)
        }
    }
    
    /**
     Returns a closure that will appropriately route text field output to the view model, linking to the item at the provided data source `itemIndex`.
     
     - parameter itemIndex: The data source index to link the text field editing to.
     
     - returns: A closure for handling the text field output.
     */
    private func editingEndedForExistingItemHandler(forItemIndex itemIndex: Int) -> (String) -> Void {
        return { [weak self] newText in
            guard let self = self else { return }
            
            self.viewModel.inputs.userFinishedEditingExistingItem(at: itemIndex, newText: newText)
            self.items[itemIndex].text = newText
            
            let indexPath = self.indexPathForItem(withIndex: itemIndex)
            guard let cell = self.tableView.cellForRow(at: indexPath) as? ItemTableViewCell else { return }
            cell.configure(as: .display(item: self.items[itemIndex], toggleChanged: self.toggleChangedHandler(forItemIndex: itemIndex)))
        }
    }
    
    /**
     Returns a closure that will appropriately route toggle output to the view model, linking to the item at the provided data source `itemIndex`.
     
     - parameter: itemIndex: The data source index to link the toggle output to.
     
     - returns: A closure for handling the text field output.
     */
    private func toggleChangedHandler(forItemIndex itemIndex: Int) -> (Bool) -> Void {
        return { [weak self] newValue in
            guard let self = self else { return }
            self.viewModel.inputs.userChangedCompleteStateOfItem(at: itemIndex, to: newValue)
            self.items[itemIndex].isComplete = newValue
        }
    }
    
}

