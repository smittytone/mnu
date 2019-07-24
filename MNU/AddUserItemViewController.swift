
//  MNUaddUserItemViewController.swift
//  MNU
//
//  Created by Tony Smith on 22/07/2019.
//  Copyright © 2019 Tony Smith. All rights reserved.


import Cocoa

class AddUserItemViewController: NSViewController, NSTextFieldDelegate {

    // MARK: - UI Outlets

    @IBOutlet weak var addItemSheet: NSWindow!
    @IBOutlet weak var itemScriptText: NSTextField!
    @IBOutlet weak var menuTitleText: NSTextField!
    @IBOutlet weak var textCount: NSTextField!
    @IBOutlet weak var titleText: NSTextField!
    @IBOutlet weak var saveButton: NSButton!


    // MARK: - Class Properties

    var hasChanged: Bool = false
    var newMNUitem: MNUitem? = nil
    var parentWindow: NSWindow? = nil
    var isEditing: Bool = false

    
    // MARK: - Lifecycle Functions

    override func viewDidLoad() {

        super.viewDidLoad()

        // Set the name length indicator
        self.textCount.stringValue = "\(menuTitleText.stringValue.count)/\(MNU_CONSTANTS.MENU_TEXT_LEN)"
    }


    func showSheet() {

        if !self.isEditing {
            // Clear the new user item sheet's input fields first
            self.itemScriptText.stringValue = ""
            self.menuTitleText.stringValue = ""
            self.saveButton.title = "Add"
            self.titleText.stringValue = "Add A New Terminal Command"
        } else {
            // Populate the fields from the MNUitem property
            if let item: MNUitem = self.newMNUitem {
                self.itemScriptText.stringValue = item.script
                self.menuTitleText.stringValue = item.title
                self.titleText.stringValue = "Edit This Terminal Command"
                self.saveButton.title = "Update"
            } else {
                NSLog("Could not access the supplied MNUitem")
                return
            }
        }

        // Present the sheet
        if let window = self.parentWindow {
            window.beginSheet(self.addItemSheet,
                              completionHandler: nil)
        }
    }


    // MARK: - Action Functions

    @IBAction @objc func doCancel(sender: Any?) {

        // Just close the sheet
        self.parentWindow!.endSheet(addItemSheet)
    }


    @IBAction @objc func doSave(sender: Any?) {

        var hasChanged: Bool = false

        if !self.isEditing {
            // Create a MNUuserItem
            let newItem = MNUitem()
            newItem.script = self.itemScriptText.stringValue
            newItem.title = self.menuTitleText.stringValue
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
            hasChanged = true
        } else {
            // Save the updated fields
            if let item = self.newMNUitem {
                if item.title != self.menuTitleText.stringValue {
                    hasChanged = true
                    item.title = self.menuTitleText.stringValue
                }

                if item.script != self.itemScriptText.stringValue {
                    hasChanged = true
                    item.script = self.itemScriptText.stringValue
                }
            }
        }
        
        if hasChanged {
            // Inform the configure window controller that there's a new item to list
            let nc = NotificationCenter.default
            nc.post(name: NSNotification.Name(rawValue: "com.bps.mnu.item-added"),
                    object: self)
        }

        // Close the sheet
        self.parentWindow!.endSheet(addItemSheet)
    }


    // MARK: - NSTextFieldDelegate Functions

    func controlTextDidChange(_ obj: Notification) {

        // We use this to trap text entry into the 'itemText' field and limit it to x characters
        // where x is set by 'MNU_CONSTANTS.MENU_TEXT_LEN'
        let sender: NSTextField = obj.object as! NSTextField

        if sender == menuTitleText {
            if menuTitleText.stringValue.count > MNU_CONSTANTS.MENU_TEXT_LEN {
                // The field contains more than 'MNU_CONSTANTS.MENU_TEXT_LEN' characters, so only
                // keep that number of characters in the field
                self.menuTitleText.stringValue = String(menuTitleText.stringValue.prefix(MNU_CONSTANTS.MENU_TEXT_LEN))
                NSSound.beep()
            }

            // Whenever a character is entered, update the character count
            self.textCount.stringValue = "\(self.menuTitleText.stringValue.count)/\(MNU_CONSTANTS.MENU_TEXT_LEN)"
            return;
        }
    }

}
