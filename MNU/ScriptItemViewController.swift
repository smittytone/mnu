
//  ScriptItemViewController.swift
//  MNU
//
//  Created by Tony Smith on 04/07/2019.
//  Copyright © 2019 Tony Smith. All rights reserved.


import Cocoa

class ScriptItemViewController: NSViewController {


    @IBOutlet weak var itemButton: NSButton!
    @IBOutlet weak var itemText: NSTextField!
    @IBOutlet weak var itemImage: NSImageView!
    @IBOutlet weak var itemProgress: NSProgressIndicator!


    var text: String = ""
    var state: Bool = false
    var action: Selector? = nil
    var onImageName: String = ""
    var offImageName: String = ""


    override func viewDidLoad() {

        super.viewDidLoad()

        self.itemText.stringValue = self.text
        self.itemButton.action = self.action
        self.itemProgress.stopAnimation(nil)
        setImage(isOn: self.state)
    }


    func setImage(isOn: Bool) {

        // Switch the image based on the value of 'isOn':
        // If 'isOn' is true, use 'onImage', otherwise use 'offImage'
        self.itemImage.image = NSImage.init(named: (isOn ? self.onImageName : self.offImageName))
        self.itemImage.needsDisplay = true
    }
    
}
