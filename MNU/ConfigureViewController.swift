
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


class ConfigureViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {

    // MARK: - UI Outlets

    @IBOutlet weak var windowTabView: NSTabView!
    @IBOutlet weak var menuItemsTableView: NSTableView!
    @IBOutlet weak var menuItemsCountText: NSTextField!
    @IBOutlet weak var aivc: AddUserItemViewController!
    @IBOutlet weak var aboutVersionText: NSTextField!


    // MARK: - Class Properties

    var menuItems: MenuItemList? = nil
    var configureWindow: NSWindow? = nil
    let mnuPasteboardType = NSPasteboard.PasteboardType(rawValue: "com.bps.mnu.pb")
    var hasChanged: Bool = false


    // MARK: - Lifecycle Functions

    override func viewDidLoad() {

        super.viewDidLoad()

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
        self.aivc.parentWindow = self.configureWindow!

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
        self.configureWindow!.center()
        self.configureWindow!.makeKeyAndOrderFront(self)
        self.configureWindow!.orderFrontRegardless()
    }

    
    // MARK: - Action Functions

    @IBAction @objc func doCancel(sender: Any?) {

        // The user clicked 'Cancel', so hust close the configure window
        self.configureWindow!.close()
    }


    @IBAction @objc func doSave(sender: Any?) {

        // If any changes have been made to the item list, inform the app delegate
        if self.hasChanged {
            let nc = NotificationCenter.default
            nc.post(name: NSNotification.Name(rawValue: "com.bps.mnu.list-updated"),
                    object: self)
        }

        // Close the Configure window
        self.configureWindow!.close()
    }

    
    @IBAction @objc func doNewScriptItem(sender: Any?) {

        // Tell the Add User Item view controller to display its own sheet as
        // ready to accept a new item
        self.aivc.isEditing = false
        self.aivc.currentMenuItems = self.menuItems
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


    @IBAction @objc func doShowHelp(sender: Any?) {

        // Show the 'Help' via the website
        // TODO create web page
        // TODO provide offline help
        NSWorkspace.shared.open(URL.init(string:"https://smittytone.github.io/mnu/index.html#how-to-configure")!)
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
                if item.type == MNU_CONSTANTS.TYPES.SWITCH || (item.type == MNU_CONSTANTS.TYPES.SCRIPT && item.code != MNU_CONSTANTS.ITEMS.SCRIPT.USER) {
                    // This is a built-in switch, so change the button to 'show/hide'
                    cell!.button.title = item.isHidden ? "Show" : "Hide"
                    cell!.button.action = #selector(self.doShowHideSwitch(sender:))
                    cell!.editButton.isHidden = true
                }

                if item.type == MNU_CONSTANTS.TYPES.SCRIPT && item.code == MNU_CONSTANTS.ITEMS.SCRIPT.USER {
                    // This is a user-created script item, so set the button to 'delete'
                    cell!.button.title = "Delete"
                    cell!.button.action = #selector(self.doDeleteScript(sender:))
                    cell!.editButton.action = #selector(self.doEditScript(sender:))
                    cell!.editButton.menuItem = item
                }
                
                cell!.title.stringValue = item.title
                cell!.button.menuItem = item
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
}
