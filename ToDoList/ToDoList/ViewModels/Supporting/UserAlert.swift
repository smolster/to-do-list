//
//  UserAlert.swift
//  ToDoList
//
//  Created by Swain Molster on 9/7/19.
//  Copyright © 2019 Swain Molster. All rights reserved.
//

import Foundation

struct UserAlert {
    
    enum Style {
        case alert
        case actionSheet
    }
    
    enum Option {
        typealias Action = ((_ dismissAlert: () -> Void) -> Void)
        
        case cancel(action: Action?)
        case ok(action: Action?)
        case custom(text: String, destructive: Bool, action: Action?)
        
        var text: String {
            switch self {
            case .cancel: return "Cancel"
            case .ok: return "OK"
            case .custom(let text, _, _): return text
            }
        }
        
        var action: Action? {
            switch self {
            case .ok(let action), .cancel(let action), .custom(_, _, let action):
                return action
            }
        }
        
        var destructive: Bool {
            switch self {
            case .ok, .cancel: return false
            case .custom(_, let destructive, _): return destructive
            }
        }
    }
    
    var style: Style = .alert
    var title: String
    var message: String
    var options: [Option]
}
