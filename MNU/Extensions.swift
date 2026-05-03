/*
    Extensions.swift
    MNU

    Created by Tony Smith on 01/10/2019.
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


extension URL {
    
    func unixpath() -> String {
        
        return self.absoluteString.replacingOccurrences(of: "file://", with: "")
    }
}


extension NSImage {

    /**
     Return a copy of the image in the specified size.

     - Parameters
        - newSize: The chosen size.

     - Returns The resized version of the image, or `nil` on error.
     */
    func resize(to newSize: NSSize) -> NSImage? {

        if let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil,
                                         pixelsWide: Int(newSize.width),
                                         pixelsHigh: Int(newSize.height),
                                         bitsPerSample: 8,
                                         samplesPerPixel: 4,
                                         hasAlpha: true,
                                         isPlanar: false,
                                         colorSpaceName: .calibratedRGB,
                                         bytesPerRow: 0,
                                         bitsPerPixel: 0) {
            bitmap.size = newSize
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
            draw(in: NSRect(x: 0, y: 0, width: newSize.width, height: newSize.height), from: .zero, operation: .copy, fraction: 1.0)
            NSGraphicsContext.restoreGraphicsState()

            let resizedImage = NSImage(size: newSize)
            resizedImage.addRepresentation(bitmap)
            return resizedImage
        }

        return nil
    }


    /**
     Generated a negative version, ie. inverted colours, of the image.

     - Returns An inverted NSImage, or the image itself.
     */
    func inverted() -> NSImage {

        guard let cgImage = self.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return self
        }

        let ciImage = CIImage(cgImage: cgImage)
        guard let filter = CIFilter(name: "CIColorInvert") else {
            return self
        }

        filter.setValue(ciImage, forKey: kCIInputImageKey)
        guard let outputImage = filter.outputImage else {
            return self
        }

        guard let outputCgImage = outputImage.toCGImage() else {
            return self
        }

        return NSImage(cgImage: outputCgImage, size: self.size)
    }


    /**
     Generate a version of the image suitable for display in light more or dark mode.
     The image is always a template, ie. black + clear.
     
     - Returns The appropriately moded image.
     */
    func modedImage() -> NSImage {

        return NSImage(size: self.size,
                       flipped: false,
                       drawingHandler: { rect in
            
            // Get the current mode (dark or light)
            let mode = NSAppearance.currentDrawing()
            if mode.bestMatch(from: [NSAppearance.Name.aqua, NSAppearance.Name.darkAqua]) == .aqua {
                // Draw the black image (it's a template)
                self.draw(in: rect)
            } else {
                // Convert the black image to white and then drae
                self.inverted().draw(in: rect)
            }
                
            return true
        })
    }
}


fileprivate extension CIImage {

    /**
     Convert the CIImage to a CGImage.

     - Returns The image's CGImage equivalent, or `nil` on error.
     */
    func toCGImage() -> CGImage? {
        let context = CIContext(options: nil)
        if let cgImage = context.createCGImage(self, from: self.extent) {
            return cgImage
        }
        
        return nil
    }
}


extension NSApplication {

    /**
     Indicate whether the app is in Light mode or not.

     - Returns `true` if the Mac is in light mode, otherwise `false`.
     */
    func isMacInLightMode() -> Bool {
        
        return (self.effectiveAppearance.name.rawValue == "NSAppearanceNameAqua")
    }
}


extension String {
    
    /**
     Replace substrings within a String, using Strings.

     - Returns A copy of the String including the replacements.
     */
    func replace(_ base: String, with: String) -> String {
        return self.replacingOccurrences(of: base, with: with, options: .literal, range: nil)
    }
}


extension NSAttributedString {

    /**
     Return the width of the rendered string in points.
     */
    var width: CGFloat {
        let rectA = boundingRect(
          with: NSSize(width: Double.infinity, height: Double.infinity),
          options: [.usesLineFragmentOrigin]
        )

        let textStorage = NSTextStorage(attributedString: self)
        let textContainer = NSTextContainer()
        let layoutManager = NSLayoutManager()

        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        textContainer.lineFragmentPadding = 0.0
        layoutManager.glyphRange(for: textContainer)

        let rectB = layoutManager.usedRect(for: textContainer)
        return ceil(max(rectA.width, rectB.width))
    }
}
