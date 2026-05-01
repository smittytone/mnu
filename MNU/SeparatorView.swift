//
//  SeparatorView.swift
//  MNU
//
//  Created by Tony Smith on 01/05/2026.
//  Copyright © 2026 Tony Smith. All rights reserved.
//

import AppKit


final class SeparatorView: NSView {

    // MARK: - Graphics Functions

    override func draw(_ dirtyRect: NSRect) {

        super.draw(dirtyRect)

        if let gc: NSGraphicsContext = NSGraphicsContext.current {
            // Lock the context
            gc.saveGraphicsState()

            // Draw the line
            NSColor.controlAccentColor.setFill()
            let line = NSBezierPath()
            line.lineWidth = 1.0
            line.appendRoundedRect(self.bounds, xRadius: 4.0, yRadius: 4.0)
            line.fill()

            // Unlock the context
            gc.restoreGraphicsState()
        }
    }

}
