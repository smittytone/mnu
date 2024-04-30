
/*
    AddUserItemViewController.swift
    MNU

    Created by Tony Smith on 24/07/2019.
    Copyright © 2024 Tony Smith. All rights reserved.

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


final class AddUserItemViewController: NSViewController,
                                       NSTextFieldDelegate,
                                       NSPopoverDelegate,
                                       NSWindowDelegate {

    // MARK: - UI Outlets

    @IBOutlet var addItemSheet: NSWindow!
    @IBOutlet var itemScriptText: AddUserItemTextField!
    @IBOutlet var menuTitleText: AddUserItemTextField!
    @IBOutlet var textCount: NSTextField!
    @IBOutlet var titleText: NSTextField!
    @IBOutlet var saveButton: NSButton!
    @IBOutlet var iconButton: AddUserItemIconButton!
    @IBOutlet var iconPopoverController: AddUserItemPopoverController!
    // FROM 1.2.0
    @IBOutlet var openCheck: NSButton!
    // FROM 1.2.2
    @IBOutlet var directCheck: NSButton!
    // FROM 1.7.0
    @IBOutlet var modifierKeysSegment: NSSegmentedControl!
    @IBOutlet var keyEquivalentText: AddUserItemKeyTextField!


    // MARK: - Public Class Properties

    var newMenuItem: MenuItem? = nil
    var currentMenuItems: MenuItemList? = nil
    var parentWindow: NSWindow? = nil
    var isEditing: Bool = false
    // FROM 1.5.0
    var appDelegate: AppDelegate? = nil


    // MARK: - Public Class Properties
    private var iconPopover: NSPopover? = nil
    private var icons: NSMutableArray = NSMutableArray.init()
    // FROM 1.5.0
    private var directAlert: NSAlert? = nil
    // FROM 1.7.0
    private var keyFieldEditor: AddUserItemKeyFieldEditor? = nil
    
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

        // FROM 1.7.0
        self.keyEquivalentText.segment = self.modifierKeysSegment

        // Set up notifications
        // 'com.bps.mnu.select-image' is sent by the AddUserItemViewController when an icon is selected
        let nc: NotificationCenter = NotificationCenter.default
        nc.addObserver(self,
                       selector: #selector(updateButtonIcon(_:)),
                       name: NSNotification.Name(rawValue: "com.bps.mnu.select-image"),
                       object: nil)
    }


    private func makeIconMatrix() {

        // Build the array of icons that we will use for the popover selector
        // and the button that triggers its appearance
        
        for i in 0..<MNU_CONSTANTS.ICONS.count {
            let image: NSImage? = NSImage.init(named: "picon_" + MNU_CONSTANTS.ICONS[i])
            self.icons.add(image!)
        }
    }


    private func makePopover() {

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

        // FROM 1.7.0
        // Reset the segment control
        self.modifierKeysSegment.selectedSegment = -1

        if self.isEditing {
            // We are presenting an existing item, so get it and populate
            // the sheet's fields accordingly
            if let item: MenuItem = self.newMenuItem {
                // Populate the fields from the MenuItem property
                self.itemScriptText.stringValue = item.script
                self.itemScriptText.becomeFirstResponder()
                self.itemScriptText.currentEditor()?.selectedRange = NSMakeRange(0, 0)
                self.menuTitleText.stringValue = item.title
                self.saveButton.title = "Update"
                self.titleText.stringValue = "Edit This Command"
                self.iconButton.image = self.icons.object(at: item.iconIndex) as? NSImage
                self.iconButton.index = item.iconIndex
                self.textCount.stringValue = "\(item.title.count)/30"
                self.openCheck.state = item.type == MNU_CONSTANTS.TYPES.SCRIPT ? .off : .on
                self.directCheck.state = item.isDirect ? .on : .off
                // FROM 1.7.0
                self.keyEquivalentText.stringValue = item.keyEquivalent.uppercased()
                
                if item.keyModFlags & (1 << MNU_CONSTANTS.MOD_KEY_SHIFT) != 0 {
                    self.modifierKeysSegment.selectSegment(withTag: MNU_CONSTANTS.MOD_KEY_SHIFT)
                }
                
                if item.keyModFlags & (1 << MNU_CONSTANTS.MOD_KEY_CMD) != 0 {
                    self.modifierKeysSegment.selectSegment(withTag: MNU_CONSTANTS.MOD_KEY_CMD)
                }
                
                if item.keyModFlags & (1 << MNU_CONSTANTS.MOD_KEY_OPT) != 0 {
                    self.modifierKeysSegment.selectSegment(withTag: MNU_CONSTANTS.MOD_KEY_OPT)
                }
                
                if item.keyModFlags & (1 << MNU_CONSTANTS.MOD_KEY_CTRL) != 0 {
                    self.modifierKeysSegment.selectSegment(withTag: MNU_CONSTANTS.MOD_KEY_CTRL)
                }
                
            } else {
                NSLog("Could not access the supplied MenuItem")
                return
            }
        } else {
            // We are presenting a new item, so create it and
            // clear the sheet's input fields
            self.itemScriptText.stringValue = ""
            self.itemScriptText.becomeFirstResponder()
            self.menuTitleText.stringValue = ""
            self.saveButton.title = "Add"
            self.titleText.stringValue = "Add A New Command"
            self.iconButton.image = self.icons.object(at: 0) as? NSImage
            self.iconButton.index = 0
            self.textCount.stringValue = "0/30"
            self.openCheck.state = .off
            self.directCheck.state = .off
            // FROM 1.7.0
            self.keyEquivalentText.stringValue = ""
        }

        // Present the sheet
        if let window = self.parentWindow {
            window.beginSheet(self.addItemSheet, completionHandler: nil)
        }
    }


    @objc func updateButtonIcon(_ note: Notification) {

        // When we receive a notification from the popover controller that an icon has been selected,
        // we come here and set the button's image to that icon
        
        if let obj: Any = note.object {
            // Decode the notification object
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
        let isOpenAction: Bool = self.openCheck.state == .on
        let isDirect: Bool = self.directCheck.state == .on
        
        // FROM 1.6.1
        // For end to editing, to see if this fixes the 'no changes' issue
        // with the TextFields
        if let theText: NSText = self.itemScriptText.currentEditor() {
            self.itemScriptText.endEditing(theText)
        }
        
        if let theText: NSText = self.menuTitleText.currentEditor() {
            self.menuTitleText.endEditing(theText)
        }
        
        // Check that we have valid field entries
        if self.itemScriptText.stringValue.count == 0 {
            // The field is blank, so warn the user
            showAlert("Missing Command", "You must enter a command. If you don’t want to set one at this time, click OK then Cancel")
            return
        }

        if self.menuTitleText.stringValue.count == 0 {
            // The field is blank, so warn the user
            showAlert("Missing Menu Label", "You must enter a label for the command’s menu entry. If you don’t want to set one at this time, click OK then Cancel")
            return
        }

        // FROM 1.5.0
        // If we've created an 'open' action, check that the target exists
        if isOpenAction {
            if let ad: AppDelegate = self.appDelegate {
                if ad.getAppPath(self.itemScriptText.stringValue) == nil {
                    showAlert("The app ‘\(self.itemScriptText.stringValue)’ cannot be found", "Please check that you have it installed on your Mac.")
                    return
                }
            }
        }

        // FROM 1.5.0
        // If the 'run direct' checkbox is set, make sure we have an absolute path
        if isDirect {
            // Check for an initial '/' to make sure we have an absolute path
            if !self.itemScriptText.stringValue.hasPrefix("/") {
                showAlert("You do not appear to have entered an absolute path", "Please check the ‘Enter a command...’ field and try so Save again.")
                return
            }

            // Check to see if the direct command contains common shell characters
            // NOTE We check 'sender' is not nil because we pass nil into the function
            //      when recursing it from 'showDirectAlert()' if the user chooses
            //      to save anyway
            if sender != nil && checkDirectCommand(self.itemScriptText.stringValue) {
                showDirectAlert()
                return
            }
        }

        // FROM 1.7.0
        // Make sure a specified key equivalent AND any modifiers are unique
        var modKeys: UInt = 0
        for i: Int in 0..<self.modifierKeysSegment.segmentCount {
            if self.modifierKeysSegment.isSelected(forSegment: i) {
                modKeys |= (1 << i)
            }
        }

        if !checkModifiers(modKeys) {
            return
        }

        if self.isEditing {
            // Save the updated fields
            if let item: MenuItem = self.newMenuItem {
                if item.title != self.menuTitleText.stringValue {
                    // FROM 1.2.0
                    // Check for a duplicate menu title if the
                    // menu title has been changed
                    if !checkLabel() { return }
                    
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
                
                // FROM 1.2.0
                let newType: Int = isOpenAction ? MNU_CONSTANTS.TYPES.OPEN : MNU_CONSTANTS.TYPES.SCRIPT
                if newType != item.type {
                    item.type = newType
                    itemHasChanged = true
                }

                // FROM 1.2.2
                if item.isDirect != isDirect {
                    itemHasChanged = true
                    item.isDirect = isDirect

                    // FROM 1.5.0
                    // Check for relative elements in the path - and update accordingly
                    if isDirect {
                        item.script = makeAbsolutePath(item.script)
                    }
                }
                
                // FROM 1.7.0
                if item.keyEquivalent != self.keyEquivalentText.stringValue {
                    itemHasChanged = true
                    item.keyEquivalent = self.keyEquivalentText.stringValue.lowercased()
                }
                
                if item.keyModFlags != modKeys {
                    itemHasChanged = true
                    item.keyModFlags = modKeys
                }
            }
        } else {
            // Process a new menu item
            // Check for a duplicate menu title
            if !checkLabel() { return }
            
            // Create a Menu Item and set its values
            let newItem: MenuItem = MenuItem()
            newItem.script = self.itemScriptText.stringValue
            newItem.title = self.menuTitleText.stringValue
            newItem.type = isOpenAction ? MNU_CONSTANTS.TYPES.OPEN : MNU_CONSTANTS.TYPES.SCRIPT
            newItem.code = MNU_CONSTANTS.ITEMS.SCRIPT.USER
            newItem.isNew = true
            newItem.iconIndex = self.iconButton.index
            // FROM 1.2.2
            newItem.isDirect = isDirect

            // FROM 1.5.0
            // Check for relative elements in the path - and update accordingly
            if isDirect {
                if (newItem.script as NSString).contains("..") {
                    newItem.script = (newItem.script as NSString).standardizingPath
                }
            }
            
            // FROM 1.7.0
            newItem.keyEquivalent = self.keyEquivalentText.stringValue
            newItem.keyModFlags = modKeys

            // Store the new menu item
            self.newMenuItem = newItem
            itemHasChanged = true
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
        // FROM 1.6.0 -- don't stop editing here, do it in notified code
        // self.isEditing = false
    }

    
    @IBAction @objc func doShowHelp(sender: Any?) {

        // Show the 'Help' via the website
        // TODO provide offline help

        if let helpURL: URL = URL.init(string: MNU_SECRETS.WEBSITE.URL_MAIN + "#how-to-add-and-edit-your-own-menu-items") {
            NSWorkspace.shared.open(helpURL)
        }
    }


    @IBAction @objc func doShowIcons(sender: Any) {

        // Show the icon matrix
        
        self.iconPopover!.show(relativeTo: self.iconButton.bounds,
                               of: self.iconButton,
                               preferredEdge: NSRectEdge.maxY)
    }


    @IBAction @objc func doCheckBox(sender: Any) {

        // FROM 1.5.0
        // Make sure mutually exclusive checkboxes aren't ticked

        let checkedButton: NSButton = sender as! NSButton
        var doWarn: Bool = false

        if checkedButton.state == .on {
            if checkedButton == self.directCheck {
                if self.openCheck.state == .on {
                    // Open action checkbox is set, so direct action can't be
                    doWarn = true
                }
            }

            if checkedButton == self.openCheck {
                if self.directCheck.state == .on {
                    // Direct action checkbox is set, so open action can't be
                    doWarn = true
                }
            }
        }

        if doWarn {
            // There is a clash, so turn off the just-checked button and warn the user
            checkedButton.state = .off
            showAlert("Sorry, you can’t check this option", "Selecting this option conflicts with another you have already chosen")
        }
    }


    @IBAction @objc func doClearKey(sender: Any) {

        // FROM 1.7.0

        self.keyEquivalentText.stringValue = ""
    }


    // MARK: - Input Checker Functions

    private func checkLabel() -> Bool {

        // ADDED 1.2.0
        // Moved from 'doSave()'
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
                    return false
                }
            }
        }

        return true
    }


    func checkDirectCommand(_ command: String) -> Bool {

        // ADDED 1.5.0
        // Check for common shell characters in a direct-action command
        let shellChars: [String] = ["~", "$", "*", "?", "!", "+", "@", "\"", "'", "{", "["]
        for shellChar in shellChars {
            if (command as NSString).contains(shellChar) {
                return true
            }
        }

        return false
    }


    func makeAbsolutePath(_ path: String) -> String {

        // ADDED 1.5.0
        // Check for a relative path and return the absolute version
        // (or the input path if it is already absolute)
        // NOTE Refactored to a function to simplify testing

        // Separate input path into space-separated sub-paths
        var returnPath: String = ""
        let parts: [String] = (path as NSString).components(separatedBy: " ")

        // Fix up each sub-path
        for i in 0..<parts.count {
            var part: String = parts[i]
            if (part as NSString).contains("..") {
                if !part.hasPrefix("/") {
                    part = "/" + part
                }
                returnPath += (part as NSString).standardizingPath
            } else {
                returnPath += part
            }

            // Put the spaces back for all but the last item
            if i < parts.count - 1 {
                returnPath += " "
            }
        }

        return returnPath
    }


    private func checkModifiers(_ modFlags: UInt) -> Bool {

        if self.keyEquivalentText.stringValue == "" {
            return true
        }

        if let list: MenuItemList = self.currentMenuItems {
            if list.items.count > 0 {
                if let newMenuItem: MenuItem = self.newMenuItem {
                    var got: Bool = false
                    for item: MenuItem in list.items {
                        if item.uuid != newMenuItem.uuid &&
                            item.keyEquivalent == self.keyEquivalentText.stringValue.lowercased() &&
                            item.keyModFlags == modFlags {
                            got = true
                            break
                        }
                    }
                    
                    if got {
                        // The label is in use, so warn the user and exit the save
                        showAlert("Key Equivalent and Modifiers are in use", "You must enter a unique key equivalent and modifier set. Please do so, or remove the key")
                        return false
                    }
                }
            }
        }

        return true;
    }


    // MARK: - Helper Functions

    private func showAlert(_ title: String, _ message: String) {

        // Present an alert to warn the user, with only one option
        
        let alert: NSAlert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.beginSheetModal(for: self.addItemSheet,
                              completionHandler: nil)
    }


    private func showDirectAlert() {

        // FROM 1.5.0
        // Present an alert to warn the user, with two options

        self.directAlert = NSAlert()
        self.directAlert!.messageText = "Your direct command contains one or more common shell characters"
        self.directAlert!.informativeText = "Direct commands are not processed by a shell. Are you sure you want to save this command?"
        self.directAlert!.addButton(withTitle: "Save")
        self.directAlert!.addButton(withTitle: "Edit Command")
        self.directAlert!.beginSheetModal(for: self.addItemSheet) { (response) in
            if response == .alertFirstButtonReturn {
                self.directAlert!.window.orderOut(nil)
                self.doSave(sender: nil)
            }
        }
    }


    // MARK: - NSTextFieldDelegate Functions

    func controlTextDidChange(_ obj: Notification) {

        // We use this to trap text entry into the 'itemText' field and limit it to x characters
        // where x is set by 'MNU_CONSTANTS.MENU_TEXT_LEN'
        let sender: NSTextField = obj.object as! NSTextField

        if sender == self.menuTitleText {
            if self.menuTitleText.stringValue.count > MNU_CONSTANTS.MENU_TEXT_LEN {
                // The field contains more than 'MNU_CONSTANTS.MENU_TEXT_LEN' characters, so only
                // keep that number of characters in the field
                self.menuTitleText.stringValue = String(self.menuTitleText.stringValue.prefix(MNU_CONSTANTS.MENU_TEXT_LEN))
                NSSound.beep()
            }

            // Whenever a character is entered, update the character count
            self.textCount.stringValue = "\(self.menuTitleText.stringValue.count)/\(MNU_CONSTANTS.MENU_TEXT_LEN)"
            return;
        }
    }


    // MARK: - NSWindowDelegate Methods

    func windowWillReturnFieldEditor(_ sender: NSWindow, to client: Any?) -> Any? {

        // ADDED 1.7.0
        // Assign a custom Field Editor to the modifier keys NSTextField
        // See `AddUserItemKeyFieldEditor.swift`

        if let anyClient: Any = client {
            if anyClient is AddUserItemKeyTextField {
                if self.keyFieldEditor == nil {
                    self.keyFieldEditor = AddUserItemKeyFieldEditor.init()
                }

                // Don't process Tab, Enter etc.
                self.keyFieldEditor!.isFieldEditor = false

                // Link in the NSTextField subclass
                self.keyFieldEditor!.keyTextField = self.keyEquivalentText

                // Trap Undo (CMD-Z) handling
                self.keyFieldEditor!.allowsUndo = false
                self.keyEquivalentText.undoManager?.registerUndo(withTarget: self.keyFieldEditor!,
                                                                 selector: #selector(AddUserItemKeyFieldEditor.undo),
                                                                 object: nil)
                return self.keyFieldEditor!
            }
        }

        return nil
    }
}
