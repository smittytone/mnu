
/*
 AddUserItemButton.swift
 MNU

 Created by Tony Smith on 22/08/2019.
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


class AddUserItemIconButton: NSButton {

    // MARK: - Class Properties
    // 'index' is the index of the button's icon within the 'icons' array
    // 'icons' is an array of NSImages for the backpack item icons
    // NOTE We use NSMutableArray so we can set the value of 'icons' as a reference
    var index: Int = 1
    var icons: NSMutableArray = NSMutableArray.init()


    // MARK: - Lifecycle Functions

    override func awakeFromNib() {

        // Set up notifications
        // 'select.image' is sent by the popover controller (AddUserItemViewController) when an icon is selected
        let nc = NotificationCenter.default
        nc.addObserver(self,
                       selector: #selector(setButton),
                       name: NSNotification.Name(rawValue: "select.image"),
                       object: nil)
    }


    // MARK: - Misc Functions

    @objc func setButton(_ note: Notification) {

        // When we receive a notification from the popover controller that an icon has been selected,
        // we come here and set the button's image to that icon
        let obj = note.object

        if obj != nil {
            // Decode the notifiction object
            let array = obj as! NSMutableArray
            let sender = array.object(at: 1) as! AddUserItemIconButton

            // Only change the icon of the button that was actually clicked on
            if sender == self {
                let item = array.object(at: 0) as! AddUserItemCollectionViewItem
                if let image = icons.object(at: item.index) as? NSImage { self.image = image }
                self.index = item.index
            }
        }
    }
}
