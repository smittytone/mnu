
//  SwitchItemViewController.swift
//  MNU
//
//  Created by Tony Smith on 04/07/2019.
//  Copyright © 2019 Tony Smith. All rights reserved.


import Cocoa

class SwitchItemViewController: NSViewController {


    @IBOutlet weak var itemSwitch: NSButton!
    @IBOutlet weak var itemText: NSTextField!
    @IBOutlet weak var itemImage: NSImageView!


    var text: String = ""
    var state: Bool = false
    var action: Selector? = nil
    var onImageName: String = ""
    var offImageName: String = ""


    override func viewDidLoad() {

        super.viewDidLoad()

        self.itemText.stringValue = self.text
        self.itemSwitch.state = self.state ? NSControl.StateValue.on : NSControl.StateValue.off
        self.itemSwitch.action = self.action
        setImage(isOn: self.state)
    }


    func setImage(isOn: Bool) {

        // Switch the image based on the value of 'isOn':
        // If 'isOn' is true, use 'onImage', otherwise use 'offImage'
        self.itemImage.image = NSImage.init(named: (isOn ? self.onImageName : self.offImageName))
        self.itemImage.needsDisplay = true
    }
}
