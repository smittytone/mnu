
/*
    AddUserItemCollectionView.swift
    MNU

    Created by Tony Smith on 28/08/2019.
    Copyright © 2024 Tony Smith. All rights reserved.

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


final class AddUserItemCollectionView: NSView {

    // MARK: - Public Class Properties

    var isSelected: Bool = false


    // MARK: - Graphics Functions

    override func draw(_ dirtyRect: NSRect) {

        super.draw(dirtyRect)

        if let gc: NSGraphicsContext = NSGraphicsContext.current {
            // Lock the context
            gc.saveGraphicsState()

            // Set the colours we'll be using - just use fill so we
            // get colour coming through the image
            if self.isSelected {
                NSColor.controlAccentColor.setFill()
            } else {
                NSColor.clear.setFill()
            }

            // Make the circle
            let rect: NSRect = NSMakeRect(0, 0, 64, 64)
            let highlightCircle: NSBezierPath = NSBezierPath()
            highlightCircle.lineWidth = 4.0
            highlightCircle.appendOval(in: rect)
            highlightCircle.fill()

            // Unlock the context
            gc.restoreGraphicsState()
        }
    }
    
}
