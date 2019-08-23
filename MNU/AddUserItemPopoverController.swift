
//
//  AddUserItemPopoverController.swift
//  MNU
//
//  Created by Tony Smith on 22/08/2019.
//  Copyright © 2019 Tony Smith. All rights reserved.
//


import Cocoa


class AddUserItemPopoverController: NSViewController,
                                    NSCollectionViewDataSource,
                                    NSCollectionViewDelegate {

    @IBOutlet weak var collectionView: NSCollectionView!

    var icons: NSMutableArray = NSMutableArray.init()
    var tooltips: [String] = []
    var count: Int = 0
    var button: AddUserItemIconButton = AddUserItemIconButton()


    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {

        super.viewDidLoad()

        // Add icon tooltips
        self.tooltips.append("Generic script")
        self.tooltips.append("Brew script")
        self.tooltips.append("Git script")
        self.tooltips.append("Python script")
        self.tooltips.append("Node script")
        self.tooltips.append("Rust script")
        self.tooltips.append("Bash script")
        self.tooltips.append("AppleScript")

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


    func configureCollectionView() {

        // Configure the collection view's flow layout manager
        let gridLayout = NSCollectionViewGridLayout.init()
        gridLayout.maximumItemSize = NSMakeSize(28, 28)
        gridLayout.minimumItemSize = NSMakeSize(28, 28)
        gridLayout.maximumNumberOfRows = 4
        gridLayout.maximumNumberOfColumns = 4
        gridLayout.minimumInteritemSpacing = 2.0

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
        let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "AddUserItemCollectionViewItem"),
                                           for: indexPath)
        guard let collectionViewItem = item as? AddUserItemCollectionViewItem else { return item }
        collectionViewItem.image = self.icons.object(at: count) as? NSImage
        collectionViewItem.index = self.count
        collectionViewItem.view.toolTip = self.tooltips[self.count]

        // Increase the icon index
        self.count += 1
        if self.count == self.icons.count { self.count = 0 }

        return item
    }


    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {

        // Identify the selected icon and notify the parent AddUserItemViewController so that it can
        // update its icon button (which triggers the popup containing this collection)
        for index in indexPaths {
            if let obj = collectionView.item(at: index) {
                // Send the selected item's index to the AddUserItemViewController
                let item = obj as! AddUserItemCollectionViewItem
                let nc = NotificationCenter.default
                nc.post(name: NSNotification.Name(rawValue: "com.bps.mnu.select-image"),
                        object: NSNumber.init(value: item.index))
            }
        }
    }

}
