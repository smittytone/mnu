
//  MNUitem.swift
//  MNU
//
//  Created by Tony Smith on 05/07/2019.
//  Copyright © 2019 Tony Smith. All rights reserved.


import Cocoa


class MNUitem: NSObject, NSCopying {

    // MARK: - Properties

    var title: String = ""              // The name of the item in the menu
    var type: Int = -1                  // The type of the item: script or switch
    var code: Int = -1                  // What kind of script or switch is it
    var index: Int = -1                 // The location of the item in the menu
    var controller: Any? = nil          // The item's managing view controller
    var script: String = ""             // For user items, the bash command it will run
    var isNew: Bool = false             // Set to true when a user item is added
    var isHidden: Bool = false          // Set to true when a switch item is hidden by the user


    // MARK: NSCopying Functions

    func copy(with zone: NSZone? = nil) -> Any {

        let itemCopy = MNUitem()
        itemCopy.title = self.title
        itemCopy.type = self.type
        itemCopy.code = self.code
        itemCopy.index = self.index
        itemCopy.script = self.script
        itemCopy.isNew = self.isNew
        itemCopy.isHidden = self.isHidden
        itemCopy.controller = self.controller

        return itemCopy
    }

}
