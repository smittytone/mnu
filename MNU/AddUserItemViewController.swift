
//  MNUaddUserItemViewController.swift
//  MNU
//
//  Created by Tony Smith on 22/07/2019.
//  Copyright © 2019 Tony Smith. All rights reserved.


import Cocoa

class AddUserItemViewController: NSViewController, NSTextFieldDelegate {

    // MARK: - UI Outlets

    @IBOutlet weak var itemExec: NSTextField!
    @IBOutlet weak var itemText: NSTextField!
    @IBOutlet weak var textCount: NSTextField!


    // MARK: - Class Properties

    var hasChanged: Bool = false
    var newMNUitem: MNUitem? = nil

    
    // MARK: - Lifecycle Functions

    override func viewDidLoad() {

        super.viewDidLoad()

        // Set the name length indicator
        self.textCount.stringValue = "\(itemText.stringValue.count)/\(MNU_CONSTANTS.MENU_TEXT_LEN)"
    }


    // MARK: - Action Functions

    @IBAction @objc func doCancel(sender: Any?) {

        // Just close the window
        self.view.window!.close()
    }


    @IBAction @objc func doSave(sender: Any?) {

        // Create a MNUuserItem
        let newItem = MNUitem()
        newItem.script = itemExec.stringValue
        newItem.title = itemText.stringValue
        newItem.type = MNU_CONSTANTS.TYPES.SCRIPT
        newItem.code = MNU_CONSTANTS.ITEMS.SCRIPT.USER
        newItem.isNew = true

        // Add a view controller and set its view properties
        let controller: ScriptItemViewController = ScriptItemViewController.init(nibName: nil, bundle: nil)
        controller.text = newItem.title
        controller.state = true
        controller.onImageName = "dark_mode_icon"
        controller.offImageName = "dark_mode_icon"

        // Assign the controller to the new menu item
        newItem.controller = controller

        // Store the new menu item
        self.newMNUitem = newItem

        // Inform the configure window controller that there's a new item to list
        let nc = NotificationCenter.default
        nc.post(name: NSNotification.Name(rawValue: "com.bps.mnu.item-added"),
                object: self)

        // Close the Window
        self.view.window!.close()
    }


    // MARK: - NSTextFieldDelegate Functions

    func controlTextDidChange(_ obj: Notification) {

        // We use this to trap text entry into the 'itemText' field and limit it to x characters
        // where x is set by 'MNU_CONSTANTS.MENU_TEXT_LEN'
        let sender: NSTextField = obj.object as! NSTextField

        if sender == itemText {
            if itemText.stringValue.count > MNU_CONSTANTS.MENU_TEXT_LEN {
                // The field contains more than 'MNU_CONSTANTS.MENU_TEXT_LEN' characters, so only
                // keep that number of characters in the field
                self.itemText.stringValue = String(itemText.stringValue.prefix(MNU_CONSTANTS.MENU_TEXT_LEN))
                NSSound.beep()
            }

            // Whenever a character is entered, update the character count
            self.textCount.stringValue = "\(self.itemText.stringValue.count)/\(MNU_CONSTANTS.MENU_TEXT_LEN)"
            return;
        }
    }

}
