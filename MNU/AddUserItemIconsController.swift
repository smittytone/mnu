//
//  AddUserItemIconsController.swift
//  MNU
//
//  Created by Tony Smith on 22/08/2019.
//  Copyright © 2019 Tony Smith. All rights reserved.
//

import Cocoa

class AddUserItemIconsController: NSViewController,
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

        // Load pack item icons into an array for easy access later
        var image: NSImage? = NSImage.init(named: "logo_generic")
        self.icons.add(image!)
        image = NSImage.init(named: "logo_brew")
        self.icons.add(image!)
        image = NSImage.init(named: "logo_github")
        self.icons.add(image!)
        image = NSImage.init(named: "logo_python")
        self.icons.add(image!)
        image = NSImage.init(named: "logo_node")
        self.icons.add(image!)
        image = NSImage.init(named: "logo_rust")
        self.icons.add(image!)

        image = NSImage.init(named: "logo_github")
        self.icons.add(image!)
        image = NSImage.init(named: "logo_python")
        self.icons.add(image!)

        self.tooltips.append("Generic script")
        self.tooltips.append("Brew script")
        self.tooltips.append("Git script")
        self.tooltips.append("Python script")
        self.tooltips.append("Node script")
        self.tooltips.append("Rust script")

        self.tooltips.append("Git script")
        self.tooltips.append("Python script")

        // Force a crash if the two arrays don't match in size
        assert (self.tooltips.count == self.icons.count)

        // Configure the collection view
        configureCollectionView()
    }


    override func viewDidAppear() {

        super.viewDidAppear()

        // Clear the current selection and set it to the icon of
        // the button the user has clicked on
        collectionView.deselectAll(self)
        let set: Set<IndexPath> = [IndexPath.init(item: button.index, section: 0)]
        collectionView.selectItems(at: set,
                                   scrollPosition: NSCollectionView.ScrollPosition.top)
    }


    // MARK: - CollectionView Functions

    func configureCollectionView() {

        // Configure the collection view's flow layout manager
        let flowLayout = NSCollectionViewFlowLayout()
        flowLayout.itemSize = NSSize(width: 20.0,
                                     height: 20.0)
        flowLayout.sectionInset = NSEdgeInsets(top: 2.0,
                                               left: 2.0,
                                               bottom: 2.0,
                                               right: 2.0)
        flowLayout.minimumInteritemSpacing = 2.0
        flowLayout.minimumLineSpacing = 2.0

        let gridLayout = NSCollectionViewGridLayout.init()
        gridLayout.maximumItemSize = NSMakeSize(28, 28)
        gridLayout.minimumItemSize = NSMakeSize(28, 28)
        gridLayout.maximumNumberOfRows = 4
        gridLayout.maximumNumberOfColumns = 4
        gridLayout.minimumInteritemSpacing = 2.0

        // Add the flow layout to the collection view
        //self.collectionView.collectionViewLayout = flowLayout
        self.collectionView.collectionViewLayout = gridLayout
        self.collectionView.layer?.backgroundColor = NSColor.textBackgroundColor.cgColor
        self.collectionView.isSelectable = true
        self.collectionView.allowsEmptySelection = true
        view.wantsLayer = true
    }


    func numberOfSections(in collectionView: NSCollectionView) -> Int {

        return 1
    }


    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {

        // Just return the number of icons we have
        return self.icons.count
    }


    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {

        let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "AddUserItemCollectionViewItem"),
                                           for: indexPath)
        guard let collectionViewItem = item as? AddUserItemCollectionViewItem else { return item }
        collectionViewItem.image = self.icons.object(at: count) as? NSImage
        collectionViewItem.index = self.count
        collectionViewItem.view.toolTip = self.tooltips[self.count]
        self.count += 1
        if self.count == self.icons.count { self.count = 0 }
        return item
    }


    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {

        for index in indexPaths {
            let obj = collectionView.item(at: index)
            if obj != nil {
                // Create an array instance to hold the data we need to send
                let array: NSMutableArray = NSMutableArray.init()
                let item = obj as! AddUserItemCollectionViewItem
                array.add(item)
                array.add(self.button)

                // Send the selected item to the buttons via a notifications
                let nc = NotificationCenter.default
                nc.post(name: NSNotification.Name(rawValue: "select.image") ,
                        object: array)
            }
        }
    }

    
}
