
//  ConfigureWindowViewController.swift
//  MNU
//
//  Created by Tony Smith on 05/07/2019.
//  Copyright © 2019 Tony Smith. All rights reserved.


import Cocoa


class ConfigureViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {

    // MARK: - UI Outlets

    @IBOutlet weak var menuItemsTableView: NSTableView!
    @IBOutlet weak var aivc: AddUserItemViewController!


    // MARK: - Class Properties

    var items: MNUitemList? = nil
    let mnuPasteboardType = NSPasteboard.PasteboardType(rawValue: "com.bps.mnu.pb")
    var hasChanged: Bool = false


    // MARK: - Lifecycle Functions

    override func viewDidLoad() {

        super.viewDidLoad()

        // Set up the table view for drag and drop reordering
        self.menuItemsTableView.registerForDraggedTypes([mnuPasteboardType])

        // Set the add user item view controller's parent window
        self.aivc.parentWindow = self.view.window!

        // Watch for notifications of changes sent by the add user item view controller
        let nc = NotificationCenter.default
        nc.addObserver(self,
                       selector: #selector(self.processNewItem),
                       name: NSNotification.Name(rawValue: "com.bps.mnu.item-added"),
                       object: nil)
    }


    func show() {

        // Show the controller's own window
        self.view.window!.makeKeyAndOrderFront(self)
        self.view.window!.orderFrontRegardless()
    }

    
    // MARK: - Action Functions

    @IBAction @objc func doCancel(sender: Any?) {

        // Just close the configure window
        self.view.window!.close()
    }


    @IBAction @objc func doSave(sender: Any?) {

        // If any changes have been made to the item list, inform the app delegate
        if hasChanged {
           let nc = NotificationCenter.default
            nc.post(name: NSNotification.Name(rawValue: "com.bps.mnu.list-updated"),
                    object: self)
        }

        // Close the configure window
        self.view.window!.close()
    }

    
    @IBAction @objc func doNewScriptItem(sender: Any?) {

        // Tell the add user item view controller to display its sheet
        self.aivc.showSheet()
    }


    @objc func doShowHideSwitch(sender: Any) {

        let button: MenuItemTableCellButton = sender as! MenuItemTableCellButton
        if let item: MNUitem = button.menuItem {
            item.isHidden = !item.isHidden
            self.hasChanged = true
            self.menuItemsTableView.reloadData()
        }
    }


    @objc func doDeleteScript(sender: Any) {

    }


    // MARK: - Notification Handlers

    @objc func processNewItem() {

        if aivc != nil {
            if let item: MNUitem = aivc!.newMNUitem {
                self.items!.items.append(item)
                self.menuItemsTableView.reloadData()
                self.hasChanged = true
            }
        }
    }

    
    // MARK: - TableView Data Source Functions

    func numberOfRows(in tableView: NSTableView) -> Int {

        if let items = self.items {
            return items.items.count
        }

        return 0
    }


    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {

        if let items = self.items {
            let item: MNUitem = items.items[row]
            let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "mnu-item-cell"), owner: self) as? MenuItemTableCellView
            if cell != nil {
                if item.type == MNU_CONSTANTS.TYPES.SWITCH || (item.type == MNU_CONSTANTS.TYPES.SCRIPT && item.code != MNU_CONSTANTS.ITEMS.SCRIPT.USER) {
                    // This is a built-in switch, so change the button to 'show/hide'
                    cell!.button.title = item.isHidden ? "Show" : "Hide"
                    cell!.button.action = #selector(self.doShowHideSwitch(sender:))
                }

                if item.type == MNU_CONSTANTS.TYPES.SCRIPT && item.code == MNU_CONSTANTS.ITEMS.SCRIPT.USER {
                    // This is a built-in switch, so change the button to 'show/hide'
                    cell!.button.title = "Delete"
                    cell!.button.action = #selector(self.doDeleteScript(sender:))
                }
                
                cell!.title.stringValue = item.title
                cell!.button.menuItem = item
                return cell
            }
        }

        return nil
    }


    func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {

        if let items = self.items {
            let item: MNUitem = items.items[row]
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
        if let items = self.items {
            for i in 0..<items.items.count {
                let anItem: MNUitem = items.items[i]
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
            let anItem: MNUitem = items.items[originalRow]
            items.items.remove(at: originalRow)
            items.items.insert(anItem, at: newRow)

            hasChanged = true
            return true
        }

        return false
    }
}
