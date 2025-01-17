
/*
    Generic.swift
    MNU

    Created by Tony Smith on 01/10/2019.
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
        let data: Data = try Data.init(contentsOf: imageUrl)
        return data
    } catch {
        print(error)
    }
    
    return nil
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
