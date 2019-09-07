//
//  ViewModels.swift
//  ToDoList
//
//  Created by Swain Molster on 9/6/19.
//  Copyright © 2019 Swain Molster. All rights reserved.
//

import Foundation

struct ToDoItemViewModel {
    
    var text: String
    var dateCreated: String
    var dateCompleted: String?
    
    var isComplete: Bool { return dateCompleted != nil }
    
    fileprivate init(text: String, dateCreated: String, dateCompleted: String?) {
        self.text = text
        self.dateCreated = dateCreated
        self.dateCompleted = dateCompleted
    }
}

extension ToDoItem {
    func viewModel() -> ToDoItemViewModel {
        return .init(text: self.text, dateCreated: "\(self.dateCreated)", dateCompleted: nil)
    }
}
