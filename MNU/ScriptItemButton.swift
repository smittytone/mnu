
/*
 ScriptItemButton.swift
 MNU
 
 Created by Tony Smith on 06/08/2019.
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


class ScriptItemButton: NSButton {
    
    // MARK: - App Properties
    var onImageName: String = ""
    var offImageName: String = ""
    
    
    // MARK: - Lifecycle Functions
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        // Set up a tracking area over the button so we can flip its
        // image on mouse entry/exit
        let trackingArea = NSTrackingArea.init(rect: self.bounds,
                                           options: [.activeAlways, .mouseEnteredAndExited],
                                           owner: self,
                                           userInfo: nil)
        self.addTrackingArea(trackingArea)
        
        // Watch for menu closing so we can remove the highlight
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.enterBackground),
                                               name: NSNotification.Name.init(rawValue: "com.bps.mnu.will-background"),
                                               object: nil)
    }
    
    
    @objc func enterBackground() {
        
        // Clear the button's highlight
        self.image = NSImage.init(named: self.offImageName)
    }
    
    
    // MARK: - Mouse Event Handler Functions
    
    override func mouseEntered(with event: NSEvent) {
        
        // Set the button's image to 'hightlight'
        self.image = NSImage.init(named: self.onImageName)
    }
    
    
    override func mouseExited(with event: NSEvent) {
        
        // Clear the button's highlight
        self.image = NSImage.init(named: self.offImageName)
    }
}
