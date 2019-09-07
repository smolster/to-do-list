//
//  AllListsViewModel.swift
//  ToDoList
//
//  Created by Swain Molster on 9/6/19.
//  Copyright © 2019 Swain Molster. All rights reserved.
//

import Foundation

protocol AllListsViewModelInputs {
    /// Call at end of viewDidLoad.
    func viewDidLoad()
    
    /// Call when then user taps a list.
    func userTappedList(named name: String)
    
    /// Call when user attempts to delete list.
    func userDeletedList(named name: ToDoList)
}

protocol AllListsViewModelOutputs {
    var displayLists: OutputFunction<ToDoList>? { get set }
    var displayAlert: OutputFunction<UserAlertInfo>? { get set }
    var showSingleListViewWithList: OutputFunction<ToDoList>? { get set }
}

protocol AllListsViewModelType {
    var inputs: AllListsViewModelInputs { get }
    var outputs: AllListsViewModelOutputs { get }
}

final class AllListsViewModel: AllListsViewModelInputs, AllListsViewModelOutputs, AllListsViewModelType {

    var inputs: AllListsViewModelInputs { return self }
    var outputs: AllListsViewModelOutputs { return self }
    
    private let database: Database
    
    
    init(database: Database) {
        self.database = database
    }
    
    // MARK: Outputs
    
    var displayLists: OutputFunction<ToDoList>?
    var displayAlert: OutputFunction<UserAlertInfo>?
    var showSingleListViewWithList: OutputFunction<ToDoList>?
    
    // MARK: Inputs
    
    func viewDidLoad() {
        
    }
    
    func userTappedList(named name: String) {
        self.outputs.showSingleListViewWithList?(<#T##ToDoList#>)
    }
    
    func userDeletedList(named name: ToDoList) {
        
    }
}
