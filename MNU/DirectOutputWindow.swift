
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
    @IBOutlet weak var outputScrollView: NSScrollView!
    
    // MARK: - Public Properties
    
    public var textAttributes: [NSAttributedString.Key : Any]? = nil
    
    
    // MARK: - Private Properties
    
    private var backingForegroundColour: NSColor = .cyan
    
    
    // MARK: - Window Preparation Functions
    
    public func prepareForOutput(_ subtitle: String, _ isLight: Bool) {
        
        if self.textAttributes == nil {
            let outputFont = NSFont.monospacedSystemFont(ofSize: 13.0, weight: .semibold)
            self.textAttributes = [
                .font: outputFont,
                .foregroundColor: isLight ? NSColor.purple : NSColor.green
            ]
        } else {
            self.textAttributes?[.foregroundColor] = isLight ? NSColor.purple : NSColor.green
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
            textStore.append(NSAttributedString(string: text, attributes: self.textAttributes))
        }
    }
    
    
    public func appendRule() {
        
        if let textStore = self.outputTextView.textStorage {
            if var ruleAtts = self.textAttributes {
                ruleAtts[.strikethroughStyle] = NSUnderlineStyle.thick.rawValue
                ruleAtts[.strikethroughColor] = NSColor.labelColor
                textStore.append(NSAttributedString(string: "\n\u{00A0}\u{0009}\u{00A0}\n\n", attributes: ruleAtts))
            }
        }
    }
    
}
