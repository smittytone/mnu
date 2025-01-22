
/*
    DirectOutputWindow.swift
    MNU

    Created by Tony Smith on 22/01/2025.
    Copyright © 2025 Tony Smith. All rights reserved.

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

import AppKit


class DirectOutputWindow: NSPanel {
    
    // MARK: - UI Properties
    
    @IBOutlet weak var outputTextView: NSTextView!
    
    
    // MARK: - Public Properties
    
    public var textAttrributes: [NSAttributedString.Key : Any]? = nil
    public var foregroundColour: NSColor {
        
        set {
            self.backingForegroundColour = newValue
            
            // Update the displayed view's attributed string
            if self.outputTextView.attributedString().length != 0 {
                if var textAtts = self.textAttrributes {
                    textAtts[.foregroundColor] = newValue
                    
                    if let textStore = self.outputTextView.textStorage {
                        textStore.setAttributes(textAtts, range: NSMakeRange(0, self.outputTextView.attributedString().length))
                    }
                }
            }
        }
        
        get {
            return self.backingForegroundColour
        }
    }
    
    
    // MARK: - Private Properties
    
    private var backingForegroundColour: NSColor = .cyan
    
    
    // MARK: - Window Preparation Functions
    
    public func prepareForOutput(_ subtitle: String) {
        
        // Set up the text view for fresh content
        self.outputTextView.string = ""
        
        if self.textAttrributes == nil {
            let outputFont = NSFont.monospacedSystemFont(ofSize: 13.0, weight: .semibold)
            self.textAttrributes = [
                .font: outputFont,
                .foregroundColor: self.backingForegroundColour
            ]
        } else {
            self.textAttrributes?[.foregroundColor] = self.backingForegroundColour
        }
        
        // Set up the window itself
        if !self.isVisible {
            positionBottomLeft()
        }
        
        self.subtitle = subtitle
        self.makeKeyAndOrderFront(self)
    }
    
    
    public func positionBottomLeft() {
         
         if let screenSize = screen?.visibleFrame.size {
             self.setFrameOrigin(NSPoint(x: 0.0, y: screenSize.height-frame.size.height - self.frame.height))
         }
     }
    
    
    public func appendText(_ text: String) {
        
        if let textStore = self.outputTextView.textStorage {
            textStore.append(NSAttributedString.init(string: text, attributes: self.textAttrributes))
        }
    }
    
}
