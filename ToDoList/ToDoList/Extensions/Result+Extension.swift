//
//  Result+Extension.swift
//  ToDoList
//
//  Created by Swain Molster on 9/11/19.
//  Copyright © 2019 Swain Molster. All rights reserved.
//

import Foundation

extension Result {
    func handle(using failureHandler: (Failure) -> Void, and successHandler: (Success) -> Void) {
        switch self {
        case .failure(let failure):
            failureHandler(failure)
        case .success(let success):
            successHandler(success)
        }
    }
}
