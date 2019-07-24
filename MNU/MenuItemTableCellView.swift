
//  MNUitemTableCellView.swift
//  MNU
//
//  Created by Tony Smith on 24/07/2019.
//  Copyright © 2019 Tony Smith. All rights reserved.


import Cocoa

class MenuItemTableCellView: NSTableCellView {

    // This table cell view simply has a couple of extra items we want to make accessible
    
    @IBOutlet weak var title: NSTextField!
    @IBOutlet weak var button: MenuItemTableCellButton!
    @IBOutlet weak var editButton: MenuItemTableCellButton!
    
}
