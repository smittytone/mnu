
/*
    AddUserItemPopoverController.swift
    MNU

    Created by Tony Smith on 22/08/2019.
    Copyright © 2023 Tony Smith. All rights reserved.

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


final class AddUserItemPopoverController: NSViewController,
                                          NSCollectionViewDataSource,
                                          NSCollectionViewDelegate {

    // MARK: - UI Outlets
    
    @IBOutlet weak var collectionView: NSCollectionView!
    
    
    // MARK: - Public Class Properties
    
    var icons: NSMutableArray = NSMutableArray.init()
    var button: AddUserItemIconButton = AddUserItemIconButton()
    
    
    // MARK: - Private Class Properties
    
    private var count: Int = 0
    private var tooltips: [String] = []
    

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {

        super.viewDidLoad()

        // Add icon tooltips
        self.tooltips.append("Hash Bang")
        self.tooltips.append("Bash")
        self.tooltips.append("Z Shell")
        self.tooltips.append("Code")
        self.tooltips.append("Git")

        self.tooltips.append("Python")
        self.tooltips.append("Node")
        self.tooltips.append("AppleScript")
        self.tooltips.append("TypeScript")
        self.tooltips.append("CoffeeScript")

        self.tooltips.append("GitHub")
        self.tooltips.append("GitLab")
        self.tooltips.append("Homebrew")
        self.tooltips.append("Docker")
        self.tooltips.append("PHP")

        self.tooltips.append("Web")
        self.tooltips.append("Cloud")
        self.tooltips.append("Document")
        self.tooltips.append("Folder")
        self.tooltips.append("Application")

        self.tooltips.append("Settings")
        self.tooltips.append("Sync")
        self.tooltips.append("Power")
        self.tooltips.append("Mac")
        self.tooltips.append("X: The Unknown")

        // Configure the collection view
        configureCollectionView()
    }


    override func viewDidAppear() {

        super.viewDidAppear()

        // Clear the current selection and select the icon that matches the one
        // shown by the host view's icon button
        collectionView.deselectAll(self)
        let set: Set<IndexPath> = [IndexPath.init(item: button.index, section: 0)]
        collectionView.selectItems(at: set,
                                   scrollPosition: NSCollectionView.ScrollPosition.top)
    }


    private func configureCollectionView() {

        // Configure the collection view's flow layout manager
        
        let gridLayout: NSCollectionViewGridLayout = NSCollectionViewGridLayout.init()
        gridLayout.maximumItemSize = NSMakeSize(64, 64)
        gridLayout.minimumItemSize = NSMakeSize(64, 64)
        gridLayout.maximumNumberOfRows = 5
        gridLayout.maximumNumberOfColumns = 5
        gridLayout.minimumInteritemSpacing = 0.0
        gridLayout.minimumLineSpacing = 0.0
        gridLayout.margins = NSEdgeInsetsMake(4.0, 4.0, 4.0, 4.0)

        // Add the grid layout to the collection view and configure the collection view
        self.collectionView.collectionViewLayout = gridLayout
        self.collectionView.layer?.backgroundColor = NSColor.textBackgroundColor.cgColor
        self.collectionView.isSelectable = true
        self.collectionView.allowsEmptySelection = true
        view.wantsLayer = true
    }


    // MARK: - NSCollectionViewDelegate Functions

    func numberOfSections(in collectionView: NSCollectionView) -> Int {

        // Only one section in this collection
        
        return 1
    }


    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {

        // Just return the number of icons we have
        
        return self.icons.count
    }


    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {

        // Create (or retrieve) an AddUserItemCollectionViewItem instance and configure it
        
        let item: NSCollectionViewItem = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "AddUserItemCollectionViewItem"),
                                                                 for: indexPath)
        guard let collectionViewItem: AddUserItemCollectionViewItem = item as? AddUserItemCollectionViewItem else { return item }
        collectionViewItem.image = self.icons.object(at: count) as? NSImage
        collectionViewItem.index = self.count
        collectionViewItem.view.toolTip = self.tooltips[self.count]

        // Increase the icon index
        self.count += 1
        if self.count == self.icons.count {
            self.count = 0
        }

        return item
    }


    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {

        // Identify the selected icon and notify the parent AddUserItemViewController so that it can
        // update its icon button (which triggers the popup containing this collection)
        
        for index in indexPaths {
            if let obj: NSCollectionViewItem = collectionView.item(at: index) {
                // Send the selected item's index to the AddUserItemViewController
                let item = obj as! AddUserItemCollectionViewItem
                let nc: NotificationCenter = NotificationCenter.default
                nc.post(name: NSNotification.Name(rawValue: "com.bps.mnu.select-image"),
                        object: NSNumber.init(value: item.index))
            }
        }
    }

}
