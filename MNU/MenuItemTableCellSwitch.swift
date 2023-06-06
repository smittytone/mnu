//
//  MenuItemTableCellSwitch.swift
//  MNU
//
//  Created by Tony Smith on 06/06/2023.
//  Copyright © 2023 Tony Smith. All rights reserved.
//


import Foundation
import Cocoa


final class MenuItemTableCellSwitch: NSSwitch {

    // Subclass in order to add a property that points to the button's parent menu item
    // This is used in the table of menu items presented by the Configure Window

    var menuItem: MenuItem? = nil
}
