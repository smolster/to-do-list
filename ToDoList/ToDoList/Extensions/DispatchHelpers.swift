//
//  DispatchHelpers.swift
//  ToDoList
//
//  Created by Swain Molster on 9/11/19.
//  Copyright © 2019 Swain Molster. All rights reserved.
//

import Foundation

func dispatchToMainIfNeeded(_ execute: @escaping () -> Void) {
    if Thread.current.isMainThread {
        execute()
    } else {
        DispatchQueue.main.async(execute: execute)
    }
}
