
/*
    ScriptItemViewController.swift
    MNU

    Created by Tony Smith on 04/07/2019.
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


class ScriptItemViewController: NSViewController {

    // MARK: - UI Outlets
    
    @IBOutlet weak var itemButton: NSButton!
    @IBOutlet weak var itemText: NSTextField!
    @IBOutlet weak var itemImage: NSImageView!
    @IBOutlet weak var itemProgress: NSProgressIndicator!

    
    // MARK: - Class Properties

    var text: String = ""
    var state: Bool = false
    var action: Selector? = nil
    var onImageName: String = ""
    var offImageName: String = ""


    // MARK: - Lifecycle Functions

    override func viewDidLoad() {

        super.viewDidLoad()

        // Set the outlets' values here from the properties set when the view controller
        // was instantiated. This is because the outlets can't be considered to be available
        // until 'viewDidLoad()' is called
        self.itemText.stringValue = self.text
        self.itemButton.action = self.action
        self.itemProgress.stopAnimation(nil)
        setImage(isOn: self.state)
    }


    // MARK: - View Component Control Functions

    func setImage(isOn: Bool) {

        // Switch the image based on the value of 'isOn':
        // If 'isOn' is true, use 'onImage', otherwise use 'offImage'
        self.itemImage.image = NSImage.init(named: (isOn ? self.onImageName : self.offImageName))
        self.itemImage.needsDisplay = true
    }
    
}
