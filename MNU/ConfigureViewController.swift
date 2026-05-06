/*
    ConfigureWindowViewController.swift
    MNU

    Created by Tony Smith on 05/07/2019.
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
import UniformTypeIdentifiers


final class ConfigureViewController:  NSViewController,
                                      NSTabViewDelegate,
                                      NSTableViewDataSource,
                                      NSTableViewDelegate,
                                      NSWindowDelegate,
                                      NSMenuDelegate,
                                      NSOpenSavePanelDelegate {

    // MARK: - UI Outlets

    @IBOutlet var windowTabView: NSTabView!
    @IBOutlet var window: PMConfigureWindow!

    // Menu Items Tab
    @IBOutlet weak var menuItemsTableView: NSTableView!
    @IBOutlet weak var menuItemsCountText: NSTextField!
    @IBOutlet weak var showHelpButton: NSButton!
    @IBOutlet weak var aivc: AddUserItemViewController!
    // FROM 1.1.0
    @IBOutlet weak var extrasButton: NSButton!
    @IBOutlet weak var menuItemsAddButton: NSButton!
    @IBOutlet weak var applyChangesButton: NSButton!

    // Settings Tab
    @IBOutlet weak var prefsHelpButton: NSButton!
    // FROM 1.6.0
    @IBOutlet weak var prefsTerminalChoiceTerminal: NSButton!
    @IBOutlet weak var prefsTerminalChoiceITerm2: NSButton!
    // FROM 2.2.0
    @IBOutlet weak var prefsLaunchAtLoginSwitch: NSSwitch!
    @IBOutlet weak var prefsNewTermTabSwitch: NSSwitch!
    @IBOutlet weak var prefsShowImagesSwitch: NSSwitch!
    @IBOutlet weak var prefsAutoSeparateSwitch: NSSwitch!
    @IBOutlet weak var prefsDirectOutputSwitch: NSSwitch!
    // FROM 2.4.0
    @IBOutlet weak var prefsTerminalChoiceGhostty: NSButton!

    // About... Tab
    @IBOutlet weak var aboutVersionText: NSTextField!
    @IBOutlet weak var fbvc: FeedbackSheetViewController!
    // FROM 1.1.0
    @IBOutlet weak var feedbackButton: NSButton!

    // Tab control buttons
    // FROM 2.0.0
    @IBOutlet weak var tabButtonMenu: NSButton!
    @IBOutlet weak var tabButtonSettings: NSButton!
    @IBOutlet weak var tabButtonAbout: NSButton!


    // MARK: - Public Class Properties

    var menuItems: MenuItemList? = nil
    var configureWindow: PMConfigureWindow? = nil
    let mnuPasteboardType = NSPasteboard.PasteboardType(rawValue: MNU_CONSTANTS.MISC_IDS.PASTEBOARD)
    var hasChanged: Bool = false
    var lastChance: Bool = false
    // FROM 1.6.0
    var terminalChoice: Int = 0
    var tabOpenChoice: Bool = false
    // FROM 2.0.0
    var doShowOutput: Bool = false
    // FROM 2.4.0
    var firstOpen: Bool = true


    // MARK: - Private Class Properties

    private  var systemVersion: Int = 10
    // FROM 1.1.0
    private  var extrasMenu: NSMenu? = nil
    // FROM 1.7.0
    private  var systemVersionMinor: Int = 14
    // FROM 2.0.0
    private  var tabManager: PMTabManager = PMTabManager()
    private  var autoSeparateInForce: Bool = false
    private  var newMenuItemIndex: Int = 0
    internal var customIcons: [CustomIcon] = []


    // MARK: - Lifecycle Functions

    override func viewDidLoad() {

        super.viewDidLoad()

        // FROM 1.4.6
        // Get the OS version so we can set the table view row height and cell image scaling
        // according to whether we're on Catalina or under, or Big Sur and up
        let sysVer: OperatingSystemVersion = ProcessInfo.processInfo.operatingSystemVersion
        self.systemVersion = sysVer.majorVersion
        self.systemVersionMinor = sysVer.minorVersion

        // Ask our window to make the first responder (for key presses)
        self.configureWindow = self.window
        self.window.makeFirstResponder(self)
        self.window.delegate = self

        // Set up the table view for drag and drop reordering
        self.menuItemsTableView.registerForDraggedTypes([self.mnuPasteboardType])
        self.menuItemsTableView.delegate = self
        self.menuItemsTableView.rowSizeStyle = .custom

        // Watch for notifications of changes sent by the add user item view controller
        let nc: NotificationCenter = NotificationCenter.default
        nc.addObserver(self,
                       selector: #selector(self.processNewItem),
                       name: NSNotification.Name(rawValue: MNU_CONSTANTS.NOTIFICATION_IDS.ITEM_ADDED),
                       object: nil)

        // Set up the About MNU... tab text
        let version: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        let build: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
        self.aboutVersionText.stringValue = "Version \(version) (\(build))"

        // FROM 1.1.0
        // Prepare the extras... button
        self.extrasMenu = NSMenu()
        self.extrasMenu!.addItem(NSMenuItem(title: "Backup MNU data...",
                                            action: #selector(self.doExport),
                                            keyEquivalent: ""))
        self.extrasMenu!.addItem(NSMenuItem(title: "Restore MNU data...",
                                            action: #selector(self.doImport),
                                            keyEquivalent: ""))
        self.extrasMenu!.addItem(NSMenuItem.separator())
        self.extrasMenu!.addItem(NSMenuItem(title: "Restore defaults",
                                            action: #selector(self.restoreDefaults),
                                            keyEquivalent: ""))
        // FROM 2.1.0
        self.extrasMenu!.addItem(NSMenuItem.separator())
        self.extrasMenu!.addItem(NSMenuItem(title: "Delete unused custom icons",
                                            action: #selector(self.imageFileGarbageCollection),
                                            keyEquivalent: ""))
        // FROM 1.1.0
        self.extrasMenu!.addItem(NSMenuItem.separator())
        self.extrasMenu!.addItem(NSMenuItem(title: "Send feedback...",
                                            action: #selector(self.submitFeedback),
                                            keyEquivalent: ""))

        // FROM 1.1.0
        // Add tooltips: Menu Items Tab
        self.menuItemsAddButton.toolTip         = "Add a new menu item"
        self.extrasButton.toolTip               = "Click here for further actions"
        self.applyChangesButton.toolTip         = "Click to apply any changes you have made"
        self.showHelpButton.toolTip             = "Click here for help with this tab"

        // Preferences/Settings Tab
        self.prefsHelpButton.toolTip            = "Click here for help with this tab"
        self.prefsLaunchAtLoginSwitch.toolTip   = "Check to automatically launch MNU when your Mac starts up"
        self.prefsNewTermTabSwitch.toolTip      = "Check to run commands in new Terminal tabs"
        self.prefsShowImagesSwitch.toolTip      = "Check to display images alongside MNU menu items"

        // About... Tab
        self.feedbackButton.toolTip             = "Click here to submit comments and feedback about MNU"

        // Tab control buttons
        self.tabButtonMenu.toolTip              = "Configure MNU’s menu items"
        self.tabButtonSettings.toolTip          = "Apply MNU settings"
        self.tabButtonAbout.toolTip             = "Learn more about MNU"

        // Configure the tab manager and its tabs
        makeTabs(self.tabManager)

        // FROM 2.2.0
        self.feedbackButton.contentTintColor = .controlAccentColor

        // FROM 2.4.0
        // Move this here so un-minimising the window doesn't change its tab
        self.tabManager.programmaticallyClickButton(at: 0)
    }


    override func viewWillAppear() {

        super.viewWillAppear()

        // FROM 1.3.1
        // Scale up table view row height according to macOS version
        self.menuItemsTableView.rowSizeStyle = .custom
        self.menuItemsTableView.rowHeight = MNU_CONSTANTS.CONFIG_TABLE_ROW_HEIGHT

        // FROM 1.0.0: move from the app delegate
        // Update the item table
        self.menuItemsTableView.reloadData()

        // Update the menu item list count indicator
        displayItemCount()

        // FROM 1.0.1: moved from 'viewDidLoad()' so that the items update AFTER defaults registration
        // Set up the Preferences section
        let defaults: UserDefaults = UserDefaults.standard
        self.prefsLaunchAtLoginSwitch.state = defaults.bool(forKey: MNU_CONSTANTS.SETTINGS_IDS.STARTUP_LAUNCH) ? .on : .off
        self.prefsNewTermTabSwitch.state = defaults.bool(forKey: MNU_CONSTANTS.SETTINGS_IDS.NEW_TERM_TAB) ? .on : .off
        self.prefsShowImagesSwitch.state = defaults.bool(forKey: MNU_CONSTANTS.SETTINGS_IDS.SHOW_MENU_IMAGES) ? .on : .off
        // FROM 1.6.0
        self.terminalChoice = defaults.integer(forKey: MNU_CONSTANTS.SETTINGS_IDS.TERMINAL)
        switch(self.terminalChoice) {
            case MNU_CONSTANTS.TERMINAL.ITERM:
                self.prefsTerminalChoiceITerm2.state = .on
            // Add other non-zero cases here to include other terminals:
            // FROM 2.4.0 -- add Ghostty
            case MNU_CONSTANTS.TERMINAL.GHOSTTY:
                self.prefsTerminalChoiceGhostty.state = .on
            default:
                self.prefsTerminalChoiceTerminal.state = .on
        }

        // FROM 1.1.0
        // Disable/enable the Apply button until changes are made
        self.applyChangesButton.isEnabled = self.hasChanged

        // FROM 2.0.0
        // Set up auto separation and its effect on controls
        self.prefsAutoSeparateSwitch.state = defaults.bool(forKey: MNU_CONSTANTS.SETTINGS_IDS.AUTO_SEPARATE) ? .on : .off
        self.autoSeparateInForce = self.prefsAutoSeparateSwitch.state == .on ? true : false

        // Set up output for direct commands
        self.prefsDirectOutputSwitch.state = defaults.bool(forKey: MNU_CONSTANTS.SETTINGS_IDS.SHOW_DIRECT_OUTPUT) ? .on : .off
        self.doShowOutput = self.prefsDirectOutputSwitch.state == .on ? true : false

        // FROM 2.0.0
        // Assemble a set of custom icons
        getCustomIcons()

        // Size the first tab (which may not be visible)
        setListTabSize()
        self.tabManager.setWindowSize()

        // FROM 2.4.0
        // Centre the window when it first appears
        if self.firstOpen {
            self.window.center()
            self.firstOpen = false
        }
    }


    override func viewWillDisappear() {

        // Preserve content size of the MNU List tab. It will have been saved if
        // the users switched to another tab, but this preserves sizes when no
        // switch took place
        if self.tabManager.currentIndex == 0 {
            self.tabManager.preserveCurrentSizeOfTabAt(index: 0)
        }
    }


    /**
     Assemble a list of custom icons from the icon store.
     This will include icons mapped to menu items plus any stored
     images orphaned from menu items.

     FROM 2.0.0
     MODIFIED 2.1.0
     */
    private func getCustomIcons() {

        guard let menuItems = self.menuItems?.items else { return }

        // Clear the custom icon list if it is populated
        if !self.customIcons.isEmpty {
            self.customIcons.removeAll()
        }

        // Populate the custom icon list
        do {
            // Get the files currently in the store at `~/.congfig/mnu`
            let files = try FileManager.default.contentsOfDirectory(atPath: getImageStoreUrl("").unixpath())
            for file in files {
                // Add the image file to the custom icon list
                if let customIcon = getCustomIcon(file) {
                    self.customIcons.append(customIcon)

                    // Determine if one or more menu items claims the current custom icon
                    for menuItem in menuItems {
                        if menuItem.customImageId == file {
                            // The menu item claims the custom icon, so mark the current custom icon as in use...
                            customIcon.inUse = true

                            // ...and point the menu item at the custom icon in the list
                            menuItem.iconIndex = MNU_CONSTANTS.DEFAULT_ICONS.count - 1 + self.customIcons.count
                        }
                    }
                } else {
                    // TODO Better error presentation
                    print("Could not load image file '\(file)' from the store")
                }
            }
        } catch {
            // NOP
        }
    }


    /**
     Create a custom item object for a file loaded from disk.

     - Parameters:
        - filename: The name of the image file to load.

     - Returns A CustomIcon instance, or `nil` on error.
     */
    private func getCustomIcon(_ filename: String) -> CustomIcon? {
        if let imageBytes = loadImage(getImageStoreUrl(filename)) {
            if let image = NSImage(data: imageBytes) {
                let customIcon = CustomIcon()
                image.isTemplate = true
                customIcon.image = image
                customIcon.id = filename
                return customIcon
            }
        }

        return nil
    }


    /**
     Show the controller's own window in the centre of the display,
     eg. called by the app delegate in response to a notification from the
     controls view controller.

     - Note This triggers calls to `viewWillAppear()`, `viewdidAppear()`, etc.
     */
    func show() {

        if !self.configureWindow!.isVisible {
            // Window is not yet present on the desktop so handle extra,
            // post-load initialisation here
            self.applyChangesButton.isEnabled = false
        }

        // The following is required to bring the window to the front properly
        self.configureWindow!.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }


    override func resignFirstResponder() -> Bool {

        // Make sure we can continue to track key events
        // NOTE Currently disabled (to restore table drag'n'drop)
        return true
    }


    // MARK: - Tab View Action Functions

    @IBAction
    private
    func doSwitchTab(sender: NSButton) {

        self.tabManager.buttonClicked(sender)
    }


    // MARK: - Menu Items Tab Action Functions

    @IBAction
    @objc
    func doCancel(sender: Any?) {

        // The user clicked 'Cancel', so just close the configure window
        self.configureWindow!.performClose(sender)

        // Update the visibility state
        //self.isVisible = false
    }


    @IBAction
    @objc
    private func doSave(sender: Any?) {

        // If any changes have been made to the item list, inform the app delegate
        if self.hasChanged {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: MNU_CONSTANTS.NOTIFICATION_IDS.UPDATE_LIST),
                                            object: self)
            self.hasChanged = false
            self.applyChangesButton.isEnabled = false
        }

        // Disabled -- this is now handled by the notification code called above
        // Close the Configure window
        // self.configureWindow!.close()
    }


    @IBAction
    @objc
    private func doNewScriptItem(sender: Any?) {

        doAdd(self.menuItems?.items.count ?? -1)
    }


    @IBAction
    @objc
    private func doShowExtras(sender: NSButton) {

        // FROM 1.1.0
        // Pop up the import/export buttons
        let yDelta: CGFloat = 4.0
        let buttonPosition = NSPoint(x: 0, y: yDelta + sender.frame.size.height)
        self.extrasMenu!.popUp(positioning: nil,
                               at: buttonPosition,
                               in: sender)
    }


    // MARK: - Menu Items Action Handler Support Functions

    /**
     Invoke the Add User Item sheet for the creation of a new item.

     FROM 2.0.0
     */
    private func doAdd(_ additionPoint: Int) {

        guard checkMenuItemCount() else { return }

        self.aivc.newMenuItem = nil
        prepareAddEditSheet(false)
    }


    /**
     Invoke the Add User Item sheet for the editing of an existing item.

     - Parameters:
        - item: The menu item selected for editing.
     */
    private func doEdit(_ item: MenuItem) {

        self.aivc.newMenuItem = item
        prepareAddEditSheet(true)
    }


    /**
     Generic settings to be applied before the Add New Item sheet is revealed
     in either Add Item or Edit Item mode.

     FROM 2.0.0

     - Parameters:
        - isEditing: `true` if the sheet is to be presented in editing mode,
                     otherwise `false`.
     */
    private func prepareAddEditSheet(_ isEditing: Bool) {

        self.aivc.parentWindow = self.configureWindow!
        self.aivc.menuItems = self.menuItems
        self.aivc.customIcons = self.customIcons
        self.aivc.isEditing = isEditing
        self.aivc.cvc = self
        self.aivc.showSheet()
    }


    /**
     Delete a menu item, but offer the user a way out first.

     - Parameters:
        - item: The menu item selected for deletion.
     */
    private func doDelete(_ item: MenuItem) {

        // Present an alert to warn the user about deleting the Menu Item
        let alert: NSAlert = NSAlert()
        alert.messageText = "Are you sure you wish to delete ‘\(item.title)’?"
        alert.addButton(withTitle: "Yes")
        alert.addButton(withTitle: "No")
        alert.beginSheetModal(for: self.configureWindow!) { (response: NSApplication.ModalResponse) in
            if response == NSApplication.ModalResponse.alertFirstButtonReturn {
                // The user clicked 'Yes' so find the item referenced by the button,
                // and remove it from the configure window controller's list
                guard let list = self.menuItems else { return }
                guard list.items.count > 0 else { return }

                // Get the index of the menu item to be deleted
                var index = -1
                for i in 0..<list.items.count {
                    let anItem: MenuItem = list.items[i]
                    if anItem == item {
                        index = i
                        break
                    }
                }

                // We found the item's index, so we can proceed to remove it
                if index != -1 {
                    list.items.remove(at: index)
                    self.hasChanged = true
                    self.applyChangesButton.isEnabled = true
                    self.menuItemsTableView.reloadData()
                }
            }
        }
    }


    /**
     Flip the item's recorded state and update the table.
     */
    private func doShowHide(_ item: MenuItem) {

        item.isHidden = !item.isHidden
        self.hasChanged = true
        self.applyChangesButton.isEnabled = true

        // Reload the table data and update the status line
        self.menuItemsTableView.reloadData()
        displayItemCount()
    }


    // MARK: - Menu Items Table Button Selector Functions

    @objc
    private func doShowHideSwitch(sender: Any) {

        // Get the menu item from the reference stored in the table cell's switch object
        let theSwitch: MenuItemTableCellSwitch = sender as! MenuItemTableCellSwitch
        if let item: MenuItem = theSwitch.menuItem {
            doShowHide(item)
        }
    }


    @objc
    private func doTableButtonEditScript(sender: Any) {

        // Get the menu item from the reference stored in the table cell's edit button
        let button: MenuItemTableCellButton = sender as! MenuItemTableCellButton
        if let item: MenuItem = button.menuItem {
            doEdit(item)
        }
    }


    @objc
    private func doDeleteScript(sender: Any) {

        // Get the menu item from the reference stored in the table cell's delete button
        let button: MenuItemTableCellButton = sender as! MenuItemTableCellButton
        if let item: MenuItem = button.menuItem {
            doDelete(item)
        }
    }


    // MARK: - Contextual Menu Action Functions

    @IBAction
    @objc
    private func doContextShowHide(sender: Any) {

        // Get the menu item from the reference stored in the contextual menu item
        let menuItem: NSMenuItem = sender as! NSMenuItem
        if let item: MenuItem = menuItem.representedObject as? MenuItem {
            doShowHide(item)
        }
    }


    @IBAction
    private func doContextEditScript (sender: Any) {

        // Get the menu item from the reference stored in the contextual menu item
        let menuItem: NSMenuItem = sender as! NSMenuItem
        if let item: MenuItem = menuItem.representedObject as? MenuItem {
            doEdit(item)
        }
    }


    @IBAction
    @objc
    private func doContextDeleteScript(sender: Any) {

        // Get the menu item from the reference stored in the contextual menu item
        let menuItem: NSMenuItem = sender as! NSMenuItem
        if let item: MenuItem = menuItem.representedObject as? MenuItem {
            doDelete(item)
        }
    }


    @IBAction
    @objc
    private func doContextAddNewItem(sender: Any) {

        // Get the menu item from the reference stored in the contextual menu item
        let menuItem: NSMenuItem = sender as! NSMenuItem
        if let item: MenuItem = menuItem.representedObject as? MenuItem {
            if let index = self.menuItems?.items.firstIndex(of: item) {
                self.newMenuItemIndex = index
                doAdd(index)
            }
        }
    }


    @IBAction
    @objc
    private func doContextAddSeparator(sender: Any) {

        // Get the menu item from the reference stored in the contextual menu item
        let menuItem: NSMenuItem = sender as! NSMenuItem
        if let item: MenuItem = menuItem.representedObject as? MenuItem {
            if let index = self.menuItems?.items.firstIndex(of: item) {
                let newMenuItem = MenuItem()
                newMenuItem.type = .separator
                newMenuItem.title = "Separator"
                newMenuItem.code = MNU_CONSTANTS.ITEMS.SCRIPT.USER
                self.menuItems?.items.insert(newMenuItem, at: index + 1)
                self.hasChanged = true
                self.applyChangesButton.isEnabled = true
                self.menuItemsTableView.reloadData()
            }
        }
    }


    // MARK: - About Tab Action Functions

    @IBAction
    private func submitFeedback(sender: Any?) {

        // Get the feedback sheet view controller to show its sheet
        self.fbvc.parentWindow = self.configureWindow!
        self.fbvc.showSheet()
    }


    // MARK: - Settings Tab Action Functions

    /**
     The user has toggled the 'launch at login' checkbox, so send a suitable
     notification to the app delegate.
     */
    @IBAction
    private func doToggleLaunchAtLogin(sender: Any?) {

        let action: String = (self.prefsLaunchAtLoginSwitch.state == NSControl.StateValue.on
                              ? MNU_CONSTANTS.NOTIFICATION_IDS.AUTOSTART_ENABLED
                              : MNU_CONSTANTS.NOTIFICATION_IDS.AUTOSTART_DISABLED)

        NotificationCenter.default.post(name: NSNotification.Name(rawValue: action),
                                        object: self)
    }


    /**
     The user has toggled the 'show item images' checkbox, so set a suitable
     notification to the app delegate.
     */
    @IBAction
    private func doToggleItemImages(sender: Any?) {

        let defaults: UserDefaults = UserDefaults.standard
        let state = self.prefsShowImagesSwitch.state == .on ? true : false
        defaults.set(state, forKey: MNU_CONSTANTS.SETTINGS_IDS.SHOW_MENU_IMAGES)

        // Notify the menu that it needs to change
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: MNU_CONSTANTS.NOTIFICATION_IDS.UPDATE_LIST),
                                        object: self)
    }


    /**
     The user has toggled the 'new terminal tab' checkbox, so set a suitable
     notification to the app delegate.
     */
    @IBAction
    private func doSetTermPref(sender: Any?) {

        let defaults: UserDefaults = UserDefaults.standard
        self.tabOpenChoice = self.prefsNewTermTabSwitch.state == .on ? true : false
        defaults.set(self.tabOpenChoice, forKey: MNU_CONSTANTS.SETTINGS_IDS.NEW_TERM_TAB)

        // FROM 1.6.0
        // Notify the menu that it needs to change
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: MNU_CONSTANTS.NOTIFICATION_IDS.TERM_TABBING_SET),
                                        object: self)
    }


    /**
     The user has changed their preferred terminal app.

     FROM 1.6.0
     */
    @IBAction
    private func doToggleTerminalChoice(sender: Any?) {

        var termChoice: Int = 0
        if self.prefsTerminalChoiceITerm2.state == .on {
            termChoice = MNU_CONSTANTS.TERMINAL.ITERM
        }

        // Add more Terminal choices by index here...
        // FROM 2.4.0 -- Support Ghostty
        if self.prefsTerminalChoiceGhostty.state == .on {
            termChoice = MNU_CONSTANTS.TERMINAL.GHOSTTY
        }

        // Only write out the choice if it's different -- it should be
        if termChoice != self.terminalChoice {
            self.terminalChoice = termChoice
            let defaults: UserDefaults = UserDefaults.standard
            defaults.set(termChoice, forKey: MNU_CONSTANTS.SETTINGS_IDS.TERMINAL)

            // Notify the mai app that it needs to change
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: MNU_CONSTANTS.NOTIFICATION_IDS.TERM_UPDATED),
                                            object: self)
        }
    }


    /**
     The user has toggled the 'auto separate' checkbox, so set a suitable
     notification to the app delegate.

     FROM 2.0.0
     */
    @IBAction
    private func doToggleAutoSeparate(sender: Any?) {

        let defaults: UserDefaults = UserDefaults.standard
        let state = self.prefsAutoSeparateSwitch.state == .on ? true : false
        defaults.set(state, forKey: MNU_CONSTANTS.SETTINGS_IDS.AUTO_SEPARATE)

        // Setting this disables manually created separators so enable/disable
        // the separator setting controls as required
        self.autoSeparateInForce = state
        self.menuItemsTableView.reloadData()

        // Notify the menu that it needs to change
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: MNU_CONSTANTS.NOTIFICATION_IDS.UPDATE_LIST),
                                        object: self)
    }


    /**
     The user has toggled the 'show direct output' checkbox, so set a suitable
     notification to the app delegate.

     FROM 2.0.0
     */
    @IBAction
    private func doToggleShowDirectOutput(sender: Any?) {

        let defaults: UserDefaults = UserDefaults.standard
        let state = self.prefsDirectOutputSwitch.state == .on ? true : false
        self.doShowOutput = state
        defaults.set(state, forKey: MNU_CONSTANTS.SETTINGS_IDS.SHOW_DIRECT_OUTPUT)

        // Notify the menu that it needs to change
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: MNU_CONSTANTS.NOTIFICATION_IDS.OUTPUT_UPDATED),
                                        object: self)
    }


    /**
     Show the 'Help' via the website.

     TODO provide offline help
     */
    @IBAction
    private func doShowHelp(sender: Any?) {

        var path: String = MNU_SECRETS.WEBSITE.URL_MAIN
        let button: NSButton = sender as! NSButton
        path += button == self.prefsHelpButton ? "#mnu-preferences" : "#how-to-configure-mnu"

        if let helpURL: URL = URL(string: path) {
            NSWorkspace.shared.open(helpURL)
        }
    }


    // MARK: - List Import/Export/Reset Functions

    /**
     Export the menu list as a backup. This currently outputs a plaintext JSON file.

     FROM 1.1.0
     */
    @objc
    private func doExport() {

        // Create a save panel for the export operation...
        let savePanel = NSSavePanel()

        // FROM 2.2.0 -- Monterey requirements
        if let fileType = UTType(filenameExtension: "json", conformingTo: .json) {
            savePanel.allowedContentTypes = [fileType]
        }

        savePanel.allowsOtherFileTypes = false
        savePanel.canCreateDirectories = true
        savePanel.nameFieldStringValue = "MNUItems"
        savePanel.directoryURL = FileManager.default.homeDirectoryForCurrentUser
        // FROM 2.2.0
        savePanel.isExtensionHidden = false
        

        // ...and show it
        savePanel.beginSheetModal(for: self.view.window!) { (response) in

            if response == NSApplication.ModalResponse.OK {
                // The user clicked the Save button
                guard let targetUrl = savePanel.url else { return }

                // Create a JSON string representation of the menu data
                do {
                    let dataString: String = try self.menuItems!.encode()

                    // Convert the string to data for saving
                    if let fileData: Data = dataString.data(using: String.Encoding.utf8) {

                        // Save the data
                        if !FileManager.default.createFile(atPath: targetUrl.path,
                                                           contents:fileData,
                                                           attributes: nil) {
                            self.showExportAlert()
                        }
                    }
                } catch {
                    self.showExportAlert()
                }
            }
        }
    }


    /**
     Multi-use call from `doExport()` (see above).

     FROM 1.1.0
     */
    private func showExportAlert() {

        showAlert("File Export Error",
                  "Sorry, but the menu items back-up file could not be created. Please try again.",
                  self.view.window!)
    }


    /**
     Import a backup menu item list.

     FROM 1.1.0
     */
    @objc
    private func doImport() {

        // Create an open panel for the import operation...
        let openPanel: NSOpenPanel = NSOpenPanel()
        openPanel.allowsOtherFileTypes = false
        openPanel.allowsMultipleSelection = false
        openPanel.directoryURL = FileManager.default.homeDirectoryForCurrentUser
        openPanel.delegate = self

        // FROM 2.1.0
        // Replace deprecated `allowedFileTypes` property
        if let fileType = UTType(filenameExtension: "json") {
            openPanel.allowedContentTypes = [fileType]
        }

        // ...and show it
        openPanel.beginSheetModal(for: self.view.window!) { (response) in

            if response == NSApplication.ModalResponse.OK {
                // The user clicked the Save button
                if let targetUrl = openPanel.url {
                    // Load the data if we have a valid file URL
                    do {
                        let fileData: Data = try Data(contentsOf: targetUrl)
                        let newMenu: MenuItemList = try MenuItemList.decode(fileData)
                        self.menuItems = newMenu
                        self.hasChanged = true
                        self.applyChangesButton.isEnabled = true
                        self.menuItemsTableView.reloadData()
                    } catch Serializer.error.BadGroupDeserialization {
                        showAlert("File Processing Error",
                                  "Sorry, but the menu items back-up file could not be processed. Is it a MNU file?",
                                  self.view.window!)
                    } catch {
                        showAlert("File Import Error",
                                  "Sorry, but the menu items back-up file could not be loaded from disk. Is it a MNU file?",
                                  self.view.window!)
                    }
                }
            }
        }
    }


    /**
     Factory Reset.
     */
    @objc
    private func restoreDefaults() {

        let alert: NSAlert = NSAlert()
        alert.messageText = "Are you sure you wish to restore MNU’s defaults?"
        alert.addButton(withTitle: "Yes")
        alert.addButton(withTitle: "No")
        alert.beginSheetModal(for: self.configureWindow!) { (response: NSApplication.ModalResponse) in
            if response == NSApplication.ModalResponse.alertFirstButtonReturn {
                // The user clicked 'Yes': notify the menu that it needs to change
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: MNU_CONSTANTS.NOTIFICATION_IDS.RESTORE_DEFAULTS),
                                                object: self)

                // App delegate will rebuild the item list, so the config
                // window is now redundant -- so close it. Also, we're implicitly ignoring
                // any exxisting changes made as the user has explicitly said YES to
                // restoring the defaults.
                self.hasChanged = false
                self.applyChangesButton.isEnabled = false
                self.configureWindow!.close()
            }
        }
    }


    /**
     Check for any files in the store that are no longer referenced, and delete them.

     FROM 2.1.0
     */
    @objc
    private func imageFileGarbageCollection() {

        if self.customIcons.count > 0 {
            do {
                // Iterate over the files in the store.
                let files = try FileManager.default.contentsOfDirectory(atPath: getImageStoreUrl("").unixpath())
                for file in files {
                    // Iterate over the custom icon list to see if any of them claim the file
                    var claimed = false
                    for customIcon in self.customIcons {
                        if customIcon.id == file && customIcon.inUse {
                            claimed = true
                            break
                        }
                    }

                    if !claimed {
                        // The file has no match in the custom icons list, so zap it as requested
                        do {
                            try FileManager.default.removeItem(atPath: getImageStoreUrl(file).unixpath())
                        } catch {
                            // TODO Better error presentation
                            print("Could not delete unused image file '\(file)' from the store")
                        }
                    }
                }
            } catch {
                // NOP
            }

            // Recreate the custom icons list
            getCustomIcons()
        }
    }


    // MARK: - Notification Handlers

    /**
     This function is called in response to a `MNU_CONSTANTS.NOTIFICATION_IDS.ITEM_ADDED` notification
     from the `AddUserItemViewController` that an existing item was edited, or a new item created
     */
    @objc
    private func processNewItem() {

        if !self.aivc.isEditing {
            // Add a newly created Menu Item to the list
            if let item: MenuItem = self.aivc.newMenuItem {
                if self.newMenuItemIndex != 0 {
                    self.menuItems!.items.insert(item, at: self.newMenuItemIndex + 1)
                } else {
                    self.menuItems!.items.append(item)
                }
            }
        }

        // FROM 1.6.0
        // Switch off editing mode for the AddUserItemViewController
        // NOTE Previously done in the controller's code
        self.aivc.isEditing = false

        // Update the Configure Window
        self.hasChanged = true
        self.applyChangesButton.isEnabled = true
        self.menuItemsTableView.reloadData()
        displayItemCount()

        // FROM 2.1.0
        // Get the custom icon list back from `AddUserItemViewController`
        self.customIcons = self.aivc.customIcons
    }


    // MARK: - TableView Data Source and Delegate Functions

    func numberOfRows(in tableView: NSTableView) -> Int {

        if let items: MenuItemList = self.menuItems {
            return items.items.count
        }

        return 0
    }


    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {

        if let items: MenuItemList = self.menuItems {
            let item: MenuItem = items.items[row]
            let cell: MenuItemTableCellView? = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "mnu-item-cell"),
                                                                  owner: self) as? MenuItemTableCellView

            if cell != nil {
                // Configure the cell's title and its three buttons
                // NOTE 'buttonA' is the right-most button
                cell!.title.stringValue = item.title

                // FROM 2.0.0
                // Is the item a separator line? If so this requires special text formatting
                if item.type == .separator {
                    let labelParagraphStyle = NSMutableParagraphStyle()
                    labelParagraphStyle.alignment = .left

                    var labelFont = NSFont.systemFont(ofSize: MNU_CONSTANTS.DEFAULT_SYSTEM_FONT_SIZE)
                    if let font: NSFont = NSFontManager.shared.font(withFamily: labelFont.familyName!,
                                                                    traits: .italicFontMask,
                                                                    weight: 5,
                                                                    size: MNU_CONSTANTS.DEFAULT_SYSTEM_FONT_SIZE) {
                        labelFont = font
                    }

                    let labelText = item.title + (self.autoSeparateInForce ? " only visible when separators not added automatically" : "")
                    let attrTitle = NSMutableAttributedString(string: labelText, attributes: [.font: labelFont,
                                                                                              .paragraphStyle: labelParagraphStyle,
                                                                                              .foregroundColor: self.autoSeparateInForce ? NSColor.gray : NSColor.controlAccentColor])

                    cell!.title.attributedStringValue = attrTitle

                    // FROM 2.2.0
                    // Add experimental signifier
                    let lineView = SeparatorView()
                    lineView.setFrameOrigin(CGPoint(x: attrTitle.width + 8.0, y: 15.0))
                    lineView.setFrameSize(CGSize(width: cell!.cellSwitch.frame.origin.x - attrTitle.width - 24.0, height: 2.0))
                    lineView.alphaValue = 0.5
                    cell!.addSubview(lineView, positioned: .below, relativeTo: cell!.title)
                    cell!.separatorView = lineView
                } else {
                    // FROM 2.2.0
                    // Zap any unneeded separators
                    if cell!.separatorView != nil {
                        cell!.separatorView!.removeFromSuperview()
                        cell!.separatorView = nil
                    }
                }

                // NOTE Buttons named in order, from the Left to Right
                cell!.buttonA.image = NSImage(named: "NSTouchBarDeleteTemplate")
                cell!.buttonA.contentTintColor = .controlAccentColor
                cell!.buttonA.action = #selector(self.doDeleteScript(sender:))
                cell!.buttonA.toolTip = "Delete this menu item"
                cell!.buttonA.isEnabled = true
                cell!.buttonA.controlSize = .small
                cell!.buttonA.imageScaling = .scaleProportionallyDown
                cell!.buttonA.menuItem = item

                cell!.buttonB.image = NSImage(named: "NSTouchBarComposeTemplate")
                cell!.buttonB.contentTintColor = .controlAccentColor
                cell!.buttonB.action = #selector(self.doTableButtonEditScript(sender:))
                cell!.buttonB.toolTip = "Edit this menu item"
                cell!.buttonB.isEnabled = item.type != .separator
                cell!.buttonB.controlSize = .small
                cell!.buttonB.imageScaling = .scaleProportionallyDown
                cell!.buttonB.menuItem = item

                // FROM 1.7.0
                // Drop Button C (red/green image button) in favour of a switch
                cell!.cellSwitch.menuItem = item
                cell!.cellSwitch.state = item.isHidden ? .off : .on
                cell!.cellSwitch.action = #selector(self.doShowHideSwitch(sender:))
                cell!.cellSwitch.toolTip = "Show or hide this menu item"
                cell!.cellSwitch.isEnabled = true
                cell!.cellSwitch.controlSize = .mini

                if item.type == .switch {
                    // This is a built-in switch, so disable the edit, delete buttons
                    cell!.buttonB.isEnabled = false
                    cell!.buttonA.isEnabled = false

                    // FROM 1.3.0
                    // Change tooltips for built-ins
                    cell!.buttonB.toolTip = "Built-in menu items can’t be edited"
                    cell!.buttonA.toolTip = "Built-in menu items can’t be deleted"
                }

                if item.type == .script && item.code != MNU_CONSTANTS.ITEMS.SCRIPT.USER {
                    // This is a built-in switch, so disable the edit button
                    cell!.buttonB.isEnabled = false
                    cell!.buttonB.toolTip = "Built-in menu items can’t be edited"
                }

                // FROM 2.0.0
                // Do we need to disable the cell?
                if item.type == .separator {
                    if self.autoSeparateInForce {
                        cell!.buttonA.isEnabled = false
                        cell!.buttonB.isEnabled = false
                        cell!.cellSwitch.isEnabled = false

                        cell!.buttonA.toolTip = "MNU-managed separators can’t be deleted"
                        cell!.buttonB.toolTip = "MNU-managed separators can’t be edited"
                        cell!.cellSwitch.toolTip = "MNU-managed separators are shown automatically"
                    } else {
                        cell!.buttonB.isEnabled = false
                        cell!.buttonB.toolTip = "Separators can’t be edited"
                    }
                }

                return cell
            }
        }

        return nil
    }


    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {

        return MNU_CONSTANTS.CONFIG_TABLE_ROW_HEIGHT
    }


    func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {

        if let items: MenuItemList = self.menuItems {
            let item: MenuItem = items.items[row]
            let pasteboardItem: NSPasteboardItem = NSPasteboardItem()
            pasteboardItem.setString(item.title, forType: self.mnuPasteboardType)
            return pasteboardItem
        }

        return nil
    }


    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {

        if dropOperation == .above {
            return .move
        } else {
            return []
        }
    }


    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        guard
            let item = info.draggingPasteboard.pasteboardItems?.first,
            let itemTitle = item.string(forType: self.mnuPasteboardType)
            else { return false }

        var originalRow = -1
        if let items: MenuItemList = self.menuItems {
            for i in 0..<items.items.count {
                let anItem: MenuItem = items.items[i]
                if anItem.title == itemTitle {
                    originalRow = i
                }
            }

            var newRow = row
            if originalRow < newRow { newRow = row - 1 }

            // Animate the rows
            tableView.beginUpdates()
            tableView.moveRow(at: originalRow, to: newRow)
            tableView.endUpdates()

            // Move the list items
            let anItem: MenuItem = items.items[originalRow]
            items.items.remove(at: originalRow)
            items.items.insert(anItem, at: newRow)

            self.hasChanged = true

            // FROM 1.3.1 - bugfix: enable Apply button
            self.applyChangesButton.isEnabled = true

            return true
        }

        return false
    }


    // MARK: - NSWindowDelegate Functions

    func windowShouldClose(_ sender: NSWindow) -> Bool {

        // Before the Configure Window closes, check for un-applied changes
        // NOTE This follows from any call to 'doCancel()'
        guard self.hasChanged else { return true }

        // There are unsaved changes - warn the user
        let alert: NSAlert = NSAlert()
        alert.messageText = "You have unapplied changes"
        alert.informativeText = "Do you wish to apply the changes you have made before closing the Configure MNU window?"
        alert.addButton(withTitle: "Yes")
        alert.addButton(withTitle: "No")

        if !self.lastChance {
            alert.addButton(withTitle: "Cancel")
        }

        alert.beginSheetModal(for: self.configureWindow!) { (selection) in
            if selection == NSApplication.ModalResponse.alertFirstButtonReturn {
                // The user said YES, so add MNU to the login items system preference
                self.doSave(sender: nil)
            }

            if selection != NSApplication.ModalResponse.alertThirdButtonReturn {
                // The user said YES or NO, so close the window
                self.configureWindow!.close()

                if self.lastChance {
                    // We're bailing, so inform the host app we can quit at last
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: MNU_CONSTANTS.NOTIFICATION_IDS.CAN_QUIT),
                                                    object: self)
                }
            }
        }

        // Dont' close yet
        return false
    }


    // MARK: - Key Event Handling Functions

    override func keyDown(with event: NSEvent) {

        // Catch key events to trap ESC (close window), arrows (cycle through tabs), CMD-M (minimize)

        if event.keyCode == MNU_CONSTANTS.MENU_ESC_KEY {
            // ESC key pressed
            // Make sure the sheets aren't visible and close
            if self.aivc.parentWindow == nil && self.fbvc.parentWindow == nil {
                doCancel(sender: self)
            }

            return
        }

        if (event.keyCode == MNU_CONSTANTS.MENU_ARR_KEY) {
            // Right Arrow key pressed
            // Cycle through the tabs in that direction
            if self.aivc.parentWindow == nil && self.fbvc.parentWindow == nil {
                if let selectedTab: NSTabViewItem = self.windowTabView.selectedTabViewItem {
                    let index: Int = self.windowTabView.indexOfTabViewItem(selectedTab)
                    if index == 2 {
                        self.windowTabView.selectTabViewItem(at: 0)
                        return
                    }
                }

                self.windowTabView.selectNextTabViewItem(self)
                return
            }
        }

        if (event.keyCode == MNU_CONSTANTS.MENU_ARL_KEY) {
            // Left Arrow key pressed
            // Cycle through the tabs in that direction
            if self.aivc.parentWindow == nil && self.fbvc.parentWindow == nil {
                if let selectedTab: NSTabViewItem = self.windowTabView.selectedTabViewItem {
                    let index: Int = self.windowTabView.indexOfTabViewItem(selectedTab)
                    if index == 0 {
                        self.windowTabView.selectTabViewItem(at: 2)
                        return
                    }
                }

                self.windowTabView.selectPreviousTabViewItem(self)
                return
            }
        }

        if event.keyCode == 46 && event.modifierFlags.contains(NSEvent.ModifierFlags.command) {
            // CMD-M pressed
            // Minimize the window
            self.configureWindow!.miniaturize(self)
            return
        }

        // Pass on allow other key events
        super.keyDown(with: event)
    }


    // MARK: - NSMenuDelegate Functions

    func menuNeedsUpdate(_ menu: NSMenu) {

        // We come here before displaying the NSTableView's set contextual menu
        // (its 'menu' property, set in Interface Builder) in order to update
        // the menu's items for the Menu Item clicked on

        // Get the NSTableView row that the user clicked
        let clickedRow: Int = self.menuItemsTableView.clickedRow

        if clickedRow > -1 {
            // If the click was on a valid row, use that index to
            // get the MenuItem represented at the clicked row
            if let items: MenuItemList = self.menuItems {
                let item: MenuItem = items.items[clickedRow]
                // Set the contextual menu's three items (Show/Hide, Edit, Delete)
                // to point to the Menu Item represented at the clicked row
                menu.item(at: MNU_CONSTANTS.CONFIG_TABLE_CONTEXT_MENU.SHOW_HIDE)!.representedObject = item
                menu.item(at: MNU_CONSTANTS.CONFIG_TABLE_CONTEXT_MENU.EDIT)!.representedObject = item
                menu.item(at: MNU_CONSTANTS.CONFIG_TABLE_CONTEXT_MENU.DELETE)!.representedObject = item
                menu.item(at: MNU_CONSTANTS.CONFIG_TABLE_CONTEXT_MENU.NEW)!.representedObject = item
                menu.item(at: MNU_CONSTANTS.CONFIG_TABLE_CONTEXT_MENU.SEPARATOR)!.representedObject = item

                // Contextualise the Show/Hide menu item's title
                menu.item(at: MNU_CONSTANTS.CONFIG_TABLE_CONTEXT_MENU.SHOW_HIDE)?.title = item.isHidden ? "Show" : "Hide"

                // Assume all of the NSMenuItems are required...
                menu.item(at: MNU_CONSTANTS.CONFIG_TABLE_CONTEXT_MENU.SHOW_HIDE)!.isEnabled = true
                menu.item(at: MNU_CONSTANTS.CONFIG_TABLE_CONTEXT_MENU.EDIT)!.isEnabled = true
                menu.item(at: MNU_CONSTANTS.CONFIG_TABLE_CONTEXT_MENU.DELETE)!.isEnabled = true
                menu.item(at: MNU_CONSTANTS.CONFIG_TABLE_CONTEXT_MENU.NEW)!.isEnabled = true
                menu.item(at: MNU_CONSTANTS.CONFIG_TABLE_CONTEXT_MENU.SEPARATOR)!.isEnabled = !self.autoSeparateInForce

                // ... but disabled those that are not needed by the Menu Item
                // (ie. it represents a built-in item)
                if item.type == .switch || item.code != MNU_CONSTANTS.ITEMS.SCRIPT.USER {
                    menu.item(at: MNU_CONSTANTS.CONFIG_TABLE_CONTEXT_MENU.EDIT)!.isEnabled = false
                    menu.item(at: MNU_CONSTANTS.CONFIG_TABLE_CONTEXT_MENU.DELETE)!.isEnabled = false
                }

                // FROM 2.0.0
                // Turn off editing for separators
                if item.type == .separator {
                    menu.item(at: MNU_CONSTANTS.CONFIG_TABLE_CONTEXT_MENU.EDIT)!.isEnabled = false
                }
            }
        }
    }


    // MARK: - NSTabViewDelegate Functions

    func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {

        // Catch tab view changes to prevent the view controller from being
        // dropped from the window's responder chain. We need to do this in
        // order to ensure the view controller continues to handle the key down
        // events it is watching out for.
        self.configureWindow!.makeFirstResponder(self)
    }


    // MARK: - Misc Functions

    /**
     Update the count of current menu items and present it in the relevant label.
     */
    private func displayItemCount() {

        var total = 0
        var count = 0

        if let list: MenuItemList = self.menuItems {
            if list.items.count > 0 {
                for item: MenuItem in list.items {
                    if !item.isHidden { //}&& item.type != .separator {
                        // Real items, visible
                        count += 1
                    }

                    total += 1
                }
            }
        }

        // Handle plurals in the text correctly, and subsitite 'no' for '0'
        let itemText: String = count == 1 ? "item" : "items"
        let countText: String = count == 0 ? "no" : "\(count)"

        // Display the text
        menuItemsCountText.stringValue = "MNU will show \(countText) of \(total) \(itemText) (Option-click MNU to show all items)"
    }


    /**
     Check that the user has not added too many items already
     current limit is set as ` MNU_CONSTANTS.MAX_ITEM_COUNT'.

     TODO Calculate the number of DISPLAYED items and limit that rather than the total

     */
    private func checkMenuItemCount() -> Bool {

        if let items: MenuItemList = self.menuItems {
            if items.items.count >= MNU_CONSTANTS.MAX_ITEM_COUNT {
                // Limit reached - warn the user
                let alert: NSAlert = NSAlert()
                alert.messageText = "You have already added the maximum number of items to MNU"
                alert.informativeText = "MNU can only show \(MNU_CONSTANTS.MAX_ITEM_COUNT) items. Please delete an item before adding a new one."
                alert.addButton(withTitle: "OK")
                alert.beginSheetModal(for: self.configureWindow!,
                                      completionHandler: nil)
                return false
            }
        }

        return true
    }


    /**
     Generate the three tabs used in this app and controlled by `tabManager`.

     - Parameters:
        - atm: A TabManager instance.
     */
    private func makeTabs(_ atm: PMTabManager) {

        let listTab = PMTab()
        listTab.name = "list"
        listTab.isResizeable = true
        listTab.defaultSize = MNU_CONSTANTS.CONFIG_TAB_PANEL_SIZE.MENU_LIST
        listTab.minimumSize = listTab.defaultSize
        listTab.maximumSize = MNU_CONSTANTS.CONFIG_TAB_PANEL_SIZE.MENU_LIST_MAX
        listTab.button = self.self.tabButtonMenu

        let settingsTab = PMTab()
        settingsTab.name = "settings"
        settingsTab.defaultSize = MNU_CONSTANTS.CONFIG_TAB_PANEL_SIZE.SETTINGS
        settingsTab.button = self.tabButtonSettings

        let aboutTab = PMTab()
        aboutTab.name = "settings"
        aboutTab.defaultSize = MNU_CONSTANTS.CONFIG_TAB_PANEL_SIZE.ABOUT
        aboutTab.button = self.tabButtonAbout

        atm.tabs = [listTab, settingsTab, aboutTab]
        atm.parentController = self
        atm.parentWindow = self.configureWindow
    }


    /**
     Called when just before the Config window appears, we use it to set a 'maximum content'
     window size for the List tab based on the number of items in the list.

     FROM 2.2.0
     */
    private func setListTabSize() {

        guard self.tabManager.tabs.count > 0 else { return }

        // Check for nil in case the user has altered the window size
        let listTab = self.tabManager.tabs[0]
        if listTab.currentSize == nil {
            // Count the total number of MNU items in the list and the
            // number of those that are set to be visible
            let itemCount: Double
            if let items: MenuItemList = self.menuItems {
                itemCount = Double(items.items.count)
            } else {
                itemCount = 1.0
            }

            listTab.currentSize = NSSize(width: 600.0, height: 190.0 + (itemCount * 32.0))
        }
    }
}
