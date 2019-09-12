//
//  ListTableViewCell.swift
//  ToDoList
//
//  Created by Swain Molster on 9/10/19.
//  Copyright © 2019 Swain Molster. All rights reserved.
//

import UIKit

/// Cell for displaying to-do list data.
final class ListTableViewCell: UITableViewCell {
    
    /// Enumerates the different configurations for the cell.
    enum Configuration {
        /// Regular display. User interaction with underlying elements deactivated.
        case display(ToDoListDisplay)
        
        /// Only name displayed, and text field enabled for editing.
        case editable(text: String)
        
        /// Only name displayed, and currently editing. passing to `ListTableViewCell.configure(as:)`
        /// sets the cell's text field as first responder. `callback` will be called after editing
        /// ends in the text field.
        case editing(currentText: String, callback: (_ newText: String) -> Void)
    }

    /// The cell's primary text field.
    @IBOutlet weak private var textField: UITextField! {
        didSet {
            self.textField.delegate = self
            self.textField.returnKeyType = .done
        }
    }
    
    /// A container view, for providing a "separated" look in the table view, despite table view constraints.
    @IBOutlet weak var containerView: UIView! {
        didSet {
            self.containerView.layer.cornerRadius = 5.0
        }
    }
    
    /// Right-side label, currently used for displaying number of items in the to-do list.
    @IBOutlet weak private var rightLabel: UILabel!
    
    /// Bottom-left label, currently used for displaying the last-updated date/time.
    @IBOutlet weak var bottomLeftLabel: UILabel!
    
    @IBOutlet weak var textFieldConstraintToBottomLabel: NSLayoutConstraint!
    @IBOutlet weak var textFieldConstraintToBottomContainerView: NSLayoutConstraint!
    
    /// Saved from the `Configuration.editing` case when it is passed.
    private var editingCallback: ((_ newText: String) -> Void)?
    
    private var shouldMarkForSelection: Bool = false

    /**
     Configures the cell with the provided option.
     
     - parameter configuration: The desired configuration.
     */
    func configure(as configuration: Configuration) {
        self.selectionStyle = .none
        switch configuration {
        case .editable(let text):
            self.shouldMarkForSelection = false
            self.rightLabel.text = nil
            self.bottomLeftLabel.text = nil
            self.bottomLeftLabel.isHidden = true
            self.textField.text = text
            self.textField.isUserInteractionEnabled = false // Set to false so any taps route through didSelect.
            self.textField.resignFirstResponder()
            self.textFieldConstraintToBottomLabel.isActive = false
            self.textFieldConstraintToBottomContainerView.isActive = true
            
        case .editing(let currentText, let callback):
            self.shouldMarkForSelection = false
            self.rightLabel.text = nil
            self.bottomLeftLabel.text = nil
            self.bottomLeftLabel.isHidden = true
            self.editingCallback = callback
            self.textField.text = currentText
            self.textField.isUserInteractionEnabled = true
            self.textField.becomeFirstResponder()
            
            self.textFieldConstraintToBottomLabel.isActive = false
            self.textFieldConstraintToBottomContainerView.isActive = true
            
        case .display(let list):
            self.shouldMarkForSelection = true
            self.textField.isUserInteractionEnabled = false
            self.textField.resignFirstResponder()
            self.textField.text = list.name
            self.rightLabel.text = list.itemCountString
            self.bottomLeftLabel.isHidden = false
            self.bottomLeftLabel.text = list.dateModifiedString
            self.textFieldConstraintToBottomLabel.isActive = true
            self.textFieldConstraintToBottomContainerView.isActive = false
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        if shouldMarkForSelection {
            self.containerView.backgroundColor = selected ? .groupTableViewBackground : .white
        }
    }
}

extension ListTableViewCell: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.handleEndEditing()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
        self.handleEndEditing()
    }
    
    private func handleEndEditing() {
        Logger.info("Editing changed")
        // In many cases, both of the above functions will be called.
        // So, we run this little song-and-dance to ensure that editingCallback is only called once.
        let callback = editingCallback
        editingCallback = nil // HAVE to set to `nil` BEFORE calling it, otherwise run into issues.
        callback?(self.textField.text ?? "")
        
        self.textField.resignFirstResponder()
    }
}

extension ListTableViewCell: Reusable, NibLoadable {
    static var reuseIdentifier: String { return "ListTableViewCell" }
    static var nibName: String { return "ListTableViewCell" }
    static var nibBundle: Bundle { return Bundle(for: self) }
}
