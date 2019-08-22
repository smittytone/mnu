
/*
 AddUserItemCollectionViewItem.swift
 MNU

 Created by Tony Smith on 22/08/2019.
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


class AddUserItemCollectionViewItem: NSCollectionViewItem {

    var index: Int = -1

    var image: NSImage? {
        didSet {
            guard isViewLoaded else { return }

            if let image = image {
                imageView?.image = image
            } else {
                imageView?.image = nil
            }
        }
    }


    override var isSelected: Bool {

        didSet {
            view.layer?.borderWidth = isSelected ? 2.0 : 0.0
        }
    }


    override func viewDidLoad() {

        super.viewDidLoad()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.clear.cgColor
        view.layer?.borderColor = NSColor.controlAccentColor.cgColor
        view.layer?.borderWidth = 0.0
    }

}
