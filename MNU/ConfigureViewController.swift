
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
                                NSWindowDelegate {

    // MARK: - UI Outlets

    @IBOutlet weak var windowTabView: NSTabView!

    // Menu Items Tab
    @IBOutlet weak var menuItemsTableView: NSTableView!
    @IBOutlet weak var menuItemsCountText: NSTextField!
    @IBOutlet weak var aivc: AddUserItemViewController!
    @IBOutlet weak var menuItemsHelpButton: NSButton!

    // Preferences Tab
    @IBOutlet weak var prefsLaunchAtLoginButton: NSButton!
    @IBOutlet weak var prefsNewTermTabButton: NSButton!
    @IBOutlet weak var prefsShowControlsButton: NSButton!
    @IBOutlet weak var prefsHelpButton: NSButton!

    // About... Tab
    @IBOutlet weak var aboutVersionText: NSTextField!
    @IBOutlet weak var fbvc: FeedbackSheetViewController!
    

    // MARK: - Class Properties

    var menuItems: MenuItemList? = nil
    var configureWindow: NSWindow? = nil
    let mnuPasteboardType = NSPasteboard.PasteboardType(rawValue: "com.bps.mnu.pb")
    var hasChanged: Bool = false


    // MARK: - Lifecycle Functions

    override func viewDidLoad() {

        super.viewDidLoad()
        
        // Ask out window to make us first responder (for key presses)
        self.view.window!.makeFirstResponder(self)

        // Set up the table view for drag and drop reordering
        self.menuItemsTableView.registerForDraggedTypes([mnuPasteboardType])

        // Watch for notifications of changes sent by the add user item view controller
        let nc = NotificationCenter.default
        nc.addObserver(self,
                       selector: #selector(self.processNewItem),
                       name: NSNotification.Name(rawValue: "com.bps.mnu.item-added"),
                       object: nil)

        // Set the add user item view controller's parent window
        self.configureWindow = self.view.window!
        //self.aivc.parentWindow = self.configureWindow!
        //self.fbvc.parentWindow = self.configureWindow!
        
        // Set up the Preferences section
        let defaults: UserDefaults = UserDefaults.standard
        self.prefsLaunchAtLoginButton.state = defaults.bool(forKey: "com.bps.mnu.startup-launch") ? NSControl.StateValue.on : NSControl.StateValue.off
        self.prefsNewTermTabButton.state = defaults.bool(forKey: "com.bps.mnu.new-term-tab") ? NSControl.StateValue.on : NSControl.StateValue.off
        self.prefsShowControlsButton.state = defaults.bool(forKey: "com.bps.mnu.show-controls") ? NSControl.StateValue.on : NSControl.StateValue.off

        // Set up the About MNU... tab text
        let version: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        let build: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
        aboutVersionText.stringValue = "Version \(version) (\(build))"
    }


    override func viewWillAppear() {

        // Update the menu item list count indicator
        displayItemCount()
    }

    
    func show() {

        // Show the controller's own window in the centre of the display
        self.windowTabView.selectTabViewItem(at: 0)
        self.configureWindow!.center()
        self.configureWindow!.makeKeyAndOrderFront(nil)
        //self.configureWindow!.makeKey()
        //self.configureWindow!.orderFrontRegardless()
        // The following is required to bring the window to the front properly
        // SEE https://stackoverflow.com/questions/7460092/nswindow-makekeyandorderfront-makes-window-appear-but-not-key-or-front
        NSApp.activate(ignoringOtherApps: true)
    }
    
    
    override func resignFirstResponder() -> Bool {
        
        // Make sure we can continue to track key events
        return false
    }


    
    // MARK: - Action Functions
    // MARK: Menu Items List Functions
    
    @IBAction @objc func doCancel(sender: Any?) {

        // The user clicked 'Cancel', so hust close the configure window
        self.configureWindow!.close()
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

        // Tell the Add User Item view controller to display its own sheet as
        // ready to accept a new item
        self.aivc.isEditing = false
        self.aivc.currentMenuItems = self.menuItems
        self.aivc.parentWindow = self.configureWindow!
        self.aivc.showSheet()
    }


    @objc func doShowHideSwitch(sender: Any) {

        // Get the Menu Item from the reference stored in the MenuItemTableCellButton
        let button: MenuItemTableCellButton = sender as! MenuItemTableCellButton
        if let item: MenuItem = button.menuItem {
            // Flip the item's recorded state and update the table
            item.isHidden = !item.isHidden
            self.hasChanged = true

            // Reload the table data and update the status line
            self.menuItemsTableView.reloadData()
            displayItemCount()
        }
    }


    @objc func doEditScript(sender: Any) {

        // Get the Menu Item from the reference stored in the MenuItemTableCellButton
        let button: MenuItemTableCellButton = sender as! MenuItemTableCellButton
        if let item: MenuItem = button.menuItem {
            // Populate the sheet's fields for editing
            self.aivc.newMenuItem = item
            self.aivc.isEditing = true
            self.aivc.parentWindow = self.configureWindow!
            
            // Tell the add user item view controller to display its sheet
            self.aivc.showSheet()
        }
    }


    @objc func doDeleteScript(sender: Any) {

        // Get the Menu Item from the reference stored in the MenuItemTableCellButton
        let button: MenuItemTableCellButton = sender as! MenuItemTableCellButton
        if let item: MenuItem = button.menuItem {
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
                                self.menuItemsTableView.reloadData()
                            }
                        }
                    }
                }
            }
        }
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
        // TODO create web page
        // TODO provide offline help
        var path: String = "https://smittytone.github.io/mnu/index.html"
        let button: NSButton = sender as! NSButton
        path += button == self.prefsHelpButton ? "#prefs" : "#how-to-configure"
        NSWorkspace.shared.open(URL.init(string:path)!)
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
                cell!.buttonA.menuItem = item
                cell!.buttonA.toolTip = "Delete Item"
                
                cell!.buttonB.image = NSImage.init(named: "NSActionTemplate")
                cell!.buttonB.action = #selector(self.doEditScript(sender:))
                cell!.buttonB.menuItem = item
                cell!.buttonB.toolTip = "Edit Item"
                
                cell!.buttonC.image = NSImage.init(named: (item.isHidden ? "NSStatusUnavailable" : "NSStatusAvailable"))
                cell!.buttonC.action = #selector(self.doShowHideSwitch(sender:))
                cell!.buttonC.menuItem = item
                cell!.buttonC.toolTip = "Show/Hide Item"
                
                if item.type == MNU_CONSTANTS.TYPES.SWITCH || (item.type == MNU_CONSTANTS.TYPES.SCRIPT && item.code != MNU_CONSTANTS.ITEMS.SCRIPT.USER) {
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
            pasteboardItem.setString(item.title, forType: mnuPasteboardType)
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
            let itemTitle = item.string(forType: mnuPasteboardType)
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

        if self.hasChanged {
            // There are unsaved changes - warn the user
            let alert = NSAlert.init()
            alert.messageText = "You have unapplied changed?"
            alert.informativeText = "Do you wish to apply the changes you have made before closing the Configure window?"
            alert.addButton(withTitle: "Yes")
            alert.addButton(withTitle: "No")
            alert.beginSheetModal(for: self.configureWindow!) { (selection) in
                if selection == NSApplication.ModalResponse.alertFirstButtonReturn {
                    // The user said yes, so add MNU to the login items system preference
                    self.doSave(sender: nil)
                }

                self.configureWindow!.close()
            }

            return false
        }

        return true
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
        menuItemsCountText.stringValue = "Menu has \(countText) \(itemText) visible out of \(total)"
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
}
