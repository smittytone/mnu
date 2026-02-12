
/*
    Common.swift
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


/*
  Cross-file functions that need not be part of a class.
 */


/**
 Load an image from disk, either a custom image or a stored processed image.
 FROM 2.0.0
 
 - Parameters
    - imageUrl: The file URL of the image (typically from NSOpenPanel).
 
 - Returns The image data, or `nil` on error.
 */
func loadImage(_ imageUrl: URL) -> Data? {
    
    do {
        let data: Data = try Data(contentsOf: imageUrl)
        return data
    } catch {
#if DEBUG
        print(error.localizedDescription)
#else
        NSLog(error.localizedDescription)
#endif
        return nil
    }
}


/**
 Return the path to the image store for a specific file.
 Passing in an empty string will yield the directory.
 FROM 2.0.0
 
 - Returns The file's full URL.
 */
func getImageStoreUrl(_ filename: String) -> URL {
    
    var url = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".config").appendingPathComponent("mnu")
    
    if !filename.isEmpty {
        url = url.appendingPathComponent(filename)
    }
    
    return url
}


/**
 Preset a generic, simple alert with no completion handler.
 
 - Parameters
    - title:   The alert heading.
    - message: The alert body.
    - window:  The window the alert will be modal for.
 */
func showAlert(_ title: String, _ message: String, _ window: NSWindow) {
    
    // Present an alert to warn the user about deleting the Menu Item
    let alert: NSAlert = NSAlert()
    alert.messageText = title
    alert.informativeText = message
    alert.addButton(withTitle: "OK")
    alert.beginSheetModal(for: window, completionHandler: nil)
}


/**
 Check that the named app exists in one of the Mac's possible app locations.

 FROM 1.5.0
 MOVED 2.1.0

 - Parameters
    - appName: The name of the script in the bundle.

 - Returns The app's absolute path including `.app` as an extension, or `nil` on error.
 */
func getAppPath(_ appName: String) -> String? {

    // Various possible Application locations are...
    var basePaths: [String] = ["/Applications", "/Applications/Utilities", "/System/Applications", "/System/Applications/Utilities"]

    // ...and another is...
    let homeAppPath: String = ("~/Applications" as NSString).expandingTildeInPath
    if FileManager.default.fileExists(atPath: homeAppPath) {
        basePaths.append(homeAppPath)
    }

    // Run through the above list and check if the name app is there;
    // if it is, return it
    for basePath: String in basePaths {
        // Build the full app path
        var appPath: String = appName

        // Make sure our temporary full path ends in '.app'
        if !appPath.contains(".app") {
            appPath += ".app"
        }

        // Prefix the temp path with the current app folder
        if !appPath.contains(basePath) {
            appPath = basePath + "/" + appPath
        }

        // Check if the app is there -- if it is, return the full path
        if FileManager.default.fileExists(atPath: appPath) {
            return appPath
        }
    }

    // No match for the named app in any location,
    // so issue a failure note
    return nil
}
