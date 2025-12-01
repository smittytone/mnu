
/*
    AddUserItemViewController.swift
    MNU

    Created by Tony Smith on 24/07/2019.
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
import UniformTypeIdentifiers


final class AddUserItemViewController: NSViewController,
                                       NSTextFieldDelegate,
                                       NSPopoverDelegate,
                                       NSWindowDelegate,
                                       NSOpenSavePanelDelegate {

    // MARK: - UI Outlets

    @IBOutlet var addItemSheet: NSWindow!
    @IBOutlet var itemScriptText: AddUserItemTextField!
    @IBOutlet var menuTitleText: AddUserItemTextField!
    @IBOutlet var textCount: NSTextField!
    @IBOutlet var titleText: NSTextField!
    @IBOutlet var saveButton: NSButton!
    @IBOutlet var iconButton: AddUserItemIconButton!
    @IBOutlet var iconPopoverController: AddUserItemPopoverController!
    // FROM 1.2.0
    @IBOutlet var openCheck: NSButton!
    // FROM 1.2.2
    @IBOutlet var directCheck: NSButton!
    // FROM 1.7.0
    @IBOutlet var modifierKeysSegment: NSSegmentedControl!
    @IBOutlet var keyEquivalentText: AddUserItemKeyTextField!
    // FROM 2.0.0
    @IBOutlet var chooseCustomIconButton: NSButton!
    

    // MARK: - Public Class Properties

    var newMenuItem: MenuItem? = nil
    var currentMenuItems: MenuItemList? = nil
    var parentWindow: NSWindow? = nil
    var isEditing: Bool = false
    // FROM 1.5.0
    var appDelegate: AppDelegate? = nil
    // FROM 2.0.0
    var customIcons: [CustomIcon] = []


    // MARK: - Public Class Properties
    private var iconPopover: NSPopover? = nil
    private var icons: [NSImage] = []
    // FROM 1.5.0
    private var directAlert: NSAlert? = nil
    // FROM 1.7.0
    private var keyFieldEditor: AddUserItemKeyFieldEditor? = nil
    // FROM 2.0.0
    private var hasNewCustomIcon: Bool = false
    
    
    // MARK: - Lifecycle Functions

    override func viewDidLoad() {

        super.viewDidLoad()

        // Set the name length indicator
        self.textCount.stringValue = "\(menuTitleText.stringValue.count)/\(MNU_CONSTANTS.MENU_TEXT_LEN)"

        // Set up the custom script icons - these will be accessed by other objects, including
        // 'iconButton' and 'iconPopoverController'
        makeIconMatrix()

        // Configure the AddUserItemsIconController
        self.iconPopoverController.button = self.iconButton
        self.iconPopoverController.availableIcons = self.icons

        // Set up and confiure the NSPopover
        makePopover()

        // FROM 1.7.0
        self.keyEquivalentText.segment = self.modifierKeysSegment

        // Set up notifications
        // 'com.bps.mnu.select-image' is sent by the AddUserItemViewController when an icon is selected
        let nc: NotificationCenter = NotificationCenter.default
        nc.addObserver(self,
                       selector: #selector(updateButtonIcon(_:)),
                       name: NSNotification.Name(rawValue: MNU_CONSTANTS.NOTIFICATION_IDS.ICON_SELECTED),
                       object: nil)
        
        // FROM 2.0.0
        self.chooseCustomIconButton.toolTip = "Click to select a template image as a menu icon"
    }


    /**
     Build the array of icons that we will use for the popover selector
     // and the button that triggers its appearance.
     */
    private func makeIconMatrix() {
        
        for i in 0..<MNU_CONSTANTS.ICONS.count {
            let image: NSImage? = NSImage(named: "picon_" + MNU_CONSTANTS.ICONS[i])
            self.icons.append(image!)
        }
    }


    /**
     Assemble the popover if it hasn't been assembled yet.
     */
    private func makePopover() {
        
        if self.iconPopover == nil {
            self.iconPopover = NSPopover()
            self.iconPopover!.contentViewController = self.iconPopoverController
            self.iconPopover!.delegate = self
            self.iconPopover!.behavior = NSPopover.Behavior.transient
        }
    }

    
    /**
     Present the controller's sheet, customising it to either display an existing
     Menu Item's details for editing, or empty fields for a new Menu Item.
     */
    func showSheet() {

        // FROM 1.7.0
        // Reset the segment control
        self.modifierKeysSegment.selectedSegment = -1

        // FROM 2.0.0
        self.hasNewCustomIcon = false
        
         if self.isEditing {
            // We are presenting an existing item, so get it and populate
            // the sheet's fields accordingly
            if let item: MenuItem = self.newMenuItem {
                // Populate the fields from the MenuItem property
                self.titleText.stringValue = "Edit This Command"
                self.itemScriptText.stringValue = item.script
                self.menuTitleText.stringValue = item.title
                self.itemScriptText.becomeFirstResponder()
                self.itemScriptText.currentEditor()?.selectedRange = NSMakeRange(0, 0)
                self.saveButton.title = "Update"
                self.textCount.stringValue = "\(item.title.count)/30"
                self.openCheck.state = item.type == .script ? .off : .on
                self.directCheck.state = item.isDirect ? .on : .off
                
                // FROM 1.7.0
                self.keyEquivalentText.stringValue = item.keyEquivalent.uppercased()
                
                if item.keyModFlags & (1 << MNU_CONSTANTS.MOD_KEY_SHIFT) != 0 {
                    self.modifierKeysSegment.selectSegment(withTag: MNU_CONSTANTS.MOD_KEY_SHIFT)
                }
                
                if item.keyModFlags & (1 << MNU_CONSTANTS.MOD_KEY_CMD) != 0 {
                    self.modifierKeysSegment.selectSegment(withTag: MNU_CONSTANTS.MOD_KEY_CMD)
                }
                
                if item.keyModFlags & (1 << MNU_CONSTANTS.MOD_KEY_OPT) != 0 {
                    self.modifierKeysSegment.selectSegment(withTag: MNU_CONSTANTS.MOD_KEY_OPT)
                }
                
                if item.keyModFlags & (1 << MNU_CONSTANTS.MOD_KEY_CTRL) != 0 {
                    self.modifierKeysSegment.selectSegment(withTag: MNU_CONSTANTS.MOD_KEY_CTRL)
                }
                
                // FROM 2.0.0
                self.iconButton.index = item.iconIndex
                if item.iconIndex >= MNU_CONSTANTS.ICONS.count {
                    // We have a custom menu item icon to load
                    if let imageBytes = loadImage(getImageStoreUrl(item.customImageId)) {
                        if let image = NSImage(data: imageBytes) {
                            image.isTemplate = true
                            self.iconButton.image = image
                        }
                    }
                } else {
                    // Load up a pre-installed icon
                    self.iconButton.image = self.icons[item.iconIndex]
                }
            } else {
                NSLog("Could not access the supplied MenuItem")
                return
            }
        } else {
            // We are presenting a new item, so create it and
            // clear the sheet's input fields
            self.titleText.stringValue = "Add A New Command"
            self.itemScriptText.stringValue = ""
            self.menuTitleText.stringValue = ""
            self.itemScriptText.becomeFirstResponder()
            self.saveButton.title = "Add"
            self.iconButton.image = self.icons[0]
            self.iconButton.index = 0
            self.textCount.stringValue = "0/30"
            self.openCheck.state = .off
            self.directCheck.state = .off
            // FROM 1.7.0
            self.keyEquivalentText.stringValue = ""
            
        }
        
        // FROM 2.0.0
        // Compile the icon lists
        updateIconLists()
        
        // Present the sheet
        if let window = self.parentWindow {
            window.beginSheet(self.addItemSheet, completionHandler: nil)
        }
    }

    
    /**
     Add the existing custom icons to the collection of icons available.
     This only occurs when the quanity of custom icons is non-zero and greater than the number
     already added to the icon collection - ie. when there are new ones to add.
     
     FROM 2.0.0
     */
    private func updateIconLists() {
        
        if self.customIcons.count > 0 {
            // We have custom icons to add.
            self.icons.removeLast(self.icons.count - MNU_CONSTANTS.ICONS.count)
        
            // Add all the custom
            for customIcon in self.customIcons {
                self.icons.append(customIcon.image!)
            }
            
            self.iconPopoverController.availableIcons = self.icons
            self.iconPopoverController.collectionView.reloadData()
        }
    }
    
    
    /**
     When we receive a notification from the popover controller that an icon has been selected,
     we come here and set the button's image to that icon. The notification's object property
     is the icon's index in the `icons` array.
     */
    @objc
    func updateButtonIcon(_ note: Notification) {

        if let obj: Any = note.object {
            // Decode the notification object
            let index = obj as! NSNumber
            
            // FROM 2.0.0
            if index.intValue >= MNU_CONSTANTS.ICONS.count {
                // Generate fresh images from the loaded custom icon template
                self.iconButton.image = self.icons[index.intValue].modedImage()
            } else {
                self.iconButton.image = self.icons[index.intValue]
            }
            
            self.iconButton.index = index.intValue
            
            // FROM 2.0.0
            self.hasNewCustomIcon = false
        }
    }


    // MARK: - Action Functions

    @IBAction
    @objc
    func doCancel(sender: Any?) {

        // User has clicked 'Cancel', so just close the sheet

        self.parentWindow!.endSheet(addItemSheet)
        self.parentWindow = nil
    }


    /**
     The user has clicked the Add button, so check the entered information then,
     if the checks pass, save the new menu item or update the referenced menu item.
     */
    @IBAction
    @objc
    func doSave(sender: Any?) {
        
        var itemHasChanged: Bool = false
        let isOpenAction: Bool = self.openCheck.state == .on
        let isDirect: Bool = self.directCheck.state == .on
        
        // FROM 1.6.1
        // For end to editing, to see if this fixes the 'no changes' issue
        // with the TextFields
        if let theText: NSText = self.itemScriptText.currentEditor() {
            self.itemScriptText.endEditing(theText)
        }
        
        if let theText: NSText = self.menuTitleText.currentEditor() {
            self.menuTitleText.endEditing(theText)
        }
        
        // Check that we have valid field entries
        if self.itemScriptText.stringValue.count == 0 {
            // The field is blank, so warn the user
            showAlert("Missing Command", "You must enter a command. If you don’t want to set one at this time, click OK then Cancel", self.addItemSheet)
            return
        }

        if self.menuTitleText.stringValue.count == 0 {
            // The field is blank, so warn the user
            showAlert("Missing Menu Label", "You must enter a label for the command’s menu entry. If you don’t want to set one at this time, click OK then Cancel", self.addItemSheet)
            return
        }

        // FROM 1.5.0
        // If we've created an 'open' action, check that the target exists
        if isOpenAction {
            if let ad: AppDelegate = self.appDelegate {
                if ad.getAppPath(self.itemScriptText.stringValue) == nil {
                    showAlert("The app ‘\(self.itemScriptText.stringValue)’ cannot be found", "Please check that you have it installed on your Mac.", self.addItemSheet)
                    return
                }
            }
        }

        // FROM 1.5.0
        // If the 'run direct' checkbox is set, make sure we have an absolute path
        if isDirect {
            // Check for an initial '/' to make sure we have an absolute path
            if !self.itemScriptText.stringValue.hasPrefix("/") {
                showAlert("You do not appear to have entered an absolute path", "Please check the ‘Enter a command...’ field and try so Save again.", self.addItemSheet)
                return
            }

            // Check to see if the direct command contains common shell characters
            // NOTE We check 'sender' is not nil because we pass nil into the function
            //      when recursing it from 'showDirectAlert()' if the user chooses
            //      to save anyway
            if sender != nil && checkDirectCommand(self.itemScriptText.stringValue) {
                showDirectAlert()
                return
            }
        }

        // FROM 1.7.0
        // Make sure a specified key equivalent AND any modifiers are unique
        var modKeys: UInt = 0
        for i: Int in 0..<self.modifierKeysSegment.segmentCount {
            if self.modifierKeysSegment.isSelected(forSegment: i) {
                modKeys |= (1 << i)
            }
        }

        if !checkModifiers(modKeys) {
            return
        }

        if self.isEditing {
            // Save the updated fields
            // NOTE `self.menuItem` should not be `nil` if we're editing
            if let item: MenuItem = self.newMenuItem {
                if item.title != self.menuTitleText.stringValue {
                    // FROM 1.2.0
                    // Check for a duplicate menu title if the
                    // menu title has been changed
                    if !checkLabel() { return }
                    
                    itemHasChanged = true
                    item.title = self.menuTitleText.stringValue
                }

                if item.script != self.itemScriptText.stringValue {
                    itemHasChanged = true
                    item.script = self.itemScriptText.stringValue
                }
                
                // FROM 1.2.0
                let newType: MNUItemType = isOpenAction ? .open : .script
                if newType != item.type {
                    item.type = newType
                    itemHasChanged = true
                }

                // FROM 1.2.2
                if item.isDirect != isDirect {
                    itemHasChanged = true
                    item.isDirect = isDirect

                    // FROM 1.5.0
                    // Check for relative elements in the path - and update accordingly
                    if isDirect {
                        item.script = makeAbsolutePath(item.script)
                    }
                }
                
                // FROM 1.7.0
                if item.keyEquivalent != self.keyEquivalentText.stringValue {
                    itemHasChanged = true
                    item.keyEquivalent = self.keyEquivalentText.stringValue.lowercased()
                }
                
                if item.keyModFlags != modKeys {
                    itemHasChanged = true
                    item.keyModFlags = modKeys
                }
                
                // FROM 2.0.0
                if self.hasNewCustomIcon {
                    // A custom image has been chosen, replacing either an older custom image
                    // or a pre-installed icon selection
                    itemHasChanged = true
                    item.iconIndex = self.iconButton.index
                } else {
                    // No custom image selected so we check for a change of pre-installed icon
                    if item.iconIndex != self.iconButton.index {
                        itemHasChanged = true
                        item.iconIndex = self.iconButton.index
                        
                        if item.iconIndex >= MNU_CONSTANTS.ICONS.count {
                            // Get the custom icon path
                            let customIcon = customIcons[item.iconIndex - MNU_CONSTANTS.ICONS.count]
                            item.customImageId = customIcon.id
                            
                            // NOTE `.cusomImageId` will be empty if a new custom image has been selected
                            //      (of which there may be more than one)
                        }
                    }
                }
            }
        } else {
            // Process a new menu item
            // Check for a duplicate menu title
            if !checkLabel() { return }
            
            // Create a Menu Item and set its values
            let newItem: MenuItem = MenuItem()
            newItem.script = self.itemScriptText.stringValue
            newItem.title = self.menuTitleText.stringValue
            newItem.type = isOpenAction ? .open : .script
            newItem.code = MNU_CONSTANTS.ITEMS.SCRIPT.USER
            newItem.isNew = true
            // FROM 1.2.2
            newItem.isDirect = isDirect

            // FROM 1.5.0
            // Check for relative elements in the path - and update accordingly
            if isDirect {
                if (newItem.script as NSString).contains("..") {
                    newItem.script = (newItem.script as NSString).standardizingPath
                }
            }
            
            // FROM 1.7.0
            newItem.keyEquivalent = self.keyEquivalentText.stringValue
            newItem.keyModFlags = modKeys
            
            // FROM 2.0.0
            newItem.iconIndex = self.iconButton.index
            // NOTE Don't store the image path here --
            //      it's set when the image is saved (see `saveImage()`)
            
            if newItem.iconIndex >= MNU_CONSTANTS.ICONS.count {
                // Get the custom icon path
                let customIcon = customIcons[newItem.iconIndex - MNU_CONSTANTS.ICONS.count]
                newItem.customImageId = customIcon.id
                
                // NOTE `.cusomImageId` will be empty if a new custom image has been selected
                //      (of which there may be more than one)
            }

            // Store the new menu item
            self.newMenuItem = newItem
            itemHasChanged = true
        }
        
        // FROM 2.0.0
        // Do we need to save a custom image?
        // NOTE This will only save the item's current new custom image
        saveCustomImage()
        
        // Was the item updated at all (this will be true for new items)
        if itemHasChanged {
            // Inform the configure window controller that there's a new item to list
            // NOTE The called code handles edited items too - it's not just for new items
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: MNU_CONSTANTS.NOTIFICATION_IDS.ITEM_ADDED),
                                            object: self)
        }

        // Close the sheet
        self.parentWindow!.endSheet(addItemSheet)
        self.parentWindow = nil
        
        // FROM 1.6.0
        // Don't stop editing here, do it in the notified code (see above)
        // self.isEditing = false
    }
    
    
    /**
     Show help via the website.
     */
    @IBAction
    @objc
    func doShowHelp(sender: Any?) {
        
        if let helpURL: URL = URL(string: MNU_SECRETS.WEBSITE.URL_MAIN + "#how-to-add-and-edit-your-own-menu-items") {
            NSWorkspace.shared.open(helpURL)
        }
    }
    
    /**
     Present the pre-installed icon matrix.
     */
    @IBAction
    @objc
    func doShowIcons(sender: Any) {
        
        let cols = Int(Double(self.icons.count).squareRoot())
        let rows = self.icons.count % cols == 0 ? self.icons.count / cols : (self.icons.count / cols) + 1
        
        self.iconPopover!.contentSize = CGSize(width: Double(cols * 64), height: Double(rows * 64))
        let pvc = self.iconPopover!.contentViewController as! AddUserItemPopoverController
        pvc.rows = rows
        pvc.columns = cols
        pvc.collectionView.reloadData()
        
        self.iconPopover!.show(relativeTo: self.iconButton.bounds,
                               of: self.iconButton,
                               preferredEdge: NSRectEdge.maxY)
    }
    
    
    /**
     Make sure mutually exclusive checkboxes aren't ticked, and present
     a warning if they are.
     FROM 1.5.0
     */
    @IBAction
    @objc
    func doCheckBox(sender: Any) {
        
        let checkedButton: NSButton = sender as! NSButton
        var doWarn: Bool = false
        
        if checkedButton.state == .on {
            if checkedButton == self.directCheck {
                if self.openCheck.state == .on {
                    // Open action checkbox is set, so direct action can't be
                    doWarn = true
                }
            }
            
            if checkedButton == self.openCheck {
                if self.directCheck.state == .on {
                    // Direct action checkbox is set, so open action can't be
                    doWarn = true
                }
            }
        }
        
        if doWarn {
            // There is a clash, so turn off the just-checked button and warn the user
            checkedButton.state = .off
            showAlert("Sorry, you can’t check this option", "Selecting this option conflicts with another you have already chosen", self.addItemSheet)
        }
    }


    /**
     Clear any modifiers applied thus far.
     
     FROM 1.7.0
     */
    @IBAction
    @objc
    func doClearKey(sender: Any) {
        
        self.keyEquivalentText.stringValue = ""
    }
    
    
    /**
     Present an Open dialog to get a custom image, ie. an unprocessed PNG
     we're going to use as the basis for a menu item icon.
     
     - Note Currently limited to PNG and WebP files only, but this may change.
     */
    @IBAction
    func doChooseImage(sender: Any) {
        
        // Prepare an Open dialog
        let openDialog = NSOpenPanel()
        openDialog.canChooseFiles = true
        openDialog.canChooseDirectories = false
        openDialog.allowsMultipleSelection = false
        openDialog.delegate = self
        openDialog.directoryURL = URL(fileURLWithPath: "")

        // FROM 2.1.0
        // Add graphics guidance
        // TODO Make this appear automatically and not just when `Show Options` is clicked.
        let av: NSTextField = NSTextField(frame: NSMakeRect(0.0, 0.0, 600.0, 64.0))
        av.isEditable = false
        av.isSelectable = false
        av.usesSingleLineMode = false
        av.isBezeled = false
        av.isBordered = false
        av.lineBreakMode = .byWordWrapping
        av.stringValue = "Images should be in PNG or WEBP format and sized to at least 256x256 pixels. Images are applied as macOS template images, so they should contain only black pixels, transparent pixels and/or pixels with opacities between these two extremes."
        openDialog.accessoryView = av

        // Limit opening to PNG files
        if let typo = UTType(filenameExtension: "png") {
            openDialog.allowedContentTypes = [typo]
        }
        
        if let typo = UTType(filenameExtension: "webp") {
            openDialog.allowedContentTypes.append(typo)
        }
        
        // Show the panel and get the result
        var targetUrl: URL? = nil
        if openDialog.runModal() == .OK {
            targetUrl = openDialog.url
        }

        openDialog.close()
        
        // If we have a valid (non-nil) URL, try and load the file
        // and then, on success, process it for MNU usage.
        if let openUrl = targetUrl {
            if let data = loadImage(openUrl) {
                processCustomImage(data, openUrl)
            }
        }
    }
    
    
    // MARK: - Image File Load/Save and Processing Functions
    
    /**
     Convert a loaded custom image into a form that can be used by menu items,
     ie. 60x60 and set as a template. Once the image is ready, we can apply it,
     so this is where the icon custom index (25 or greater, where 25 is the fixed
     number of pre-installed icons) is set.
     
     However, we do not save the image or give it a filename here (see `saveImage()`)
     because the user may choose not to use the loaded image after all. All we do is
     establish it as a possible custom icon and record it as the currently selected one.
     
     FROM 2.0.0
     
     - Parameters
        - imageBytes: The image data loaded from disk.
        - imageUrl:   The URL of the image (for saving)
     */
    private func processCustomImage(_ imageBytes: Data, _ imageUrl: URL) {
        
        // Convert the image data to an image object
        guard let image = NSImage(data: imageBytes) else { return }
                
        // Get a scaled version of the image at the required size
        // TODO Report error here (or above)?
        guard let processedImage = image.resize(to: NSSize(width: 60.0, height: 60.0)) else { return }
        
        // Complete processing (scaling) and set the icon selection button's image
        processedImage.isTemplate = true
        self.iconButton.image = processedImage
        self.hasNewCustomIcon = true
        
        // Add the new icon to the current list of custom icons
        let newCustomIon = CustomIcon()
        newCustomIon.image = processedImage
        self.customIcons.append(newCustomIon)
        updateIconLists()
        
        // Point the icon selection button at the new custom icon record
        self.iconButton.index = MNU_CONSTANTS.ICONS.count - 1 + self.customIcons.count
    }
    
    
    /**
     Save a custom image that has been processed for menu item use to disk. This is the
     custom icom the user selected prior to clicking **Add** or **Update**, so will be
     used by the App Delegate for susbequent menu generation.
     
     FROM 2.0.0
     */
    private func saveCustomImage() {
        
        // Ensure we have a menu item
        guard let newMenuItem = self.newMenuItem else { return }
        
        // Ensure we are working with a custom icon and it's valid
        guard self.iconButton.index >= MNU_CONSTANTS.ICONS.count else { return }
        
        let customImageIndex = self.iconButton.index - MNU_CONSTANTS.ICONS.count
        guard let bitmap = self.customIcons[customImageIndex].image?.tiffRepresentation else { return }
        
        // Try to make (or get) the image store path and only proceed if it's there
        guard makeConfig() else { return }
        
        if self.customIcons[customImageIndex].id == "" {
            // This is a totally new image because this value is never set on image load, even
            // if multiple images have been loaded so give the imge store file a unique name...
            let filename = UUID().uuidString
            let fileUrl = getImageStoreUrl(filename)
            
            // ...and attempt to save it, keeping the filename on success
            do {
                try bitmap.write(to: fileUrl)
                newMenuItem.customImageId = filename
            } catch {
                print(error)
            }
        }
    }
    
    
    /**
     Create `.config` and `.config/mnu` directories under the user's home directory.
     
     FROM 2.0.0
     
     - Returns `true` if the directories are already present or created, otherwise `false`.
     */
    private func makeConfig() -> Bool {
        
        let fd = FileManager.default
        let path = getImageStoreUrl("")
        if fd.fileExists(atPath: path.unixpath()) {
            return true
        }
        
        do {
            try fd.createDirectory(at: path, withIntermediateDirectories: true)
            return true
        } catch {
            print(error)
        }
        
        return false
    }
    
    
    // MARK: - Input Checker Functions
    
    /**
     Verify that the user has entered a unique menu label.
     
     FROM 1.2.0 (moved from `doSave()`)
     
     - Returns `true` if the label is unique, otherwise `false`.
     */
    private func checkLabel() -> Bool {
        
        if let list: MenuItemList = self.currentMenuItems {
            if list.items.count > 0 {
                var got: Bool = false
                for item: MenuItem in list.items {
                    if item.title == self.menuTitleText.stringValue {
                        got = true
                        break
                    }
                }

                if got {
                    // The label is in use, so warn the user and exit the save
                    showAlert("Menu Label Already In Use", "You must enter a unique label for the command’s menu entry. If you don’t want to set one at this time, click OK then Cancel", self.addItemSheet)
                    return false
                }
            }
        }

        return true
    }


    /**
     Verify that an entered direct command does not contain any special
     shell characters.
     
     FROM 1.5.0
     
     - Note Should probably reverse the output.
     
     - Parameters
        - command: The command to check.
     
     - Returns `true` if the command contains shell characters, otherwise `false`.
     */
    func checkDirectCommand(_ command: String) -> Bool {
        
        let shellChars: [String] = ["~", "$", "*", "?", "!", "+", "@", "\"", "'", "{", "["]
        for shellChar in shellChars {
            if (command as NSString).contains(shellChar) {
                return true
            }
        }

        return false
    }


    /**
     Check for a relative path and return the absolute version.
     (or the input path if it is already absolute).
     
     FROM 1.5.0
     
     - Note Refactored to a function to simplify testing.
     
     - Parameters
        - path: The relative path to process.
     
     - Returns The absolute path.
     */
    func makeAbsolutePath(_ path: String) -> String {
        
        // Separate input path into space-separated sub-paths
        var returnPath: String = ""
        let parts: [String] = (path as NSString).components(separatedBy: " ")
        
        // Fix up each sub-path
        for i in 0..<parts.count {
            var part: String = parts[i]
            if (part as NSString).contains("..") {
                if !part.hasPrefix("/") {
                    part = "/" + part
                }
                returnPath += (part as NSString).standardizingPath
            } else {
                returnPath += part
            }

            // Put the spaces back for all but the last item
            if i < parts.count - 1 {
                returnPath += " "
            }
        }
        
        return returnPath
    }

    
    /**
     Check the modifier keys selected have not been already assigned to another menu item.
     
     An alert is presented if the modifiers are invalid.
     
     - Parameters
        - modFlags: A bitfield indicating the selected modififiers.
     
     - Returns `true` if the modifiers are valid, otherwise `false`.
     */
    private func checkModifiers(_ modFlags: UInt) -> Bool {
        
        if self.keyEquivalentText.stringValue == "" {
            return true
        }
        
        if let list: MenuItemList = self.currentMenuItems {
            if list.items.count > 0 {
                if let newMenuItem: MenuItem = self.newMenuItem {
                    var got: Bool = false
                    for item: MenuItem in list.items {
                        if item.uuid != newMenuItem.uuid &&
                            item.keyEquivalent == self.keyEquivalentText.stringValue.lowercased() &&
                            item.keyModFlags == modFlags {
                            got = true
                            break
                        }
                    }
                    
                    if got {
                        // The label is in use, so warn the user and exit the save
                        showAlert("Key Equivalent and Modifiers are in use", "You must enter a unique key equivalent and modifier set. Please do so, or remove the key", self.addItemSheet)
                        return false
                    }
                }
            }
        }
        
        return true
    }


    // MARK: - Helper Functions
    
    /**
     Present and alert to warn the user and provide two alternatives.
     
     FROM 1.5.0
     */
    private func showDirectAlert() {
        
        self.directAlert = NSAlert()
        self.directAlert!.messageText = "Your direct command contains one or more common shell characters"
        self.directAlert!.informativeText = "Direct commands are not processed by a shell. Are you sure you want to save this command?"
        self.directAlert!.addButton(withTitle: "Save")
        self.directAlert!.addButton(withTitle: "Edit Command")
        self.directAlert!.beginSheetModal(for: self.addItemSheet) { (response) in
            if response == .alertFirstButtonReturn {
                self.directAlert!.window.orderOut(nil)
                self.doSave(sender: nil)
            }
        }
    }


    // MARK: - NSTextFieldDelegate Functions

    /**
     This function is used to trap text entry into the `itemText` field and to limit it to x characters,
     where x is set by `MNU_CONSTANTS.MENU_TEXT_LEN`.
     */
    func controlTextDidChange(_ obj: Notification) {
        
        let sender: NSTextField = obj.object as! NSTextField
        if sender == self.menuTitleText {
            if self.menuTitleText.stringValue.count > MNU_CONSTANTS.MENU_TEXT_LEN {
                // The field contains more than 'MNU_CONSTANTS.MENU_TEXT_LEN' characters, so only
                // keep that number of characters in the field
                self.menuTitleText.stringValue = String(self.menuTitleText.stringValue.prefix(MNU_CONSTANTS.MENU_TEXT_LEN))
                NSSound.beep()
            }

            // Whenever a character is entered, update the character count
            self.textCount.stringValue = "\(self.menuTitleText.stringValue.count)/\(MNU_CONSTANTS.MENU_TEXT_LEN)"
            return;
        }
    }


    // MARK: - NSWindowDelegate Methods

    /**
     Assign a custom Field Editor to the modifier keys NSTextField.
     See `AddUserItemKeyFieldEditor.swift`.
     
     FROM 1.7.0
     */
    func windowWillReturnFieldEditor(_ sender: NSWindow, to client: Any?) -> Any? {
        
        if let anyClient: Any = client {
            if anyClient is AddUserItemKeyTextField {
                if self.keyFieldEditor == nil {
                    self.keyFieldEditor = AddUserItemKeyFieldEditor()
                }

                // Don't process Tab, Enter etc.
                self.keyFieldEditor!.isFieldEditor = false

                // Link in the NSTextField subclass
                self.keyFieldEditor!.keyTextField = self.keyEquivalentText

                // Trap Undo (CMD-Z) handling
                self.keyFieldEditor!.allowsUndo = false
                self.keyEquivalentText.undoManager?.registerUndo(withTarget: self.keyFieldEditor!,
                                                                 selector: #selector(AddUserItemKeyFieldEditor.undo),
                                                                 object: nil)
                return self.keyFieldEditor!
            }
        }
        
        return nil
    }
}
