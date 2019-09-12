//
//  AllListsViewController.swift
//  ToDoList
//
//  Created by Swain Molster on 9/7/19.
//  Copyright © 2019 Swain Molster. All rights reserved.
//

import Foundation
import UIKit

final class AllListsViewController: UITableViewController {
    
    /// The two high-level modes of this view.
    private enum Mode {
        /// Allowing editing of the the list names, and deletion. If we are
        /// currently editing an item, its information is provided.
        case editing(item: (index: Int, text: String)?)
        /// Not editing.
        case notEditing
    }
    
    /// Our view model.
    private let viewModel: AllListsViewModelType
    
    /// Backing data source for the table view.
    private var lists: [ToDoListDisplay] = []
    
    /// Index and current text of item currently being edited. `nil` if we aren't editing.
    private var currentlyEditing: (index: Int, text: String)?
    
    /// Current mode.
    private var mode: Mode = .notEditing
    
    init(viewModel: AllListsViewModelType) {
        self.viewModel = viewModel
        super.init(style: .grouped)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // High-level screen configuration.
        
        self.navigationController?.navigationBar.prefersLargeTitles = true
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addButtonTapped(_:)))
        self.navigationItem.rightBarButtonItem = self.editButton()
        
        self.tableView.register(nibLoadableType: ListTableViewCell.self)
        self.tableView.separatorStyle = .none
        
        // MARK: - Output Handlers
        
        self.title = viewModel.outputs.title
        
        self.viewModel.outputs.displayLists = { [weak self] lists in
            guard let self = self else { return }
            dispatchToMainIfNeeded {
                self.lists = lists
                self.tableView.reloadData()
            }
        }
        
        self.viewModel.outputs.insertListAtIndex = { [weak self] listAndIndex in
            guard let self = self else { return }
            dispatchToMainIfNeeded {
                self.lists.insert(listAndIndex.list, at: listAndIndex.index)
                self.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
            }
        }
        
        self.viewModel.outputs.removeListAtIndex = { [weak self] index in
            guard let self = self else { return }
            dispatchToMainIfNeeded {
                self.lists.remove(at: index)
                self.tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
            }
        }
        
        self.viewModel.outputs.showNewListCreationModal = { [weak self] _ in
            guard let self = self else { return }
            dispatchToMainIfNeeded {
                let alert = UIAlertController.textGatherer(
                    title: "New To-Do List",
                    message: "What would you like to call your new to-do list?",
                    placeholder: "e.g. Work Stuff",
                    allowEmpty: false,
                    okAction: { [weak self] newText in
                        self?.viewModel.inputs.userFinishedEditingNewList(name: newText)
                    },
                    cancelAction: { }
                )
                self.present(alert, animated: true, completion: nil)
            }
            
        }
        
        self.viewModel.outputs.showDeleteConfirmation = { [weak self] alertInfo in
            self?.displayAlert(UserAlert(
                style: .alert,
                title: alertInfo.title,
                message: alertInfo.message,
                options: [
                    .cancel(action: { _ in
                        self?.viewModel.inputs.userAnsweredDeleteConfirmation(shouldDelete: false)
                    }),
                    .custom(text: "Delete", destructive: true, action: { [weak self] _ in
                        self?.viewModel.inputs.userAnsweredDeleteConfirmation(shouldDelete: true)
                    })
                ]
            ))
        }
        
        self.viewModel.outputs.showSingleListViewWithViewModel = { [weak self] viewModel in
            guard let self = self else { return }
            dispatchToMainIfNeeded {
                let singleListVC = SingleListViewController(viewModel: viewModel)
                self.navigationController?.pushViewController(singleListVC, animated: true)
            }
        }
        
        self.viewModel.outputs.displayAlert = self.displayAlert

        self.viewModel.inputs.viewDidLoad()
    }
    
    // MARK: - Selector Methods
    
    @objc private func addButtonTapped(_ button: UIBarButtonItem) {
        self.viewModel.inputs.userTappedAddButton()
    }
    
    @objc private func editOrDoneButtonTapped(_ button: UIBarButtonItem) {
        self.toggleMode()
    }
    
    // MARK: - Table View Functions
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return lists.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(ofType: ListTableViewCell.self, for: indexPath)
        
        if case .editing(let item) = self.mode {
            // Check if we are currently editing at this index.
            if let item = item, indexPath.row == item.index {
                cell.configure(as: .editing(
                    currentText: item.text,
                    callback: editingEndedHandler(forItemAtIndex: indexPath.row)
                ))
            } else {
                cell.configure(as: .editable(text: lists[indexPath.row].name))
            }
        } else {
            cell.configure(as: .display(lists[indexPath.row]))
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if case .editing = self.mode {
            let cell = tableView.cellForRow(at: indexPath) as? ListTableViewCell
            cell?.configure(as: .editing(
                currentText: self.lists[indexPath.row].name,
                callback: editingEndedHandler(forItemAtIndex: indexPath.row)
            ))
            self.mode = .editing(item: (indexPath.row, self.lists[indexPath.row].name))
        } else {
            self.viewModel.inputs.userSelectedList(at: indexPath.row)
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if case .editing = self.mode {
            return true
        } else {
            return false
        }
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            self.viewModel.inputs.userAttemptedToDeleteList(at: indexPath.row)
        }
    }
    
    // MARK: - Private Functions
    
    /// Toggles the current mode , applying updates to visible cells.
    private func toggleMode() {
        if let selectedIndexPath = tableView.indexPathForSelectedRow {
            self.tableView.deselectRow(at: selectedIndexPath, animated: true)
        }
        
        switch self.mode {
        case .editing:
            self.mode = .notEditing
            
            // Set bar button.
            self.navigationItem.rightBarButtonItem = self.editButton()
            
            // Update all visible cells to `display`.
            self.tableView.indexPathsForVisibleRows?.forEach {
                (self.tableView.cellForRow(at: $0) as! ListTableViewCell).configure(as: .display(self.lists[$0.row]))
            }
            self.tableView.beginUpdates()
            self.tableView.endUpdates()
        case .notEditing:
            self.mode = .editing(item: nil)
            
            // Set bar button.
            self.navigationItem.rightBarButtonItem = self.doneButton()
            
            // Update all visible cells to `editable`.
            self.tableView.indexPathsForVisibleRows?.forEach {
                (self.tableView.cellForRow(at: $0) as! ListTableViewCell).configure(as: .editable(text: self.lists[$0.row].name))
            }
            self.tableView.beginUpdates()
            self.tableView.endUpdates()
        }
        
        
    }
    
    /// Returns a new system "Done" button, targeted at `editOrDoneButtonTapped(_:)`.
    private func doneButton() -> UIBarButtonItem {
        return UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(editOrDoneButtonTapped(_:)))
    }
    
    /// Returns a new system "Edit" button, taregt at `editOrDoneButtonTapped(_:)`.
    private func editButton() -> UIBarButtonItem {
        return UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(editOrDoneButtonTapped(_:)))
    }
    
    /**
     Returns a closure that appropriately routes text field changes to the view model for a provided data source index.
     
     - parameter index: The associated data source index.
     */
    func editingEndedHandler(forItemAtIndex index: Int) -> (String) -> Void {
        return { [weak self] newText in
            self?.lists[index].name = newText
            self?.viewModel.inputs.userFinishedEditingExistingList(at: index, newName: newText)
        }
    }
    
}
