
//  ButtonViewController.swift
//  MNU
//
//  Created by Tony Smith on 04/07/2019.
//  Copyright © 2019 Tony Smith. All rights reserved.


import Cocoa

class ButtonViewController: NSViewController {


    @IBOutlet weak var viewButton: NSButton!
    @IBOutlet weak var viewText: NSTextField!
    @IBOutlet weak var viewImage: NSImageView!
    @IBOutlet weak var viewProgress: NSProgressIndicator!


    var text: String = ""
    var state: Bool = false
    var action: Selector? = nil
    var onImageName: String = ""
    var offImageName: String = ""


    override func viewDidLoad() {

        super.viewDidLoad()

        self.viewText.stringValue = self.text
        self.viewButton.action = self.action
        self.viewProgress.stopAnimation(nil)
        setImage(isOn: self.state)
    }


    func setImage(isOn: Bool) {

        // Switch the image based on the value of 'isOn':
        // If 'isOn' is true, use 'onImage', otherwise use 'offImage'
        self.viewImage.image = NSImage.init(named: (isOn ? self.onImageName : self.offImageName))
        self.viewImage.needsDisplay = true
    }

}
