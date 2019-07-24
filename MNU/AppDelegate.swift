
//  AppDelegate.swift
//  MNU
//
//  Created by Tony Smith on 03/07/2019.
//  Copyright © 2019 Tony Smith. All rights reserved.


import Cocoa


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    //@IBOutlet weak var window: NSWindow!
    //@IBOutlet weak var myMenu: NSMenu!

    // MARK: - UI Properties

    @IBOutlet weak var modeSwitchView: NSView!
    @IBOutlet weak var modeSwitchControl: NSSegmentedControl!
    @IBOutlet weak var modeSwitchText: NSTextField!

    @IBOutlet weak var appInfoView: NSView!
    @IBOutlet weak var appInfoControl: NSButton!

    @IBOutlet weak var cwvc: ConfigureViewController!

    
    // MARK: - App Properties

    var statusItem: NSStatusItem? = nil
    var appMenu: NSMenu? = nil
    var inDarkMode: Bool = false
    var useDesktop: Bool = false
    var disableDarkMode: Bool = false
    var items: [MNUitem] = []
    var task: Process? = nil


    // MARK: - App Lifecycle Functions

    func applicationDidFinishLaunching(_ aNotification: Notification) {

        // First ensure we are running on Mojave or above -
        // Dark Mode not supported by earlier versons
        let sysVer: OperatingSystemVersion = ProcessInfo.processInfo.operatingSystemVersion
        if sysVer.minorVersion < 14 {
            // Wrong version!
            let alert = NSAlert.init()
            alert.messageText = "Unsupported version of macOS"
            alert.informativeText = "MNU makes use of features not present in the version of macOS (\(sysVer.majorVersion).\(sysVer.minorVersion).\(sysVer.patchVersion)) running on your computer. Please conisder upgrading to macOS 10.14 or higher."
            alert.addButton(withTitle: "OK")
            alert.runModal()
            self.disableDarkMode = true
        }

        // Set the default values for the states we control
        self.inDarkMode = false
        self.useDesktop = true

        // Use the standard user defaults to first determine whether the host Mac is in Dark Mode,
        // and the the other states of supported switches
        let defaults: UserDefaults = UserDefaults.standard
        var defaultsDict: [String:Any] = defaults.persistentDomain(forName: UserDefaults.globalDomain)!
        if let darkModeDefault = defaultsDict["AppleInterfaceStyle"] {
            self.inDarkMode = (darkModeDefault as! String == "Dark") ? true : false
        }

        defaultsDict = defaults.persistentDomain(forName: "com.apple.finder")!
        if let useDesktopDefault = defaultsDict["CreateDesktop"] {
            self.useDesktop = (useDesktopDefault as! String == "0") ? false : true
        }

        // Register preferences
        registerPreferences()

        // Create the app's menu
        createMenu()

        // Watch for item list changes sent by the configure window controller
        let nc = NotificationCenter.default
        nc.addObserver(self,
                       selector: #selector(self.updateMenu),
                       name: NSNotification.Name(rawValue: "com.bps.mnu.list-updated"),
                       object: nil)

    }


    func applicationWillTerminate(_ aNotification: Notification) {

        // Insert code here to tear down your application
    }


    // MARK: - App Action Functions

    @IBAction @objc func doModeSwitch(sender: Any?) {

        // Set up the script that will switch the UI mode
        var arg: String = "tell application \"System Events\" to tell appearance preferences to set dark mode to "

        // Modify the script according to user selection
        let modeSwitch: NSButton = sender as! NSButton

        if modeSwitch.state == NSControl.StateValue.off {
            // Light Mode
            arg += "false"
            self.inDarkMode = false
        } else {
            // Dark mode
            arg += "true"
            self.inDarkMode = true
        }

        // Update the menu item image
        if let item: MNUitem = itemWithTitle(MNU_CONSTANTS.BUILT_IN_TITLES.UIMODE) {
            let controller = item.controller! as! SwitchItemViewController
            controller.setImage(isOn: self.inDarkMode)
        }

        // Run the AppleScript
        let aps: NSAppleScript = NSAppleScript.init(source: arg)!
        aps.executeAndReturnError(nil)

        // Close the menu - required for controls within views added to menu items
        self.appMenu!.cancelTracking()

        // Run the task
        //runProcess(app: "/usr/bin/osascript", with: [arg], doBlock: true)
    }


    @IBAction @objc func doDesktopSwitch(sender: Any?) {

        // Get the defaults for Finder as this contains the 'use desktop' option
        let defaults: UserDefaults = UserDefaults.standard
        var defaultsDict: [String:Any] = defaults.persistentDomain(forName: "com.apple.finder")!

        // Has the user switched the desktop on or off?
        let deskSwitch: NSButton = sender as! NSButton

        if deskSwitch.state == NSControl.StateValue.on {
            // Desktop is ON, so remove the 'CreateDesktop' key from 'com.apple.finder'
            defaultsDict.removeValue(forKey: "CreateDesktop")
            self.useDesktop = true
        } else {
            // Desktop is OFF, so add the 'CreateDesktop' key, with value 0, to 'com.apple.finder'
            defaultsDict["CreateDesktop"] = 0
            self.useDesktop = false
        }

        // Write the defaults back out
        defaults.setPersistentDomain(defaultsDict, forName: "com.apple.finder")

        // Close the menu - required for controls within views added to menu items
        // self.appMenu!.cancelTracking()

        if let item: MNUitem = itemWithTitle(MNU_CONSTANTS.BUILT_IN_TITLES.DESKTOP) {
            let controller = item.controller! as! SwitchItemViewController
            controller.setImage(isOn: self.useDesktop)
        }
        // Run the task to restart the Finder
        killFinder(andDock: false)
    }


    @IBAction @objc func doGit(sender: Any?) {

        // Set up the script that will open Terminal and run 'gitup'
        let script: NSAppleScript = NSAppleScript.init(source: "tell application \"Terminal\"\nactivate\ndo script (\"gitup\") in tab 1 of window 1\nend tell")!
        script.executeAndReturnError(nil)

        // Close the menu - required for controls within views added to menu items
        self.appMenu!.cancelTracking()

        /*
        let args: [String] = ["-e tell application \"Terminal\" to activate", "-e tell application \"Terminal\" to do script (\"gitup\")"]

        // Run the task
        runProcess(app: "/usr/bin/osascript", with: args, doBlock: true)
         */
    }


    @IBAction @objc func doBrew(sender: Any?) {

        // Set up the script that will open Terminal and run 'brew update'
        let script: NSAppleScript = NSAppleScript.init(source: "tell application \"Terminal\"\nactivate\ndo script (\"brew update\") in tab 1 of window 1\nend tell")!
        script.executeAndReturnError(nil)

        // Close the menu - required for controls within views added to menu items
        self.appMenu!.cancelTracking()
    }

    
    @IBAction @objc func doScript(sender: Any?) {

        // Get the source for the script item
        let theButton: NSButton = sender as! NSButton

        for item in self.items {
            if item.type == MNU_CONSTANTS.TYPES.SCRIPT && item.code == MNU_CONSTANTS.ITEMS.SCRIPT.USER {
                let controller: ScriptItemViewController = item.controller as! ScriptItemViewController
                if controller.itemButton == theButton {
                    let scriptText = "tell application \"Terminal\"\nactivate\ndo script (\"\(item.script)\") in tab 1 of window 1\nend tell"
                    let script: NSAppleScript = NSAppleScript.init(source: scriptText)!
                    script.executeAndReturnError(nil)
                }
            }
        }

        // Close the menu - required for controls within views added to menu items
        self.appMenu!.cancelTracking()
    }


    @IBAction @objc func doQuit(sender: Any?) {

        // Quit the app
        NSApp.terminate(self)
    }


    @IBAction @objc func doHelp(sender: Any?) {

        // Show the 'Help' via the website
        // TODO provide offline help
        NSWorkspace.shared.open(URL.init(string:"https://smittytone.github.io/squinter/index.html")!)
    }


    @IBAction @objc func doConfigure(sender: Any?) {

        // Duplicate the current item list to pass on to the configure window view controller
        let list: MNUitemList = MNUitemList()

        if self.items.count > 0 {
            for item: MNUitem in self.items {
                let itemCopy: MNUitem = item.copy() as! MNUitem
                list.items.append(itemCopy)
            }
        }

        self.cwvc.items = list
        self.cwvc.menuItemsTableView.reloadData()

        // Close the menu - required for controls within views added to menu items
        self.appMenu!.cancelTracking()

        // Tell the configure window controller to show its window
        self.cwvc.show()
    }


    // MARK: - Menu And View Controller Maker Functions

    @objc func createMenu() {

        // Create the app's menu
        let defaults = UserDefaults.standard
        var index = 0
        self.appMenu = NSMenu.init(title: "MNU")
        self.items.removeAll()

        // Get the stored list of switch items and iterate through it, adding
        // the specified item as we go
        // NOTE For now this replicates a fixed order, but will allow us to support
        //      the user specifying a new order later on
        let menuItems: [Int] = defaults.array(forKey: "com.bps.mnu.item-order") as! [Int]
        let userItems: [MNUitem] = defaults.array(forKey: "com.bps.mbu.user-items") as! [MNUitem]

        for itemCode in menuItems {
            if itemCode == MNU_CONSTANTS.ITEMS.SWITCH.UIMODE {
                // Create and add a Light/Dark Mode MNU item
                let newItem = MNUitem()
                newItem.title = MNU_CONSTANTS.BUILT_IN_TITLES.UIMODE
                newItem.code = itemCode
                newItem.type = MNU_CONSTANTS.TYPES.SWITCH
                newItem.index = index
                index += 1

                // Create its controller
                let controller: SwitchItemViewController = makeSwitchController(title: "macOS Dark Mode")
                controller.offImageName = "light_mode_icon"
                controller.onImageName = "dark_mode_icon"
                controller.state = self.inDarkMode
                controller.action = #selector(self.doModeSwitch(sender:))
                newItem.controller = controller

                // Add the new item to the stored list
                self.items.append(newItem)

                // Create the menu item that will display the MNU item
                let menuItem: NSMenuItem = NSMenuItem.init(title: newItem.title,
                                                           action: nil,
                                                           keyEquivalent: "")
                menuItem.view = controller.view

                // If we're running on a version of macOS that doesn't do Dark Mode, grey out
                // the control and disable the switch
                if (self.disableDarkMode) {
                    controller.itemSwitch.isEnabled = false
                    controller.itemText.textColor = NSColor.secondaryLabelColor
                    controller.itemImage.alphaValue = 0.4
                }

                // Add the menu item and a separator
                self.appMenu!.addItem(menuItem)
                self.appMenu!.addItem(NSMenuItem.separator())
            }

            if itemCode == MNU_CONSTANTS.ITEMS.SWITCH.DESKTOP {
                // Create and add a Desktop Usage MNU Item
                let newItem = MNUitem()
                newItem.title = MNU_CONSTANTS.BUILT_IN_TITLES.DESKTOP
                newItem.code = itemCode
                newItem.type = MNU_CONSTANTS.TYPES.SWITCH
                newItem.index = index
                index += 1

                // Create its controller
                let controller: SwitchItemViewController = makeSwitchController(title: newItem.title)
                controller.onImageName = "desktop_icon_on"
                controller.offImageName = "desktop_icon_off"
                controller.state = self.useDesktop
                controller.action = #selector(self.doDesktopSwitch(sender:))
                newItem.controller = controller

                // Add the new item to the stored list
                self.items.append(newItem)

                // Create the menu item that will display the MNU item
                let menuItem: NSMenuItem = NSMenuItem.init(title: newItem.title,
                                                           action: nil,
                                                           keyEquivalent: "")
                menuItem.view = controller.view
                self.appMenu!.addItem(menuItem)
                self.appMenu!.addItem(NSMenuItem.separator())
            }

            if itemCode == MNU_CONSTANTS.ITEMS.SCRIPT.GIT {
                // Add the Git Update item
                let newItem = MNUitem()
                newItem.title = MNU_CONSTANTS.BUILT_IN_TITLES.GIT
                newItem.code = itemCode
                newItem.type = MNU_CONSTANTS.TYPES.SCRIPT
                newItem.index = index
                index += 1

                let controller: ScriptItemViewController = makeScriptController(title: newItem.title)
                controller.offImageName = "logo_gt"
                controller.onImageName = "logo_gt"
                controller.action = #selector(self.doGit(sender:))
                newItem.controller = controller

                // Add the new item to the stored list
                self.items.append(newItem)

                // Create the menu item that will display the MNU item
                let menuItem: NSMenuItem = NSMenuItem.init(title: newItem.title,
                                                           action: nil,
                                                           keyEquivalent: "")
                menuItem.view = controller.view
                self.appMenu!.addItem(menuItem)
                self.appMenu!.addItem(NSMenuItem.separator())
            }

            if itemCode == MNU_CONSTANTS.ITEMS.SCRIPT.BREW {
                // Add the Brew Update item
                let newItem = MNUitem()
                newItem.title = MNU_CONSTANTS.BUILT_IN_TITLES.BREW
                newItem.code = itemCode
                newItem.type = MNU_CONSTANTS.TYPES.SCRIPT
                newItem.index = index
                index += 1

                let controller: ScriptItemViewController = makeScriptController(title: newItem.title)
                controller.offImageName = "logo_br"
                controller.onImageName = "logo_br"
                controller.action = #selector(self.doBrew(sender:))
                newItem.controller = controller
                
                // Add the new item to the stored list
                self.items.append(newItem)

                // Create the menu item that will display the MNU item
                let menuItem: NSMenuItem = NSMenuItem.init(title: newItem.title,
                                                           action: nil,
                                                           keyEquivalent: "")
                menuItem.view = controller.view
                self.appMenu!.addItem(menuItem)
                self.appMenu!.addItem(NSMenuItem.separator())
            }

            if itemCode == MNU_CONSTANTS.ITEMS.SCRIPT.USER {
                // Add a user item

                // Check we have valid data to use
                assert(userItems.count == 0 || userItems.count < index)

                let source: MNUitem = userItems[index]

                let newItem = MNUitem()
                newItem.title = source.title
                newItem.code = itemCode
                newItem.type = MNU_CONSTANTS.TYPES.SCRIPT
                newItem.index = index
                index += 1

                let controller: ScriptItemViewController = makeScriptController(title: newItem.title)
                controller.offImageName = "logo_gen"
                controller.onImageName = "logo_gen"
                controller.action = #selector(self.doScript(sender:))
                newItem.controller = controller

                // Add the new item to the stored list
                self.items.append(newItem)

                // Create the menu item that will display the MNU item
                let menuItem: NSMenuItem = NSMenuItem.init(title: newItem.title,
                                                           action: nil,
                                                           keyEquivalent: "")
                menuItem.view = controller.view
                menuItem.representedObject = source
                self.appMenu!.addItem(menuItem)
                self.appMenu!.addItem(NSMenuItem.separator())
            }
        }

        // Finnally, add the app menu
        addAppMenuItem()

        // Now add the app menu to the macOS menu bar
        let bar: NSStatusBar = NSStatusBar.system
        self.statusItem = bar.statusItem(withLength: NSStatusItem.squareLength)

        if self.statusItem != nil && self.appMenu != nil {
            self.statusItem!.button!.image = NSImage.init(named: "menu_icon")
            self.statusItem!.button!.isHighlighted = false
            self.statusItem!.behavior = NSStatusItem.Behavior.terminationOnRemoval
            self.statusItem!.menu = self.appMenu!
            self.statusItem!.button!.toolTip = "Handy actions in one place"
            self.statusItem!.isVisible = true
        } else {
            NSLog("Could not initialise menu")
        }
    }


    func addAppMenuItem() {

        // Add the Info/Help Item
        let appItem: NSMenuItem = NSMenuItem.init(title: "APP-INFO",
                                                  action: #selector(self.doHelp),
                                                  keyEquivalent: "")
        appItem.view = self.appInfoView
        appItem.target = self;
        self.appMenu!.addItem(appItem)
    }


    @objc func updateMenu() {

        // Received a menu order update notification
        if let itemList: MNUitemList = cwvc.items {
            self.items.removeAll()
            self.items = itemList.items
        }

        // Clear the menu in order to rebuild it
        self.appMenu!.removeAllItems()

        for item in self.items {
            // If the item is not hidden, add it to the menu
            if !item.isHidden {
                // Create ann NSMenuItem that will display the current MNU item
                let menuItem: NSMenuItem = NSMenuItem.init(title: item.title,
                                                           action: nil,
                                                           keyEquivalent: "")

                // Set the NSMenuItem's view to that maintained by the MNU item's controller
                if item.type == MNU_CONSTANTS.TYPES.SCRIPT {
                    let controller: ScriptItemViewController = item.controller as! ScriptItemViewController
                    menuItem.view = controller.view

                    if item.code == MNU_CONSTANTS.ITEMS.SCRIPT.USER {
                        // The controller for a user item may not have been assigned a selector yet, so do it here
                        controller.action = #selector(self.doScript(sender:))
                        controller.itemButton.action = controller.action
                        controller.itemText.stringValue = item.title
                    }
                } else {
                    let controller: SwitchItemViewController = item.controller as! SwitchItemViewController
                    menuItem.view = controller.view
                }

                // Add the menu item and a separator
                self.appMenu!.addItem(menuItem)
                self.appMenu!.addItem(NSMenuItem.separator())
            }
        }

        // Finally, add the app menu item at the end of the menu
        addAppMenuItem()
    }


    func makeSwitchController(title: String) -> SwitchItemViewController {

        // Create and return a new generic switch view controller
        let controller: SwitchItemViewController = SwitchItemViewController.init(nibName: nil, bundle: nil)
        controller.text = title
        controller.state = false
        return controller
    }


    func makeScriptController(title: String) -> ScriptItemViewController {

        // Create and return a new generic button view controller
        let controller: ScriptItemViewController = ScriptItemViewController.init(nibName: nil, bundle: nil)
        controller.text = title
        controller.state = true
        return controller
    }


    // MARK: - Helper Functions

    func registerPreferences() {

        // Called by the app at launch to register its initial defaults
        // Set up the following keys/values:
        //   "com.bps.mnu.item-order" - An array of item type integers
        //   "com.bps.mbu.user-items" - An array of user-created items

        // NOTE The index of a user item in the 'item-order' array is its location in the menu.
        //      Iterating through the user items in 'user-items' will yield an item with an 'index'
        //      property which matches the location in the menu

        let keyArray: [String] = ["com.bps.mnu.item-order", "com.bps.mbu.user-items"]

        let valueArray: [[Any]] = [[MNU_CONSTANTS.ITEMS.SWITCH.UIMODE, MNU_CONSTANTS.ITEMS.SWITCH.DESKTOP,
                                    MNU_CONSTANTS.ITEMS.SCRIPT.GIT, MNU_CONSTANTS.ITEMS.SCRIPT.BREW], []]

        assert(keyArray.count == valueArray.count)
        let defaultsDict = Dictionary(uniqueKeysWithValues: zip(keyArray, valueArray))
        let defaults = UserDefaults.standard
        defaults.register(defaults: defaultsDict)
        defaults.synchronize()
    }


    func itemWithTitle(_ title: String) -> MNUitem? {

        for item in self.items {
            if item.title == title {
                return item
            }
        }

        return nil
    }


    // MARK: - External Process Management Functions

    func killFinder(andDock: Bool) {

        // Set up a task to kill the macOS Finder and, optionally, the Dock
        var args: [String] =  ["Finder"]
        if andDock { args.append("Dock") }
        runProcess(app: "/usr/bin/killall", with: args, doBlock: true)
    }


    func runProcess(app path: String, with args: [String], doBlock: Bool) {

        // Generic task creation and run function
        let task: Process = Process()
        task.launchPath = path
        if args.count > 0 { task.arguments = args }

        // Pipe out the output to avoid putting it in the log
        let pipe = Pipe()
        task.standardOutput = pipe

        task.launch()

        if doBlock {
            // Block until the task has completed (short tasks ONLY)
            task.waitUntilExit()
        }
    }

}

