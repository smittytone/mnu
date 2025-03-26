
/*
    MenuItem.swift
    MNU

    Created by Tony Smith on 05/07/2019.
    Copyright © 2025 Tony Smith. All rights reserved.

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


enum MNUItemType: Int {
    case `switch`       = 0
    case script
    case open
    case separator
    case unknown        = -1
}



final class MenuItem: NSObject,
                      NSCopying {

    // MARK: - Public Class Properties

    var title: String = ""                              // The name of the item in the menu
    var type: MNUItemType = .unknown                    // The type of the item: script or switch
    var code: Int = MNU_CONSTANTS.ITEMS.MISC.NO_ITEM    // What kind of script or switch is it
    var script: String = ""                             // For user items, the bash command it will run
    var isNew: Bool = false                             // Set to true when a user item is added
    var isHidden: Bool = false                          // Set to true when a switch item is hidden by the user
    var iconIndex: Int = 0                              // Icon reference value (where applicable)
    // FROM 1.2.2
    var isDirect: Bool = false                          // Does the command not appear in the Terminal?
    // FROM 1.7.0
    var keyEquivalent: String = ""                      // Menu key equivalent
    var keyModFlags: UInt = 0                           // Modifier key field
    var uuid: String = UUID().uuidString                // Unique item ID
    // FROM 2.0.0
    var customImageId: String = ""                      // Custom menu image ID
    var showDirectOutput: Bool = false                  // Log output from direct command


    // MARK: NSCopying Functions

    func copy(with zone: NSZone? = nil) -> Any {
        
        let itemCopy = MenuItem()
        itemCopy.title = self.title
        itemCopy.type = self.type
        itemCopy.code = self.code
        itemCopy.script = self.script
        itemCopy.isNew = self.isNew
        itemCopy.isHidden = self.isHidden
        itemCopy.iconIndex = self.iconIndex
        // FROM 1.2.2
        itemCopy.isDirect = self.isDirect
        // FROM 1.7.0
        itemCopy.keyEquivalent = self.keyEquivalent
        itemCopy.keyModFlags = self.keyModFlags
        itemCopy.uuid = self.uuid
        // FROM 2.0.0
        itemCopy.customImageId = self.customImageId
        itemCopy.showDirectOutput = self.showDirectOutput
        return itemCopy
    }
    
    
    /**
     Convert the menu item to a JSON string.
     
     - Returns The JSON string
     */
    func encode() throws -> String {
        
        let result = Serializer.jsonize(self)
        guard !result.isEmpty else { throw Serializer.error.BadSingleSerialization }
        return result
    }
    
    
    /**
     Create a new instance from a JSON string.
     
     - Parameters
        - json: The string from which to decode to MenuItem.
     
     - Returns The list of menu items, or a thrown error.
     */
    static func decode(_ json: String) throws -> MenuItem {
        
        let result = Serializer.dejsonize(json)
        guard let realResult = result else { throw Serializer.error.BadSingleDeserialization }
        return realResult

    }
}
