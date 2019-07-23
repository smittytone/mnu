
//  MNUitem.swift
//  MNU
//
//  Created by Tony Smith on 05/07/2019.
//  Copyright © 2019 Tony Smith. All rights reserved.


import Cocoa


class MNUitem: NSObject {

    // MARK: - Properties

    var title: String = ""              // The name of the item in the menu
    var type: Int = -1                  // The type of the item: script or switch
    var code: Int = -1                  // What kind of script or switch is it
    var index: Int = -1                 // The location of the item in the menu
    var controller: Any? = nil          // The item's managing view controller
    var script: String = ""             // For user items, the bash command it will run
    var isNew: Bool = false             // Set to true when a user item is added

}
