//
//  SingleListViewModel.swift
//  ToDoList
//
//  Created by Swain Molster on 9/7/19.
//  Copyright © 2019 Swain Molster. All rights reserved.
//

import Foundation

protocol SingleListViewModelInputs {
    /// Call at end of viewDidLoad.
    func viewDidLoad()
    
    /// Call when the user creates a new item.
    func userCreatedItem(text: String)
    
    /// Call when the user finishes editing an item.
    func userEditedItem(withDateCreated: Date, newInfo: ToDoItem)
    
    /// Call when the user finishes editing an item.
    func userDeletedItem(withDateCreated: Date)
}

protocol SingleListViewModelOutputs {
    var displayItems: OutputFunction<[ToDoItem]>? { get set }
    var displayAlert: OutputFunction<UserAlertInfo>? { get set }
}

protocol SingleListViewModelType {
    var inputs: SingleListViewModelInputs { get }
    var outputs: SingleListViewModelOutputs { get }
}

final class SingleListViewModel: SingleListViewModelInputs, SingleListViewModelOutputs, SingleListViewModelType {
    
    var inputs: SingleListViewModelInputs { return self }
    var outputs: SingleListViewModelOutputs { return self }
    
    private var list: ToDoList
    
    init(list: ToDoList) {
        self.list = list
    }
    
    // MARK: Outputs
    var displayItems: OutputFunction<[ToDoItem]>?
    var displayAlert: OutputFunction<UserAlertInfo>?
    
    // MARK: Inputs
    
    func viewDidLoad() {
        self.outputs.displayItems?(self.list.items)
    }
    
    func userCreatedItem(text: String) {
        
    }
    
    func userEditedItem(withDateCreated: Date, newInfo: ToDoItem) {
        
    }
    
    func userDeletedItem(withDateCreated: Date) {
        
    }
}
