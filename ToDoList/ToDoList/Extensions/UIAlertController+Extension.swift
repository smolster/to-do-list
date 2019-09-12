//
//  UIAlertController+Extension.swift
//  ToDoList
//
//  Created by Swain Molster on 9/11/19.
//  Copyright © 2019 Swain Molster. All rights reserved.
//

import UIKit

extension UIAlertController {
    /// Returns a `UIAlertController` for gathering text from the user.
    static func textGatherer(
        title: String?,
        message: String?,
        placeholder: String? = nil,
        allowEmpty: Bool,
        okAction: @escaping (_ finalString: String) -> Void,
        cancelAction: @escaping () -> Void
    ) -> UIAlertController {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

        alertController.addTextField { textField in
            textField.placeholder = placeholder
            textField.addTarget(alertController, action: #selector(validateNotEmpty(in:)), for: .editingChanged)
        }
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in cancelAction() }))
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            okAction(alertController.textFields![0].text ?? "")
        }))
        alertController.actions[1].isEnabled = false
        return alertController
    }
    
    @objc private func validateNotEmpty(in textField: UITextField) {
        self.actions[1].isEnabled = textField.text != nil && textField.text?.isEmpty == false
    }
}
