
//  MenuItemViewController.swift
//  MNU
//
//  Created by Tony Smith on 04/07/2019.
//  Copyright © 2019 Tony Smith. All rights reserved.


import Cocoa

class MenuItemViewController: NSViewController {


    @IBOutlet weak var viewSwitch: NSButton!
    @IBOutlet weak var viewText: NSTextField!


    var text: String = ""
    var state: Bool = false
    var action: Selector? = nil


    override func viewDidLoad() {

        super.viewDidLoad()

        viewText.stringValue = self.text
        viewSwitch.state = self.state ? NSControl.StateValue.on : NSControl.StateValue.off
        viewSwitch.action = self.action
    }

}
