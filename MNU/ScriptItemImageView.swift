
/*
 ScriptItemImageView.swift
 MNU

 Created by Tony Smith on 08/08/2019.
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


class ScriptItemImageView: NSImageView {

    // MARK: - App Properties
    
    var controller: ScriptItemViewController? = nil


    // MARK: - Lifecycle Functions

    override func awakeFromNib() {

        super.awakeFromNib()

        // Set up a tracking area over the imae so we can track clicks
        let trackingArea = NSTrackingArea.init(rect: self.bounds,
                                               options: [.activeAlways, .mouseEnteredAndExited],
                                               owner: self,
                                               userInfo: nil)
        self.addTrackingArea(trackingArea)
    }

    
    override func mouseUp(with event: NSEvent) {

        // Make a click in the image view work like a click on the superview's switch
        if let controller = self.controller {
            controller.itemButton.performClick(controller)
        }
    }

}
