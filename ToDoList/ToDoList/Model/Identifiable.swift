//
//  Identifiable.swift
//  ToDoList
//
//  Created by Swain Molster on 9/7/19.
//  Copyright © 2019 Swain Molster. All rights reserved.
//

import Foundation

protocol Identifiable {
    associatedtype ID: Equatable
    var id: ID { get }
}

extension Identifiable {
    func hasSameID(as other: Self) -> Bool {
        return self.id == other.id
    }
}
