//
//  UIViewController+Extension.swift
//  ToDoList
//
//  Created by Swain Molster on 9/7/19.
//  Copyright © 2019 Swain Molster. All rights reserved.
//

import UIKit

extension UIViewController {
    /// Shared function for displaying a `UserAlert` struct in the form of a `UIAlertController`.
    internal var displayAlert: OutputFunction<UserAlert> {
        return { [weak self] alertInfo in
            guard let self = self else { return }
            dispatchToMainIfNeeded {
                let uiStyle: UIAlertController.Style
                switch alertInfo.style {
                case .alert: uiStyle = .alert
                case .actionSheet: uiStyle = .actionSheet
                }
                
                let alert = UIAlertController(title: alertInfo.title, message: alertInfo.message, preferredStyle: uiStyle)
                for option in alertInfo.options {
                    let actionStyle: UIAlertAction.Style
                    switch option {
                    case .ok: actionStyle = .default
                    case .cancel: actionStyle = .cancel
                    case .custom: actionStyle = .default
                    }
                    
                    alert.addAction(UIAlertAction(title: option.text, style: actionStyle, handler: { _ in
                        option.action? {
                            alert.dismiss(animated: true, completion: nil)
                        }
                    }))
                }
                
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
}
