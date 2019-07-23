
//  ConfigureWindowViewController.swift
//  MNU
//
//  Created by Tony Smith on 05/07/2019.
//  Copyright © 2019 Tony Smith. All rights reserved.


import Cocoa


class ConfigureViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {

    // MARK: - UI Outlets

    @IBOutlet weak var menuItemsTableView: NSTableView!
    @IBOutlet weak var swtichItemsPopup: NSPopUpButton!
    @IBOutlet weak var aivc: AddUserItemViewController!
    @IBOutlet weak var addItemSheet: NSWindow!


    // MARK: - Class Properties

    var itemList: MNUitemList? = nil
    var itemArray: [MNUitem]? = nil
    let mnuPasteboardType = NSPasteboard.PasteboardType(rawValue: "com.bps.mnu.pb")
    var hasChanged: Bool = false


    // MARK: - Lifecycle Functions

    override func viewDidLoad() {

        super.viewDidLoad()

        self.menuItemsTableView.registerForDraggedTypes([mnuPasteboardType])

        let nc = NotificationCenter.default
        nc.addObserver(self,
                       selector: #selector(self.processNewItem),
                       name: NSNotification.Name(rawValue: "com.bps.mnu.item-added"),
                       object: nil)
    }


    // MARK: - Action Functions

    @IBAction @objc func doCancel(sender: Any?) {

        // Clear any new items
        for i in 0..<self.itemList!.items.count {
            let item: MNUitem = self.itemList!.items[i]
            if item.isNew {
                self.itemList!.items.remove(at: i)
            }
        }

        // Just close the window
        self.view.window!.close()
    }


    @IBAction @objc func doSave(sender: Any?) {

        // If any changes have been made, inform the app
        if hasChanged {
            // Update any new items: mark them as no longer new
            for i in 0..<self.itemList!.items.count {
                let item: MNUitem = self.itemList!.items[i]
                if item.isNew {
                    item.isNew = false
                }
            }

            // Notify the app delegate
            let nc = NotificationCenter.default
            nc.post(name: NSNotification.Name(rawValue: "com.bps.mnu.list-updated"),
                    object: self)
        }

        // Close the Window
        self.view.window!.close()
    }

    
    @IBAction @objc func doNewScriptItem(sender: Any?) {

        // Show the sheet
        self.aivc.itemText.stringValue = ""
        self.aivc.itemExec.stringValue = ""
        self.view.window!.beginSheet(self.addItemSheet,
                                     completionHandler: nil)
    }


    // MARK: - Notification Handlers

    @objc func processNewItem() {

        if aivc != nil {
            if let item: MNUitem = aivc!.newMNUitem {
                self.itemList!.items.append(item)
                self.menuItemsTableView.reloadData()
                self.hasChanged = true
            }
        }
    }

    
    // MARK: - TableView Data Source Functions

    func numberOfRows(in tableView: NSTableView) -> Int {

        if let itemList = self.itemList {
            return itemList.items.count
        }

        return 0
    }


    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {

        if let itemList = self.itemList {
            let item: MNUitem = itemList.items[row]
            let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "itemTitleCell"), owner: self) as? NSTableCellView
            if cell != nil {
                cell!.textField?.stringValue = item.title
                return cell
            }
        }

        return nil
    }


    func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {

        if let itemList = self.itemList {
            let item: MNUitem = itemList.items[row]
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
        if let itemList = self.itemList {
            for i in 0..<itemList.items.count {
                let anItem: MNUitem = itemList.items[i]
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
            let anItem: MNUitem = itemList.items[originalRow]
            itemList.items.remove(at: originalRow)
            itemList.items.insert(anItem, at: newRow)

            hasChanged = true
            return true
        }

        return false
    }
}
