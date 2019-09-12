//
//  NibLoadable.swift
//  ToDoList
//
//  Created by Swain Molster on 9/10/19.
//  Copyright © 2019 Swain Molster. All rights reserved.
//

import UIKit

protocol NibLoadable {
    static var nibName: String { get }
    static var nibBundle: Bundle { get }
}

protocol Reusable {
    static var reuseIdentifier: String { get }
}

extension UITableView {
    func register<T>(nibLoadableType: T.Type) where T: UITableViewCell & NibLoadable & Reusable {
        self.register(UINib(nibName: T.nibName, bundle: T.nibBundle), forCellReuseIdentifier: T.reuseIdentifier)
    }
    
    func dequeueReusableCell<T>(ofType type: T.Type, for indexPath: IndexPath) -> T where T: UITableViewCell & Reusable {
        return dequeueReusableCell(withIdentifier: type.reuseIdentifier, for: indexPath) as! T
    }
}
