
/*
    AddUserItemViewController.swift
    MNU

    Created by Tony Smith on 24/07/2019.
    Copyright © 2019 Tony Smith. All rights reserved.

    MIT License
    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
 */


import Cocoa


class AddUserItemViewController: NSViewController,
                                 NSTextFieldDelegate {

    // MARK: - UI Outlets

    @IBOutlet weak var addItemSheet: NSWindow!
    @IBOutlet weak var itemScriptText: NSTextField!
    @IBOutlet weak var menuTitleText: NSTextField!
    @IBOutlet weak var textCount: NSTextField!
    @IBOutlet weak var titleText: NSTextField!
    @IBOutlet weak var saveButton: NSButton!


    // MARK: - Class Properties

    var newMenuItem: MenuItem? = nil
    var currentMenuItems: MenuItemList? = nil
    var parentWindow: NSWindow? = nil
    var isEditing: Bool = false

    
    // MARK: - Lifecycle Functions

    override func viewDidLoad() {

        super.viewDidLoad()

        // Set the name length indicator
        self.textCount.stringValue = "\(menuTitleText.stringValue.count)/\(MNU_CONSTANTS.MENU_TEXT_LEN)"
    }


    func showSheet() {

        // Present the controller's sheet, customising it to either display an existing
        // Menu Item's details for editing, or empty fields for a new Menu Item

        if !self.isEditing {
            // Clear the new user item sheet's input fields first
            self.itemScriptText.stringValue = ""
            self.menuTitleText.stringValue = ""
            self.saveButton.title = "Add"
            self.titleText.stringValue = "Add A New Terminal Command"
        } else {
            if let item: MenuItem = self.newMenuItem {
                // Populate the fields from the MenuItem property
                self.itemScriptText.stringValue = item.script
                self.menuTitleText.stringValue = item.title
                self.saveButton.title = "Update"
                self.titleText.stringValue = "Edit This Terminal Command"
            } else {
                NSLog("Could not access the supplied MenuItem")
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

        // User has clicked 'Cancel', so just close the sheet

        self.parentWindow!.endSheet(addItemSheet)
    }


    @IBAction @objc func doSave(sender: Any?) {

        // Save a new script item, or update an existing one (if we are editing)

        var itemHasChanged: Bool = false

        // Check that we have valid field entries
        if self.itemScriptText.stringValue.count == 0 {
            // The field is blank, so warn the user
            showAlert("Missing Terminal Command", "You must enter a Terminal command. If you don’t want to set one at this time, click OK then Cancel")
            return
        }

        if self.menuTitleText.stringValue.count == 0 {
            // The field is blank, so warn the user
            showAlert("Missing Menu Label", "You must enter a label for the command’s menu entry. If you don’t want to set one at this time, click OK then Cancel")
            return
        }

        if !self.isEditing {
            // Check that we have a unique menu label
            if let list: MenuItemList = self.currentMenuItems {
                if list.items.count > 0 {
                    var got: Bool = false
                    for item: MenuItem in list.items {
                        if item.title == self.menuTitleText.stringValue {
                            got = true
                            break
                        }
                    }

                    if got {
                        // The label is in use, so warn the user and exit the save
                        showAlert("Menu Label Already In Use", "You must enter a unique label for the command’s menu entry. If you don’t want to set one at this time, click OK then Cancel")
                        return
                    }
                }
            }

            // Create a Menu Item and set its values
            let newItem = MenuItem()
            newItem.script = self.itemScriptText.stringValue
            newItem.title = self.menuTitleText.stringValue
            newItem.type = MNU_CONSTANTS.TYPES.SCRIPT
            newItem.code = MNU_CONSTANTS.ITEMS.SCRIPT.USER
            newItem.isNew = true

            // Add a view controller and set its view properties
            let controller: ScriptItemViewController = ScriptItemViewController.init(nibName: nil, bundle: nil)
            controller.text = newItem.title
            controller.state = true
            controller.onImageName = "logo_generic"
            controller.offImageName = "logo_generic"

            // Assign the controller to the new menu item
            newItem.controller = controller

            // Store the new menu item
            self.newMenuItem = newItem
            itemHasChanged = true
        } else {
            // Save the updated fields
            if let item = self.newMenuItem {
                if item.title != self.menuTitleText.stringValue {
                    itemHasChanged = true
                    item.title = self.menuTitleText.stringValue
                }

                if item.script != self.itemScriptText.stringValue {
                    itemHasChanged = true
                    item.script = self.itemScriptText.stringValue
                }
            }
        }
        
        if itemHasChanged {
            // Inform the configure window controller that there's a new item to list
            // NOTE The called code handles edited items too - it's not just for new items
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "com.bps.mnu.item-added"),
                                            object: self)
        }

        // Close the sheet
        self.parentWindow!.endSheet(addItemSheet)
    }


    @IBAction @objc func doShowHelp(sender: Any?) {

        // Show the 'Help' via the website
        // TODO create web page
        // TODO provide offline help
        NSWorkspace.shared.open(URL.init(string:"https://smittytone.github.io/mnu/index.html#add-edit")!)
    }


    // MARK: - Helper Functions

    func showAlert(_ title: String, _ message: String) {

        // Present an alert to warn the user about deleting the Menu Item
        let alert: NSAlert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.beginSheetModal(for: self.addItemSheet,
                              completionHandler: nil)
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
