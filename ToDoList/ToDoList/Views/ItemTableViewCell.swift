//
//  ItemTableViewCell.swift
//  ToDoList
//
//  Created by Swain Molster on 9/10/19.
//  Copyright © 2019 Swain Molster. All rights reserved.
//

import UIKit

// TODO: Change didReturn to just resignFirstResponder?

class ItemTableViewCell: UITableViewCell {
    
    /// Enumerates the different configurations for the cell.
    enum Configuration {
        /// Currently editing. Toggle hidden if `toggle` is `nil`. `textEditingEnded` called
        /// when editing ends in the text field. `toggle.callback` called when the toggle value changes.
        case editing(currentText: String, toggle: (isComplete: Bool, callback: (_ isOn: Bool) -> Void)?, textEditingEnded: (_ newText: String) -> Void)
        
        /// Standard display state. Callback called when toggle value changes.
        case display(item: ToDoItemDisplay, toggleChanged: (_ isOn: Bool) -> Void)
    }
    
    /// Primary text field.
    @IBOutlet weak private var textField: UITextField! {
        didSet {
            self.textField.delegate = self
        }
    }
    
    /// Toggle used for marking the item as complete.
    @IBOutlet weak private var toggle: UISwitch! {
        didSet {
            self.toggle.addTarget(self, action: #selector(toggleChanged(_:)), for: .valueChanged)
        }
    }
    
    /// Closure saved from `Configuration.editing` when it is passed to `configure(as:)`.
    private var editingCallback: ((_ newText: String) -> Void)?
    
    /// Closure saved from `Configuration` when it is passed to `configure(as:)`.
    private var toggleCallback: ((_ isOn: Bool) -> Void)?
    
    /**
     Configures the cell to display a provided `configuration`.
     
     - parameter configuration: The desired configuration.
     */
    func configure(as configuration: Configuration) {
        self.selectionStyle = .none
        self.textField.returnKeyType = .done
        switch configuration {
        case .editing(let currentText, let toggle, let textEditingEndedCallback):
            self.textField.text = currentText
            self.textField.isUserInteractionEnabled = true
            // TODO: Move this out.
            self.textField.placeholder = "e.g. Send email..."
            
            if let toggle = toggle {
                self.toggle.isOn = toggle.isComplete
                self.toggleCallback = toggle.callback
            } else {
                self.toggle.isHidden = true
                self.toggleCallback = nil
            }
            
            self.editingCallback = textEditingEndedCallback
            
            if !self.textField.isFirstResponder {
                self.textField.becomeFirstResponder()
            }
        case .display(let item, let toggleCallback):
            self.textField.text = item.text
            self.textField.isUserInteractionEnabled = false // We disable this so that every access comes through the didSelect call.
            self.toggle.isOn = item.isComplete
            self.toggle.isHidden = false
            self.toggleCallback = toggleCallback
        }
    }
    
    /// Selector method linked to the toggle.
    @objc private func toggleChanged(_ toggle: UISwitch) {
        self.toggleCallback?(toggle.isOn)
    }
}

extension ItemTableViewCell: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.handleEndEditing()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
        self.handleEndEditing()
    }
    
    private func handleEndEditing() {
        // In many cases, both of the above functions will be called.
        // So, we run this little song-and-dance to ensure that editingCallback is only called once.
        let callback = editingCallback
        editingCallback = nil // HAVE to set to `nil` BEFORE calling it, otherwise run into issues.
        callback?(self.textField.text ?? "")
        
        self.textField.resignFirstResponder()
    }
}

extension ItemTableViewCell: Reusable, NibLoadable {
    static var reuseIdentifier: String { return "ItemTableViewCell" }
    static var nibName: String { return "ItemTableViewCell" }
    static var nibBundle: Bundle { return Bundle(for: self) }
}
