
/*
    ConfigureWindowViewController.swift
    MNU

    Created by Tony Smith on 05/07/2019.
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


class ConfigureViewController:  NSViewController,
                                NSTabViewDelegate,
                                NSTableViewDataSource,
                                NSTableViewDelegate,
                                NSWindowDelegate,
                                NSMenuDelegate {

    // MARK: - UI Outlets

    @IBOutlet var windowTabView: NSTabView!

    // Menu Items Tab
    @IBOutlet var menuItemsTableView: NSTableView!
    @IBOutlet var menuItemsCountText: NSTextField!
    @IBOutlet var showHelpButton: NSButton!
    @IBOutlet var aivc: AddUserItemViewController!
    // FROM 1.1.0
    @IBOutlet var extrasButton: NSButton!
    @IBOutlet var menuItemsAddButton: NSButton!
    @IBOutlet var applyChangesButton: NSButton!

    // Preferences Tab
    @IBOutlet var prefsLaunchAtLoginButton: NSButton!
    @IBOutlet var prefsNewTermTabButton: NSButton!
    @IBOutlet var prefsShowControlsButton: NSButton!
    @IBOutlet var prefsHelpButton: NSButton!

    // About... Tab
    @IBOutlet var aboutVersionText: NSTextField!
    @IBOutlet var fbvc: FeedbackSheetViewController!
    // FROM 1.1.0
    @IBOutlet var feedbackButton: NSButton!
    
    

    // MARK: - Class Properties

    var menuItems: MenuItemList? = nil
    var configureWindow: NSWindow? = nil
    let mnuPasteboardType = NSPasteboard.PasteboardType(rawValue: "com.bps.mnu.pb")
    var hasChanged: Bool = false
    var isVisible: Bool = false
    var lastChance: Bool = false
    // FROM 1.1.0
    var extrasMenu: NSMenu? = nil
    

    // MARK: - Lifecycle Functions

    override func viewDidLoad() {

        super.viewDidLoad()

        // Ask our window to make the  first responder (for key presses)
        self.configureWindow = self.view.window
        self.configureWindow!.makeFirstResponder(self)

        // Set up the table view for drag and drop reordering
        self.menuItemsTableView.registerForDraggedTypes([self.mnuPasteboardType])
        self.menuItemsTableView.delegate = self

        // Watch for notifications of changes sent by the add user item view controller
        let nc = NotificationCenter.default
        nc.addObserver(self,
                       selector: #selector(self.processNewItem),
                       name: NSNotification.Name(rawValue: "com.bps.mnu.item-added"),
                       object: nil)

        // Set up the About MNU... tab text
        let version: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        let build: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
        aboutVersionText.stringValue = "Version \(version) (\(build))"
        
        // FROM 1.1.0
        // Prepare the extras... button
        self.extrasMenu = NSMenu()
        self.extrasMenu!.addItem(NSMenuItem.init(title: "Backup MNU Items...", action: #selector(self.doExport), keyEquivalent: ""))
        self.extrasMenu!.addItem(NSMenuItem.init(title: "Import Items...", action: #selector(self.doImport), keyEquivalent: ""))
        //self.extrasMenu!.addItem(NSMenuItem.separator())
        //self.extrasMenu!.addItem(NSMenuItem.init(title: "Show Help...", action: #selector(self.doExtraHelp), keyEquivalent: ""))

        // FROM 1.1.0
        // Add tooltips: Menu Items Tab
        self.menuItemsAddButton.toolTip = "Add a new menu item"
        self.extrasButton.toolTip = "Click here for further actions"
        self.applyChangesButton.toolTip = "Click to apply any changes you have made"
        self.showHelpButton.toolTip = "Click here for help with this tab"

        // Preferences Tab
        self.prefsHelpButton.toolTip = "Click here for help with this tab"
        self.prefsLaunchAtLoginButton.toolTip = "Check to automatically launch MNU when your Mac starts up"
        self.prefsNewTermTabButton.toolTip = "Check to run commands in new Terminal tabs"
        self.prefsShowControlsButton.toolTip = "Check to display images alongside MNU menu items"
        
        // About... Tab
        self.feedbackButton.toolTip = "Click here to submit comments and feedback about MNU"
    }


    override func viewWillAppear() {
        
        super.viewDidAppear()
        
        // FROM 1.0.0: move from the app delegate
        // Update the item table
        self.menuItemsTableView.reloadData()
        
        // Update the menu item list count indicator
        displayItemCount()
        
        // FROM 1.0.1: moved from 'viewDidLoad()' so that the items update AFTER defaults registration
        // Set up the Preferences section
        let defaults: UserDefaults = UserDefaults.standard
        self.prefsLaunchAtLoginButton.state = defaults.bool(forKey: "com.bps.mnu.startup-launch") ? NSControl.StateValue.on : NSControl.StateValue.off
        self.prefsNewTermTabButton.state = defaults.bool(forKey: "com.bps.mnu.new-term-tab") ? NSControl.StateValue.on : NSControl.StateValue.off
        self.prefsShowControlsButton.state = defaults.bool(forKey: "com.bps.mnu.show-controls") ? NSControl.StateValue.on : NSControl.StateValue.off
        
        // FROM 1.1.0
        // Disable/enable the Apply button until changes are made
        self.applyChangesButton.isEnabled = self.hasChanged
    }

    
    override func viewDidAppear() {
        
        // Update the visibility state
        self.isVisible = true
        super.viewDidAppear()
    }
    
    
    func show() {

        // Show the controller's own window in the centre of the display
        // NOTE This triggers calls to 'viewWillAppear()', 'viewdidAppear()', etc.
        self.windowTabView.selectTabViewItem(at: 0)
        self.configureWindow!.center()
        self.configureWindow!.makeKeyAndOrderFront(nil)
        
        // The following is required to bring the window to the front properly
        NSApp.activate(ignoringOtherApps: true)
    }
    
    
    override func resignFirstResponder() -> Bool {
        
        // Make sure we can continue to track key events
        // NOTE Currently disabled (to restore table drag'n'drop)
        return true
    }
    
    
    // MARK: - Action Functions
    // MARK: Menu Items List Functions
    
    @IBAction @objc func doCancel(sender: Any?) {

        // The user clicked 'Cancel', so hust close the configure window
        self.configureWindow!.performClose(sender)
        
        // Update the visibility state
        self.isVisible = false
    }


    @IBAction @objc func doSave(sender: Any?) {

        // If any changes have been made to the item list, inform the app delegate
        if self.hasChanged {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "com.bps.mnu.list-updated"),
                                            object: self)
            self.hasChanged = false
        }

        // DISABLED FROM BUILD 3
        // Close the Configure window
        // self.configureWindow!.close()
    }

    
    @IBAction @objc func doNewScriptItem(sender: Any?) {
        
        // Check that the user has not added too many items already
        // current limit is set as 'MNU_CONSTANTS.MAX_ITEM_COUNT'
        // TODO Calculate the number of DISPLAYED items and limit that rather than the total
        if let items = self.menuItems {
            if items.items.count >= MNU_CONSTANTS.MAX_ITEM_COUNT {
                // Limit reached - warn the user
                let alert: NSAlert = NSAlert()
                alert.messageText = "You have already added the maximum number of items to MNU"
                alert.informativeText = "MNU can only show \(MNU_CONSTANTS.MAX_ITEM_COUNT) items. Please delete an item before adding a new one."
                alert.addButton(withTitle: "OK")
                alert.beginSheetModal(for: self.configureWindow!,
                                      completionHandler: nil)
                return
            }
        }
        
        // Tell the Add User Item view controller to display its own sheet as
        // ready to accept a new item
        self.aivc.isEditing = false
        self.aivc.currentMenuItems = self.menuItems
        self.aivc.parentWindow = self.configureWindow!
        self.aivc.showSheet()
    }
    
    
    @IBAction @objc func doContextShowHide(sender: Any) {
        
        // Get the Menu Item from the reference stored in the contextual menu item
        let menuItem: NSMenuItem = sender as! NSMenuItem
        let item: MenuItem = menuItem.representedObject as! MenuItem
        doShowHide(item)
    }

    
    @objc func doShowHideSwitch(sender: Any) {

        // Get the Menu Item from the reference stored in the MenuItemTableCellButton
        let button: MenuItemTableCellButton = sender as! MenuItemTableCellButton
        if let item: MenuItem = button.menuItem {
            doShowHide(item)
        }
    }
    
    
    func doShowHide(_ item: MenuItem) {
        
        // Flip the item's recorded state and update the table
        item.isHidden = !item.isHidden
        self.hasChanged = true
        self.applyChangesButton.isEnabled = true
        
        // Reload the table data and update the status line
        self.menuItemsTableView.reloadData()
        displayItemCount()
    }

    
    @IBAction func doContextEditScript (sender: Any) {
        
        // Get the Menu Item from the reference stored in the contextual menu item
        let menuItem: NSMenuItem = sender as! NSMenuItem
        let item: MenuItem = menuItem.representedObject as! MenuItem
        doEdit(item)
    }
    
    
    @objc func doEditScript(sender: Any) {

        // Get the Menu Item from the reference stored in the MenuItemTableCellButton
        let button: MenuItemTableCellButton = sender as! MenuItemTableCellButton
        if let item: MenuItem = button.menuItem {
            doEdit(item)
        }
    }

    
    func doEdit(_ item: MenuItem) {
        
        // Populate the sheet's fields for editing
        self.aivc.newMenuItem = item
        self.aivc.isEditing = true
        self.aivc.parentWindow = self.configureWindow!
        
        // Tell the add user item view controller to display its sheet
        self.aivc.showSheet()
    }
    
    
    @IBAction @objc func doContextDeleteScript(sender: Any) {
        
        // Get the Menu Item from the reference stored in the contextual menu item
        let menuItem: NSMenuItem = sender as! NSMenuItem
        if let item: MenuItem = menuItem.representedObject as? MenuItem {
            doDelete(item)
        }
    }
    
    
    @objc func doDeleteScript(sender: Any) {

        // Get the Menu Item from the reference stored in the MenuItemTableCellButton
        let button: MenuItemTableCellButton = sender as! MenuItemTableCellButton
        if let item: MenuItem = button.menuItem {
            doDelete(item)
        }
    }
    
    
    func doDelete(_ item: MenuItem) {
        
        // Present an alert to warn the user about deleting the Menu Item
        let alert: NSAlert = NSAlert()
        alert.messageText = "Are you sure you wish to delete ‘\(item.title)’?"
        alert.addButton(withTitle: "Yes")
        alert.addButton(withTitle: "No")
        alert.beginSheetModal(for: self.configureWindow!) { (response: NSApplication.ModalResponse) in
            if response == NSApplication.ModalResponse.alertFirstButtonReturn {
                // The user clicked 'Yes' so find the item referenced by the button,
                // and remove it from the configure window controller's list
                if let list = self.menuItems {
                    if list.items.count > 0 {
                        var index = -1
                        for i in 0..<list.items.count {
                            let anItem: MenuItem = list.items[i]
                            if anItem == item {
                                index = i
                                break
                            }
                        }
                        
                        if index != -1 {
                            list.items.remove(at: index)
                            self.hasChanged = true
                            self.applyChangesButton.isEnabled = true
                            self.menuItemsTableView.reloadData()
                        }
                    }
                }
            }
        }
    }


    @IBAction @objc func doShowExtras(sender: NSButton) {

        // FROM 1.1.0
        // Pop up the import/export buttons
        let yDelta: CGFloat = 4.0
        let buttonPosition = NSPoint(x: 0, y: yDelta + sender.frame.size.height)
        self.extrasMenu!.popUp(positioning: nil,
                               at: buttonPosition,
                               in: sender)
    }


    @objc func doExtraHelp() {

        // FROM 1.1.0
        // Just call the existing 'doShowHelp()' function as if we were a button
        doShowHelp(sender: self.extrasButton)
    }


    // MARK: About... Pane Functions
    
    @IBAction @objc func submitFeedback(sender: Any?) {

        // Get the feedback sheet view controller to show its sheet
        self.fbvc.parentWindow = self.configureWindow!
        self.fbvc.showSheet()
    }

    
    // MARK: Preferences Pane Functions
    
    @IBAction @objc func doToggleLaunchAtLogin(sender: Any?) {

        // The user has toggled the 'launch at login' checkbox, so send a suitable
        // notification to the app delegate
        let action: String = "com.bps.mnu.startup-" + (prefsLaunchAtLoginButton.state == NSControl.StateValue.on ? "enabled" : "disabled")
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: action),
                                        object: self)
    }
    
    
    @IBAction @objc func doSetTermPref(sender: Any?) {
        
        // The user has toggled the 'launch at login' checkbox, so send a suitable
        // notification to the app delegate
        let defaults: UserDefaults = UserDefaults.standard
        let state = self.prefsNewTermTabButton.state == NSControl.StateValue.on ? true : false
        defaults.set(state,
                     forKey: "com.bps.mnu.new-term-tab")
    }


    @IBAction @objc func doShowControls(sender: Any?) {

        // The user has toggled the 'launch at login' checkbox, so send a suitable
        // notification to the app delegate
        let defaults: UserDefaults = UserDefaults.standard
        let state = self.prefsShowControlsButton.state == NSControl.StateValue.on ? true : false
        defaults.set(state,
                     forKey: "com.bps.mnu.show-controls")

        // Notify the menu that it needs to change
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "com.bps.mnu.list-updated"),
                                        object: self)
    }

    
    @IBAction @objc func doShowHelp(sender: Any?) {
        
        // Show the 'Help' via the website
        // TODO provide offline help
        var path: String = "https://smittytone.github.io/mnu/index.html"
        let button: NSButton = sender as! NSButton
        path += button == self.prefsHelpButton ? "#mnu-preferences" : "#how-to-configure-mnu"
        NSWorkspace.shared.open(URL.init(string:path)!)
    }
    
    
    // MARK: - List Import/Export Functions

    @objc func doExport() {
        
        // FROM 1.1.0
        // Create a save panel for the export operation...
        let savePanel: NSSavePanel = NSSavePanel()
        savePanel.allowedFileTypes = ["json"]
        savePanel.allowsOtherFileTypes = false
        savePanel.canCreateDirectories = true
        savePanel.nameFieldStringValue = "MNUItems"
        savePanel.directoryURL = FileManager.default.homeDirectoryForCurrentUser

        // ...and show it
        savePanel.beginSheetModal(for: self.view.window!) { (response) in
            
            if response == NSApplication.ModalResponse.OK {
                // The user clicked the Save button
                if let targetUrl = savePanel.url {
                    // Create a JSON string representation of the menu data
                    let dataString: String = Serializer.jsonizeAll(self.menuItems!)

                    // Convert the string to data for saving
                    if let fileData: Data = dataString.data(using: String.Encoding.utf16) {
                    
                        // Save the data
                        let success = FileManager.default.createFile(atPath: targetUrl.path,
                                                                     contents:fileData,
                                                                     attributes: nil)
                        if !success {
                            self.showExportAlert()
                        }
                    } else {
                        // Could not convert the JSON string to UTF-16 data
                        self.showExportAlert()
                    }
                }
            }
        }
    }


    func showExportAlert() {

        // FROM 1.1.0
        // Multi-use call from 'doExport()'
        showAlert("File Export Error",
                  "Sorry, but the menu items back-up file could not be created. Please try again.")
    }
    
    
    @objc func doImport() {
        
        // FROM 1.1.0
        // Create an open panel for the import operation...
        let openPanel: NSOpenPanel = NSOpenPanel()
        openPanel.allowedFileTypes = ["json"]
        openPanel.allowsOtherFileTypes = false
        openPanel.allowsMultipleSelection = false
        openPanel.directoryURL = FileManager.default.homeDirectoryForCurrentUser

        // ...and show it
        openPanel.beginSheetModal(for: self.view.window!) { (response) in

            if response == NSApplication.ModalResponse.OK {
                // The user clicked the Save button
                if let targetUrl = openPanel.url {
                    // Load the data if we have a valid file URL
                    do {
                        let fileData: Data = try Data.init(contentsOf: targetUrl)
                        let newMenu: MenuItemList? = Serializer.dejsonizeAll(fileData)

                        if newMenu != nil {
                            // If we have a valid menu loaded, retain it
                            // and update the UI
                            self.menuItems = newMenu
                            self.hasChanged = true
                            self.applyChangesButton.isEnabled = true
                            self.menuItemsTableView.reloadData()
                        } else {
                            // Show Error message
                            self.showAlert("File Import Error",
                                           "Sorry, but the menu items back-up file could not be processed. Is it a MNU file?")
                        }
                    } catch {
                        // Post Warning
                        self.showAlert("File Import Error",
                                       "Sorry, but the menu items back-up file could not be loaded from disk. Is it a MNU file?")
                    }
                }
            }
        }
    }
    
    
    // MARK: - Notification Handlers

    @objc func processNewItem() {

        // This function is called in response to a "com.bps.mnu.item-added" notification
        // from the Add User Item view controller that an existing item was edited,
        // or a new item created

        if aivc != nil {
            if !aivc.isEditing {
                // Add a newly created Menu Item to the list
                if let item: MenuItem = aivc!.newMenuItem {
                    self.menuItems!.items.append(item)
                }
            }

            self.hasChanged = true
            self.applyChangesButton.isEnabled = true
            self.menuItemsTableView.reloadData()
            displayItemCount()
        }
    }

    
    // MARK: - TableView Data Source and Delegate Functions

    func numberOfRows(in tableView: NSTableView) -> Int {

        if let items = self.menuItems {
            return items.items.count
        }

        return 0
    }


    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {

        if let items = self.menuItems {
            let item: MenuItem = items.items[row]
            let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "mnu-item-cell"), owner: self) as? MenuItemTableCellView
            
            if cell != nil {
                // Configure the cell's title and its three buttons
                // NOTE 'buttonA' is the right-most button
                cell!.title.stringValue = item.title
                
                cell!.buttonA.image = NSImage.init(named: "NSStopProgressFreestandingTemplate")
                cell!.buttonA.action = #selector(self.doDeleteScript(sender:))
                cell!.buttonA.toolTip = "Delete Item"
                cell!.buttonA.isEnabled = true
                cell!.buttonA.menuItem = item

                cell!.buttonB.image = NSImage.init(named: "NSActionTemplate")
                cell!.buttonB.action = #selector(self.doEditScript(sender:))
                cell!.buttonB.toolTip = "Edit Item"
                cell!.buttonB.isEnabled = true
                cell!.buttonB.menuItem = item

                cell!.buttonC.image = NSImage.init(named: (item.isHidden ? "NSStatusUnavailable" : "NSStatusAvailable"))
                cell!.buttonC.action = #selector(self.doShowHideSwitch(sender:))
                cell!.buttonC.toolTip = "Show/Hide Item"
                cell!.buttonC.isEnabled = true
                cell!.buttonC.menuItem = item

                if item.type == MNU_CONSTANTS.TYPES.SWITCH || item.code != MNU_CONSTANTS.ITEMS.SCRIPT.USER {
                    // This is a built-in switch, so disable the edit, delete buttons
                    cell!.buttonB.isEnabled = false
                    cell!.buttonA.isEnabled = false
                }

                return cell
            }
        }

        return nil
    }


    func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {

        if let items = self.menuItems {
            let item: MenuItem = items.items[row]
            let pasteboardItem = NSPasteboardItem()
            pasteboardItem.setString(item.title, forType: self.mnuPasteboardType)
            return pasteboardItem
        }

        return nil
    }


    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {

        if dropOperation == .above {
            return .move
        } else {
            return []
        }
    }


    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        guard
            let item = info.draggingPasteboard.pasteboardItems?.first,
            let itemTitle = item.string(forType: self.mnuPasteboardType)
            else { return false }

        var originalRow = -1
        if let items = self.menuItems {
            for i in 0..<items.items.count {
                let anItem: MenuItem = items.items[i]
                if anItem.title == itemTitle {
                    originalRow = i
                }
            }

            var newRow = row
            if originalRow < newRow { newRow = row - 1 }

            // Animate the rows
            tableView.beginUpdates()
            tableView.moveRow(at: originalRow, to: newRow)
            tableView.endUpdates()

            // Move the list items
            let anItem: MenuItem = items.items[originalRow]
            items.items.remove(at: originalRow)
            items.items.insert(anItem, at: newRow)

            hasChanged = true
            return true
        }

        return false
    }


    // MARK: - NSWindowDelegate Functions

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        
        // Before the Configure Window closes, check for un-applied changes
        // NOTE This follows from any call to 'doCancel()'
        if self.hasChanged {
            // There are unsaved changes - warn the user
            let alert = NSAlert.init()
            alert.messageText = "You have unapplied changes"
            alert.informativeText = "Do you wish to apply the changes you have made before closing the Configure MNU window?"
            alert.addButton(withTitle: "Yes")
            alert.addButton(withTitle: "No")
            if !self.lastChance {
                alert.addButton(withTitle: "Cancel")
            }
            
            alert.beginSheetModal(for: self.configureWindow!) { (selection) in
                if selection == NSApplication.ModalResponse.alertFirstButtonReturn {
                    // The user said YES, so add MNU to the login items system preference
                    self.doSave(sender: nil)
                }
                
                if selection != NSApplication.ModalResponse.alertThirdButtonReturn {
                    // The user said YES or NO, so close the window
                    self.configureWindow!.close()
                    if self.lastChance {
                        // We're bailing, so inform the host app we can quit at last
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "com.bps.mnu.can-quit"),
                                                        object: self)
                    }
                }
            }

            return false
        }

        return true
    }

    
    // MARK: - Key Event Handling Functions
    
    override func keyDown(with event: NSEvent) {
        
        // Catch key events to trap ESC (close window), arrows (cycle through tabs), CMD-M (minimize)
        
        if event.keyCode == MNU_CONSTANTS.MENU_ESC_KEY {
            // ESC key pressed
            // Make sure the sheets aren't visible and close
            if self.aivc.parentWindow == nil && self.fbvc.parentWindow == nil {
                doCancel(sender: self)
            }
            
            return
        }
        
        if (event.keyCode == MNU_CONSTANTS.MENU_ARR_KEY) {
            // Right Arrow key pressed
            // Cycle through the tabs in that direction
            if self.aivc.parentWindow == nil && self.fbvc.parentWindow == nil {
                if let selectedTab: NSTabViewItem = self.windowTabView.selectedTabViewItem {
                    let index = self.windowTabView.indexOfTabViewItem(selectedTab)
                    if index == 2 {
                        self.windowTabView.selectTabViewItem(at: 0)
                        return
                    }
                }
                
                self.windowTabView.selectNextTabViewItem(self)
                return
            }
        }
        
        if (event.keyCode == MNU_CONSTANTS.MENU_ARL_KEY) {
            // Left Arrow key pressed
            // Cycle through the tabs in that direction
            if self.aivc.parentWindow == nil && self.fbvc.parentWindow == nil {
                if let selectedTab: NSTabViewItem = self.windowTabView.selectedTabViewItem {
                    let index = self.windowTabView.indexOfTabViewItem(selectedTab)
                    if index == 0 {
                        self.windowTabView.selectTabViewItem(at: 2)
                        return
                    }
                }
                
                self.windowTabView.selectPreviousTabViewItem(self)
                return
            }
        }
        
        if event.keyCode == 46 && event.modifierFlags.contains(NSEvent.ModifierFlags.command) {
            // CMD-M pressed
            // Minimize the window
            self.configureWindow!.miniaturize(self)
            return
        }
        
        // Pass on allow other key events
        super.keyDown(with: event)
    }
    
    
    // MARK: - NSMenuDelegate Functions
    
    func menuNeedsUpdate(_ menu: NSMenu) {
        
        // We come here before displaying the NSTableView's set contextual menu
        // (its 'menu' property, set in Interface Builder) in order to update
        // the menu's items for the Menu Item clicked on
        
        // Get the NSTableView row that the user clicked
        let clickedRow: Int = self.menuItemsTableView.clickedRow
        
        if clickedRow > -1 {
            // If the click was on a valid row, use that index to
            // get the MenuItem represented at the clicked row
            if let items = self.menuItems {
                let item: MenuItem = items.items[clickedRow]
                // Set the contextual menu's three items (Show/Hide, Edit, Delete)
                // to point to the Menu Item represented at the clicked row
                menu.item(at: 0)!.representedObject = item
                menu.item(at: 1)!.representedObject = item
                menu.item(at: 2)!.representedObject = item
                
                // Contextualise the Show/Hide menu item's title
                menu.item(at: 0)?.title = item.isHidden ? "Show" : "Hide"
                
                // Assume all of the NSMenuItems are required...
                menu.item(at: 0)!.isEnabled = true
                menu.item(at: 1)!.isEnabled = true
                menu.item(at: 2)!.isEnabled = true
                
                // ... but disabled those that are not needed by the Menu Item
                // (ie. it represents a built-in item)
                if item.type == MNU_CONSTANTS.TYPES.SWITCH || item.code != MNU_CONSTANTS.ITEMS.SCRIPT.USER {
                    menu.item(at: 1)!.isEnabled = false
                    menu.item(at: 2)!.isEnabled = false
                }
            }
        }
    }


    // MARK: - NSTabViewDelegate Functions

    func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {

        // Catch tab view changes to prevent the view controller from being
        // dropped from the window's responder chain. We need to do this in
        // order to ensure the view controller continues to handle the key down
        // events it is watching out for.
        self.configureWindow!.makeFirstResponder(self)
    }


    // MARK: - Misc Functions

    func displayItemCount() {

        // Update the count of current menu items
        var total = 0
        var count = 0

        if let list: MenuItemList = self.menuItems {
            if list.items.count > 0 {
                total = list.items.count
                for item: MenuItem in list.items {
                    if !item.isHidden {
                        count += 1
                    }
                }
            }
        }

        // Handle plurals in the text correctly, and subsitite 'no' for '0'
        let itemText = count == 1 ? "item" : "items"
        let countText = count == 0 ? "no" : "\(count)"

        // Display the text
        menuItemsCountText.stringValue = "MNU is showing \(countText) \(itemText) out of \(total) (Option-click the menu to show all items)"
    }


    func showAlert(_ title: String, _ message: String) {

        // Present an alert to warn the user about deleting the Menu Item
        let alert: NSAlert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.beginSheetModal(for: self.view.window!,
                              completionHandler: nil)
    }

}
