
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
                                 NSTextFieldDelegate,
                                 NSPopoverDelegate {

    // MARK: - UI Outlets

    @IBOutlet var addItemSheet: NSWindow!
    @IBOutlet var itemScriptText: NSTextField!
    @IBOutlet var menuTitleText: NSTextField!
    @IBOutlet var textCount: NSTextField!
    @IBOutlet var titleText: NSTextField!
    @IBOutlet var saveButton: NSButton!
    @IBOutlet var iconButton: AddUserItemIconButton!
    @IBOutlet var iconPopoverController: AddUserItemPopoverController!


    // MARK: - Class Properties

    var newMenuItem: MenuItem? = nil
    var currentMenuItems: MenuItemList? = nil
    var parentWindow: NSWindow? = nil
    var isEditing: Bool = false
    var iconPopover: NSPopover? = nil
    var icons: NSMutableArray = NSMutableArray.init()


    // MARK: - Lifecycle Functions

    override func viewDidLoad() {

        super.viewDidLoad()

        // Set the name length indicator
        self.textCount.stringValue = "\(menuTitleText.stringValue.count)/\(MNU_CONSTANTS.MENU_TEXT_LEN)"

        // Set up the custom script icons - these will be accessed by other objects, including
        // 'iconButton' and 'iconPopoverController'
        makeIconMatrix()

        // Configure the AddUserItemsIconController
        self.iconPopoverController.button = self.iconButton
        self.iconPopoverController.icons = self.icons

        // Set up and confiure the NSPopover
        makePopover()

        // Set up notifications
        // 'com.bps.mnu.select-image' is sent by the AddUserItemViewController when an icon is selected
        let nc = NotificationCenter.default
        nc.addObserver(self,
                       selector: #selector(updateButtonIcon(_:)),
                       name: NSNotification.Name(rawValue: "com.bps.mnu.select-image"),
                       object: nil)
    }


    func makeIconMatrix() {

        // Build the array of icons that we will use for the popover selector and the button
        // that triggers its appearance
        // NOTE There should be 16 icons in total in this release

        var image: NSImage? = NSImage.init(named: "picon_generic")
        self.icons.add(image!)
        image = NSImage.init(named: "picon_bash")
        self.icons.add(image!)
        image = NSImage.init(named: "picon_brew")
        self.icons.add(image!)
        image = NSImage.init(named: "picon_github")
        self.icons.add(image!)
        image = NSImage.init(named: "picon_python")
        self.icons.add(image!)
        image = NSImage.init(named: "picon_node")
        self.icons.add(image!)
        image = NSImage.init(named: "picon_rust")
        self.icons.add(image!)
        image = NSImage.init(named: "picon_perl")
        self.icons.add(image!)
        image = NSImage.init(named: "picon_as")
        self.icons.add(image!)
        image = NSImage.init(named: "picon_coffee")
        self.icons.add(image!)
        image = NSImage.init(named: "picon_doc")
        self.icons.add(image!)
        image = NSImage.init(named: "picon_dir")
        self.icons.add(image!)
        image = NSImage.init(named: "picon_pic")
        self.icons.add(image!)
        image = NSImage.init(named: "picon_cog")
        self.icons.add(image!)

    }


    func makePopover() {

        // Assemble the popover if it hasn't been assembled yet
        if self.iconPopover == nil {
            self.iconPopover = NSPopover.init()
            self.iconPopover!.contentViewController = self.iconPopoverController
            self.iconPopover!.delegate = self
            self.iconPopover!.behavior = NSPopover.Behavior.transient
        }
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
            self.iconButton.image = self.icons.object(at: 0) as? NSImage
            self.iconButton.index = 0
        } else {
            if let item: MenuItem = self.newMenuItem {
                // Populate the fields from the MenuItem property
                self.itemScriptText.stringValue = item.script
                self.menuTitleText.stringValue = item.title
                self.saveButton.title = "Update"
                self.titleText.stringValue = "Edit This Terminal Command"
                self.iconButton.image = self.icons.object(at: item.iconIndex) as? NSImage
                self.iconButton.index = item.iconIndex
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


    @objc func updateButtonIcon(_ note: Notification) {

        // When we receive a notification from the popover controller that an icon has been selected,
        // we come here and set the button's image to that icon
        if let obj = note.object {
            // Decode the notifiction object
            let index = obj as! NSNumber
            self.iconButton.image = self.icons.object(at: index.intValue) as? NSImage
            self.iconButton.index = index.intValue
        }
    }


    // MARK: - Action Functions

    @IBAction @objc func doCancel(sender: Any?) {

        // User has clicked 'Cancel', so just close the sheet

        self.parentWindow!.endSheet(addItemSheet)
        self.parentWindow = nil
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
            newItem.iconIndex = self.iconButton.index

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

                if item.iconIndex != self.iconButton.index {
                    itemHasChanged = true
                    item.iconIndex = self.iconButton.index
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
        self.parentWindow = nil
    }


    @IBAction @objc func doShowHelp(sender: Any?) {

        // Show the 'Help' via the website
        // TODO create web page
        // TODO provide offline help
        NSWorkspace.shared.open(URL.init(string:"https://smittytone.github.io/mnu/index.html#add-edit")!)
    }


    @IBAction @objc  func doShowIcons(sender: Any) {

        // Show the icon matrix
        self.iconPopover!.show(relativeTo: self.iconButton.bounds,
                               of: self.iconButton,
                               preferredEdge: NSRectEdge.maxY)
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
