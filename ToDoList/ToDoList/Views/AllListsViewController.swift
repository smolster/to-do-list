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
    
    private let viewModel: AllListsViewModelType = AllListsViewModel(database: CoreDataDatabase())
    
    init() {
        super.init(style: .grouped)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
