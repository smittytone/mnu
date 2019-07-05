
//  ConfigureWindowViewController.swift
//  MNU
//
//  Created by Tony Smith on 05/07/2019.
//  Copyright © 2019 Tony Smith. All rights reserved.


import Cocoa


class ConfigureWindowViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {


    @IBOutlet weak var menuItemsTableView: NSTableView!
    @IBOutlet weak var swtichItemsPopup: NSPopUpButton!


    var itemList: ItemList? = nil
    var itemArray: [MNUitem]? = nil
    let mnuPasteboardType = NSPasteboard.PasteboardType(rawValue: "com.bps.mnu.pb")
    var hasChanged: Bool = false

    override func viewDidLoad() {

        super.viewDidLoad()

        self.menuItemsTableView.registerForDraggedTypes([mnuPasteboardType])
    }


    @IBAction @objc func doCancel(sender: Any?) {

        // Just close the window
        self.view.window!.close()
    }


    @IBAction @objc func doSave(sender: Any?) {

        // If any changes have been made, inform the app
        if hasChanged {
            let nc = NotificationCenter.default
            nc.post(name: NSNotification.Name(rawValue: "com.bps.mnu.list-updated"), object: self)
        }

        // Close the Window
        self.view.window!.close()
    }

    
    @IBAction @objc func doNewScriptItem(sender: Any?) {

    }


    // MARK: - TableView Data Source Functions

    func numberOfRows(in tableView: NSTableView) -> Int {

        if let itemList = self.itemList {
            if let items = itemList.items {
                return items.count
            }
        }
        return 0
    }


    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {

        if let itemList = self.itemList {
            if let items = itemList.items {
                let item: MNUitem = items[row] as! MNUitem
                let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "itemTitleCell"), owner: self) as? NSTableCellView
                if cell != nil {
                    cell!.textField?.stringValue = item.title
                    return cell
                }
            }
        }

        return nil
    }


    func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {

        if let itemList = self.itemList {
            if let items = itemList.items {
                let item: MNUitem = items[row] as! MNUitem
                let pasteboardItem = NSPasteboardItem()
                pasteboardItem.setString(item.title, forType: mnuPasteboardType)
                return pasteboardItem
            }
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
            if let items = itemList.items {
                for i in 0..<items.count {
                    let anItem: MNUitem = items[i] as! MNUitem
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
                let anItem: MNUitem = items[originalRow] as! MNUitem
                itemList.items!.remove(at: originalRow)
                itemList.items!.insert(anItem, at: newRow)

                hasChanged = true
                return true
            }
        }

        return false
    }
}
