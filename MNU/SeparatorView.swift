/*
    SeparatorView.swift
    MNU

    Created by Tony Smith on 01/05/2026.
    Copyright © 2026 Tony Smith. All rights reserved.

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


final class SeparatorView: NSView {

    // MARK: - Graphics Functions

    override func draw(_ dirtyRect: NSRect) {

        super.draw(dirtyRect)

        if let gc: NSGraphicsContext = NSGraphicsContext.current {
            // Lock the context
            gc.saveGraphicsState()

            // Draw the dotted line
            NSColor.controlAccentColor.setStroke()

            let patternPtr = UnsafeMutablePointer<CGFloat>.allocate(capacity: 2)
            patternPtr[0] = 2.0
            patternPtr[1] = 2.0

            let pointsPtr = UnsafeMutablePointer<CGPoint>.allocate(capacity: 2)
            pointsPtr[0] = NSPoint(x: 10.0, y: 0.0)
            pointsPtr[1] = NSPoint(x: 358.0, y: 0.0)

            let line = NSBezierPath()
            line.setLineDash(patternPtr, count: 2, phase: 0.0)
            line.appendPoints(pointsPtr, count: 2)
            line.lineWidth = 2.0
            line.stroke()

            // Unlock the context
            gc.restoreGraphicsState()
        }
    }

}
