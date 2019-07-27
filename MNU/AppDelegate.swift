
/*
    AppDelegate.swift
    MNU

    Created by Tony Smith on 03/07/2019.
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


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    //@IBOutlet weak var window: NSWindow!
    //@IBOutlet weak var myMenu: NSMenu!

    // MARK: - UI Outlets

    @IBOutlet weak var appControlView: NSView!              // The last view on the menu is the control bar
    @IBOutlet weak var appControlQuitButton: NSButton!      // The Quit button
    @IBOutlet weak var appControlConfigureButton: NSButton! // The Configure button
    @IBOutlet weak var appControlHelpButton: NSButton!      // The Help button
    @IBOutlet weak var cwvc: ConfigureViewController!       // The Configure window controller

    
    // MARK: - App Properties

    var statusItem: NSStatusItem? = nil         // The macOS main menu item providing the menu
    var appMenu: NSMenu? = nil                  // The NSMenu presenting the switches and scripts
    var inDarkMode: Bool = false                // Is the Mac in dark mode (true) or not (false)
    var useDesktop: Bool = false                // Is the Finder using the desktop (true) or not (false)
    var showHidden: Bool = false                // Is the Finder showing hidden files (true) or not (false)
    var disableDarkMode: Bool = false           // Should the menu disable the dark mode control (ie. not supported on the host)
    var hasChanged: Bool = false                // Has the user changed the menu entries at all?
    var items: [MenuItem] = []                  // The menu items that are present (but may be hidden)
    var task: Process? = nil


    // MARK: - App Lifecycle Functions

    func applicationDidFinishLaunching(_ aNotification: Notification) {

        // First ensure we are running on Mojave or above - Dark Mode is not supported by earlier versons
        let sysVer: OperatingSystemVersion = ProcessInfo.processInfo.operatingSystemVersion
        if sysVer.minorVersion < 14 {
            // Wrong version, so present a warnin message
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
        self.showHidden = false

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

        if let doShowHidden = defaultsDict["AppleShowAllFiles"] {
            self.showHidden = (doShowHidden as! String == "YES") ? true : false
        }

        // MARK: DEBUG SWITCHES
        // Uncomment the next line to wipe stored prefs
        //defaults.set([], forKey: "com.bps.mnu.item-order")

        // Register preferences
        registerPreferences()

        // Check for first run
        firstRunCheck()

        // Set Tooltips
        setTooltips()

        // Create the app's menu
        createMenu()

        // Enable notification watching
        let nc = NotificationCenter.default
        nc.addObserver(self,
                       selector: #selector(self.updateMenu),
                       name: NSNotification.Name(rawValue: "com.bps.mnu.list-updated"),
                       object: cwvc)

        // Watch for changes to the startup launch preferemce
        nc.addObserver(self,
                       selector: #selector(self.enableAutoStart),
                       name: NSNotification.Name(rawValue: "com.bps.mnu.startup-enabled"),
                       object: cwvc)
        nc.addObserver(self,
                       selector: #selector(self.disableAutoStart),
                       name: NSNotification.Name(rawValue: "com.bps.mnu.startup-disabled"),
                       object: cwvc)

    }


    func applicationWillTerminate(_ aNotification: Notification) {

        if self.hasChanged {
            // Store the current state of the menu if it has changed
            // NOTE We convert Menu Item objects into basic JSON strings and save
            //      these into an array that we will use to recreate the Menu Item list
            //      at next start up. This is because Strings can be PLIST'ed whereas
            //      custom objects cannot
            var savedItems: [Any] = []

            for item: MenuItem in self.items {
                savedItems.append(jsonize(item))
            }

            let defaults = UserDefaults.standard
            defaults.set(savedItems, forKey: "com.bps.mnu.item-order")
            defaults.synchronize()
        }

        // Disable notification listening (to be tidy)
        let nc = NotificationCenter.default
        nc.removeObserver(self)
    }


    func firstRunCheck() {

        // Read  in the defaults to see if this is MNU's first run: value will be true
        let defaults: UserDefaults = UserDefaults.standard
        if defaults.bool(forKey: "com.bps.menu.first-run") {
            // This is the first run - set the default to false
            defaults.set(false, forKey: "com.bps.menu.first-run")

            // Ask the user if they want to run MNU at startup
            let alert = NSAlert.init()
            alert.messageText = "Run MNU at Login?"
            alert.informativeText = "Do you wish to set your Mac to run MNU when you log in?\nThis can also be set in MNU’s Preferences."
            alert.addButton(withTitle: "Yes")
            alert.addButton(withTitle: "No")
            let selection: NSApplication.ModalResponse = alert.runModal()
            if selection == NSApplication.ModalResponse.alertFirstButtonReturn {
                // The user said yes, so add MNU to the login items system preference
                toggleStartupLaunch(doTurnOn: true)

                // Update MNU's own prefs
                defaults.set(true, forKey: "com.bps.mnu.startup-launch")
            }
        }
    }


    func toggleStartupLaunch(doTurnOn: Bool) {

        // Enable or disable (depending on the value of 'doTurnOn') the launching
        // of MNU at user login
        if doTurnOn {
            // Turn on auto-start on login
            let appPath: String = Bundle.main.bundlePath
            if let script: String = Bundle.main.path(forResource: "AddToLogin",
                                                     ofType: "scpt") {
                runProcess(app: "/usr/bin/osascript",
                           with: [script, appPath],
                           doBlock: true)
            }
        } else {
            // Turn off auto-start on login
            if let script: String = Bundle.main.path(forResource: "RemoveLogin",
                                                     ofType: "scpt") {
                runProcess(app: "/usr/bin/osascript",
                           with: [script],
                           doBlock: true)
            }
        }
    }


    @objc func enableAutoStart() {

        // Notification handler for the launch at login preference
        toggleStartupLaunch(doTurnOn: true)
    }


    @objc func disableAutoStart() {

        // Notification handler for the launch at login preference
        toggleStartupLaunch(doTurnOn: false)
    }


    // MARK: - Loading And Saving Serialization Functions

    func jsonize(_ item: MenuItem) -> String {

        // Generate a simple JSON string serialization of the specified Menu Item object
        var json = "{\"title\": \"\(item.title)\",\"type\": \(item.type),"
        json += "\"code\":\(item.code),\"index\":\(item.index),"
        json += "\"script\":\"\(item.script)\",\"hidden\": \(item.isHidden)}"
        return json
    }


    func dejsonize(_ json: String) -> MenuItem? {

        // Recreate a Menu Item object from our simple JSON serialization
        // NOTE We still need to create 'controller' properties, and this is done later
        //      See 'updateMenu()'
        if let data = json.data(using: .utf8) {
            do {
                let dict: [String: Any]? = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                let newItem = MenuItem()
                newItem.title = dict!["title"] as! String
                newItem.script = dict!["script"] as! String
                newItem.type = dict!["type"] as! Int
                newItem.code = dict!["code"] as! Int
                newItem.index = dict!["index"] as! Int
                newItem.isHidden = dict!["hidden"] as! Bool
                return newItem
            } catch {
                NSLog("Error in MNU.dejsonize(): \(error.localizedDescription)")
                presentError()
            }
        }

        return nil
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
        if let item: MenuItem = itemWithTitle(MNU_CONSTANTS.BUILT_IN_TITLES.UIMODE) {
            let controller = item.controller! as! SwitchItemViewController
            controller.setImage(isOn: self.inDarkMode)
        }

        // Run the AppleScript
        let aps: NSAppleScript = NSAppleScript.init(source: arg)!
        aps.executeAndReturnError(nil)

        // Close the menu - required for controls within views added to menu items
        self.appMenu!.cancelTracking()

        // Run the task
        // NOTE This code is no longer required, but retain it for reference
        // runProcess(app: "/usr/bin/osascript", with: [arg], doBlock: true)
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
        self.appMenu!.cancelTracking()

        // Update the Menu Item image
        if let item: MenuItem = itemWithTitle(MNU_CONSTANTS.BUILT_IN_TITLES.DESKTOP) {
            let controller = item.controller! as! SwitchItemViewController
            controller.setImage(isOn: self.useDesktop)
        }

        // Run the task to restart the Finder
        killFinder(andDock: false)
    }


    @IBAction @objc func doShowHiddenFilesSwitch(sender: Any?) {

        // Get the defaults for Finder as this contains the 'use desktop' option
        let defaults: UserDefaults = UserDefaults.standard
        var defaultsDict: [String:Any] = defaults.persistentDomain(forName: "com.apple.finder")!

        // Has the user switched the desktop on or off?
        let hiddenSwitch: NSButton = sender as! NSButton

        if hiddenSwitch.state == NSControl.StateValue.on {
            // Show Hidden is ON, so add the 'AppleShowAllFiles' key to 'com.apple.finder'
            defaultsDict["AppleShowAllFiles"] = "YES"
            self.showHidden = true
        } else {
            // Show Hidden is OFF, so remove the 'AppleShowAllFiles' key from 'com.apple.finder'
            defaultsDict.removeValue(forKey: "AppleShowAllFiles")
            self.showHidden = false
        }

        // Write the defaults back out
        defaults.setPersistentDomain(defaultsDict, forName: "com.apple.finder")

        // Close the menu - required for controls within views added to menu items
        self.appMenu!.cancelTracking()

        // Update the Menu Item image
        if let item: MenuItem = itemWithTitle(MNU_CONSTANTS.BUILT_IN_TITLES.SHOW_HIDDEN) {
            let controller = item.controller! as! SwitchItemViewController
            controller.setImage(isOn: self.showHidden)
        }

        // Run the task to restart the Finder
        killFinder(andDock: false)
    }


    @IBAction @objc func doGit(sender: Any?) {

        // Set up the script that will open Terminal and run 'gitup'
        // NOTE This requires that the user has gitup installed (see https://github.com/earwig/git-repo-updater)
        //      and will fail (in Terminal) if it is not
        // TODO Check for installation of gitup and warn if it's missing
        runScript("gitup")

        // Close the menu - required for controls within views added to menu items
        self.appMenu!.cancelTracking()

        // Run the task
        // NOTE This code is no longer required, but retain it for reference
        /*
         let args: [String] = ["-e tell application \"Terminal\" to activate", "-e tell application \"Terminal\" to do script (\"gitup\")"]
         runProcess(app: "/usr/bin/osascript", with: args, doBlock: true)
         */
    }


    @IBAction @objc func doBrewUpdate(sender: Any?) {

        // Set up the script that will open Terminal and run 'brew update'
        // NOTE This requires that the user has homebrew installed (see https://brew.sh/)
        // TODO Check for installation of brew and warn if it's missing
        runScript("brew update")

        // Close the menu - required for controls within views added to menu items
        self.appMenu!.cancelTracking()
    }


    @IBAction @objc func doBrewUpgrade(sender: Any?) {

       // Set up the script that will open Terminal and run 'brew upgrade'
       // NOTE This requires that the user has homebrew installed (see https://brew.sh/)
       // TODO Check for installation of brew and warn if it's missing
       runScript("brew upgrade")

       // Close the menu - required for controls within views added to menu items
       self.appMenu!.cancelTracking()
   }

    
    @IBAction @objc func doScript(sender: Any?) {

        // Get the source Menu Item that the menu button is linked to
        let theButton: NSButton = sender as! NSButton
        for item in self.items {
            if item.code == MNU_CONSTANTS.ITEMS.SCRIPT.USER {
                // The iterated Menu Item is a user-defined one
                let controller: ScriptItemViewController = item.controller as! ScriptItemViewController
                if controller.itemButton == theButton {
                    // The button clicked is the one this Menu Item's view controller references
                    // so run the script associated with the Menu Item
                    runScript(item.script)
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
        // TODO create web page
        // TODO provide offline help
        NSWorkspace.shared.open(URL.init(string:"https://smittytone.github.io/mnu/index.html")!)
    }


    @IBAction @objc func doConfigure(sender: Any?) {

        // Duplicate the current item list to pass on to the configure window view controller
        let list: MenuItemList = MenuItemList()

        if self.items.count > 0 {
            for item: MenuItem in self.items {
                let itemCopy: MenuItem = item.copy() as! MenuItem
                list.items.append(itemCopy)
            }
        }

        self.cwvc.menuItems = list
        self.cwvc.menuItemsTableView.reloadData()

        // Close the menu - required for controls within views added to menu items
        self.appMenu!.cancelTracking()

        // Tell the configure window controller to show its window
        self.cwvc.show()
    }


    // MARK: - Menu And View Controller Maker Functions

    @objc func createMenu() {

        // Create the app's menu using the loaded defaults
        let defaults = UserDefaults.standard
        var index = 0
        self.appMenu = NSMenu.init(title: "MNU")
        self.items.removeAll()
        
        // Get the stored list of items, if there are any - an empty array will be loaded if there are not
        let menuItems: [String] = defaults.array(forKey: "com.bps.mnu.item-order") as! [String]

        if menuItems.count > 0 {
            // We have loaded Menu Items, in serialized form, so run through them,
            // convert them to real objects and add them to the menu
            for item: String in menuItems {
                if let loadedItem = dejsonize(item) {
                    // Re-create each item's view controller according to its type
                    // The first six items are the built-ins; the last covers user-defined items
                    if loadedItem.code == MNU_CONSTANTS.ITEMS.SWITCH.UIMODE {
                        loadedItem.controller = makeModeSwitchController()
                    }

                    if loadedItem.code == MNU_CONSTANTS.ITEMS.SWITCH.DESKTOP {
                        loadedItem.controller = makeDesktopSwitchController()
                    }

                    if loadedItem.code == MNU_CONSTANTS.ITEMS.SWITCH.SHOW_HIDDEN {
                        loadedItem.controller = makeHiddenFilesSwitchController()
                    }

                    if loadedItem.code == MNU_CONSTANTS.ITEMS.SCRIPT.GIT {
                        loadedItem.controller = makeGitScriptController()
                    }

                    if loadedItem.code == MNU_CONSTANTS.ITEMS.SCRIPT.BREW_UPDATE {
                        loadedItem.controller = makeBrewUpdateScriptController()
                    }

                    if loadedItem.code == MNU_CONSTANTS.ITEMS.SCRIPT.BREW_UPGRADE {
                        loadedItem.controller = makeBrewUpgradeScriptController()
                    }

                    if loadedItem.code == MNU_CONSTANTS.ITEMS.SCRIPT.USER {
                        loadedItem.controller = makeGenericScriptController(loadedItem.title)
                    }

                    // Add the Menu Item to the list
                    self.items.append(loadedItem)

                    // Unless the item is marked as hidden, create an NSMenuItem for it
                    if !loadedItem.isHidden {
                        // Create the NSMenuItem that will represent the MNU item
                        let menuItem: NSMenuItem = NSMenuItem.init(title: loadedItem.title,
                                                                   action: nil,
                                                                   keyEquivalent: "")

                        // Set NSMenuItem's view
                        // NOTE Cast to NSViewController as it's all our subclasses' parent
                        let controller: NSViewController = loadedItem.controller as! NSViewController
                        menuItem.view = controller.view

                        // Add the NSMenuItem to the menu
                        self.appMenu!.addItem(menuItem)
                        //self.appMenu!.addItem(NSMenuItem.separator())
                    }
                } else {
                    NSLog("Error in MNU.createMenu()(): Cound not deserialize \(item)")
                    presentError()
                }
            }
        } else {
            // No serialized items are present, so assemble a list based on the default values
            let defaultItems: [Int] = defaults.array(forKey: "com.bps.mnu.default-items") as! [Int]

            for itemCode in defaultItems {
                var newItem: MenuItem? = nil

                if itemCode == MNU_CONSTANTS.ITEMS.SWITCH.UIMODE {
                    // Create and add a Light/Dark Mode MNU item
                    newItem = makeModeSwitch(index)
                }

                if itemCode == MNU_CONSTANTS.ITEMS.SWITCH.DESKTOP {
                    // Create and add a Desktop Usage MNU Item
                    newItem = makeDesktopSwitch(index)
                }

                if itemCode == MNU_CONSTANTS.ITEMS.SWITCH.SHOW_HIDDEN {
                    // Create and add a Show Hidden Files item
                    newItem = makeHiddenFilesSwitch(index)
                }

                if itemCode == MNU_CONSTANTS.ITEMS.SCRIPT.GIT {
                    // Create and add a Git Update item
                    newItem = makeGitScript(index)
                }

                if itemCode == MNU_CONSTANTS.ITEMS.SCRIPT.BREW_UPGRADE {
                    // Create and add a Brew Upgrade item
                    newItem = makeBrewUpgradeScript(index)
                }

                if itemCode == MNU_CONSTANTS.ITEMS.SCRIPT.BREW_UPDATE {
                    // Create and add a Brew Update item
                    newItem = makeBrewUpdateScript(index)
                }

                if let item: MenuItem = newItem {
                    // Add the menu item to the list
                    self.items.append(item)

                    // Create the NSMenuItem that will represent the MNU item
                    let menuItem: NSMenuItem = NSMenuItem.init(title: item.title,
                                                               action: nil,
                                                               keyEquivalent: "")

                    // Set NSMenuItem's view
                    // NOTE Cast to NSViewController as it's all our subclasses' parent
                    let controller: NSViewController = item.controller as! NSViewController
                    menuItem.view = controller.view

                    // Add the NSMenuItem to the menu
                    self.appMenu!.addItem(menuItem)
                    //self.appMenu!.addItem(NSMenuItem.separator())
                    index += 1
                }
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
            self.statusItem!.button!.toolTip = "MNU: handy actions in one easy-to-reach place\nVersion 1.0.0"
            self.statusItem!.isVisible = true
        } else {
            NSLog("Error in MNU.createMenu()(): Could not initialise menu")
            presentError()
        }
    }


    func addAppMenuItem() {

        // Add the app's control bar item
        let appItem: NSMenuItem = NSMenuItem.init(title: "APP-CONTROL",
                                                  action: #selector(self.doHelp),
                                                  keyEquivalent: "")
        appItem.view = self.appControlView
        appItem.target = self;
        self.appMenu!.addItem(appItem)
    }


    @objc func updateMenu() {

        // We have received a notification from the Confiure window controller that the list of
        // Menu Items has changed in some way, so rebuild the menu
        if let itemList: MenuItemList = cwvc.menuItems {
            self.items.removeAll()
            self.items = itemList.items
        }

        // Mark the fact that the menu has changed (so it can be saved on exit)
        self.hasChanged = true

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
                //self.appMenu!.addItem(NSMenuItem.separator())
            }
        }

        // Finally, add the app menu item at the end of the menu
        addAppMenuItem()
    }


    // MARK: Dark Mode Switching

    func makeModeSwitch(_ index: Int) -> MenuItem {

        // Make and return a stock UI mode switch
        let newItem = MenuItem()
        newItem.title = MNU_CONSTANTS.BUILT_IN_TITLES.UIMODE
        newItem.code = MNU_CONSTANTS.ITEMS.SWITCH.UIMODE
        newItem.type = MNU_CONSTANTS.TYPES.SWITCH
        newItem.index = index

        // Create its controller
        let controller: SwitchItemViewController = makeModeSwitchController()
        newItem.controller = controller

        // If we're running on a version of macOS that doesn't do Dark Mode, grey out
        // the control and disable the switch
        if (self.disableDarkMode) {
            controller.itemSwitch.isEnabled = false
            controller.itemText.textColor = NSColor.secondaryLabelColor
            controller.itemImage.alphaValue = 0.4
        }

        return newItem
    }


    func makeModeSwitchController() -> SwitchItemViewController {

        let controller: SwitchItemViewController = makeSwitchController(title: MNU_CONSTANTS.BUILT_IN_TITLES.UIMODE)
        controller.offImageName = "light_mode_icon"
        controller.onImageName = "dark_mode_icon"
        controller.state = self.inDarkMode
        controller.action = #selector(self.doModeSwitch(sender:))
        return controller
    }


    // MARK: Desktop Usage Switching

    func makeDesktopSwitch(_ index: Int) -> MenuItem {

        // Make and return a stock desktop usage mode switch
        let newItem = MenuItem()
        newItem.title = MNU_CONSTANTS.BUILT_IN_TITLES.DESKTOP
        newItem.code = MNU_CONSTANTS.ITEMS.SWITCH.DESKTOP
        newItem.type = MNU_CONSTANTS.TYPES.SWITCH
        newItem.index = index

        // Create its controller
        let controller: SwitchItemViewController = makeDesktopSwitchController()
        newItem.controller = controller
        return newItem
    }


    func makeDesktopSwitchController() -> SwitchItemViewController {

        let controller: SwitchItemViewController = makeSwitchController(title: MNU_CONSTANTS.BUILT_IN_TITLES.DESKTOP)
        controller.onImageName = "desktop_icon_on"
        controller.offImageName = "desktop_icon_off"
        controller.state = self.useDesktop
        controller.action = #selector(self.doDesktopSwitch(sender:))
        return controller
    }


    // MARK: Show Hidden Files Switching

    func makeHiddenFilesSwitch(_ index: Int) -> MenuItem {

        // Make and return a stock desktop usage mode switch
        let newItem = MenuItem()
        newItem.title = MNU_CONSTANTS.BUILT_IN_TITLES.SHOW_HIDDEN
        newItem.code = MNU_CONSTANTS.ITEMS.SWITCH.SHOW_HIDDEN
        newItem.type = MNU_CONSTANTS.TYPES.SWITCH
        newItem.index = index

        // Create its controller
        let controller: SwitchItemViewController = makeHiddenFilesSwitchController()
        newItem.controller = controller
        return newItem
    }


    func makeHiddenFilesSwitchController() -> SwitchItemViewController {

        let controller: SwitchItemViewController = makeSwitchController(title: MNU_CONSTANTS.BUILT_IN_TITLES.SHOW_HIDDEN)
        controller.onImageName = "hidden_files_icon_on"
        controller.offImageName = "hidden_files_icon_off"
        controller.state = self.showHidden
        controller.action = #selector(self.doShowHiddenFilesSwitch(sender:))
        return controller
    }


    // MARK: Update Git Trigger

    func makeGitScript(_ index: Int) -> MenuItem {

        // Make and return a stock Git Update item
        let newItem = MenuItem()
        newItem.title = MNU_CONSTANTS.BUILT_IN_TITLES.GIT
        newItem.code = MNU_CONSTANTS.ITEMS.SCRIPT.GIT
        newItem.type = MNU_CONSTANTS.TYPES.SCRIPT
        newItem.index = index

        // Create its controller
        let controller: ScriptItemViewController = makeGitScriptController()
        newItem.controller = controller
        return newItem
    }


    func makeGitScriptController() -> ScriptItemViewController {

        let controller: ScriptItemViewController = makeScriptController(title: MNU_CONSTANTS.BUILT_IN_TITLES.GIT)
        controller.offImageName = "logo_github"
        controller.onImageName = "logo_github"
        controller.action = #selector(self.doGit(sender:))
        return controller
    }


    // MARK: Update Brew Trigger

    func makeBrewUpdateScript(_ index: Int) -> MenuItem {

        // Make and return a stock Brew Update item
        let newItem = MenuItem()
        newItem.title = MNU_CONSTANTS.BUILT_IN_TITLES.BREW_UPDATE
        newItem.code = MNU_CONSTANTS.ITEMS.SCRIPT.BREW_UPDATE
        newItem.type = MNU_CONSTANTS.TYPES.SCRIPT
        newItem.index = index

        // Create its controller
        let controller: ScriptItemViewController = makeBrewUpdateScriptController()
        newItem.controller = controller
        return newItem
    }


    func makeBrewUpdateScriptController() -> ScriptItemViewController {

        let controller: ScriptItemViewController = makeScriptController(title: MNU_CONSTANTS.BUILT_IN_TITLES.BREW_UPDATE)
        controller.offImageName = "logo_brew_update"
        controller.onImageName = "logo_brew_update"
        controller.action = #selector(self.doBrewUpdate(sender:))
        return controller
    }


    // MARK: Upgrade Brew Trigger

    func makeBrewUpgradeScript(_ index: Int) -> MenuItem {

            // Make and return a stock Brew Update item
            let newItem = MenuItem()
            newItem.title = MNU_CONSTANTS.BUILT_IN_TITLES.BREW_UPGRADE
            newItem.code = MNU_CONSTANTS.ITEMS.SCRIPT.BREW_UPGRADE
            newItem.type = MNU_CONSTANTS.TYPES.SCRIPT
            newItem.index = index

            // Create its controller
            let controller: ScriptItemViewController = makeBrewUpgradeScriptController()
            newItem.controller = controller
            return newItem
        }


    func makeBrewUpgradeScriptController() -> ScriptItemViewController {

        let controller: ScriptItemViewController = makeScriptController(title: MNU_CONSTANTS.BUILT_IN_TITLES.BREW_UPGRADE)
        controller.offImageName = "logo_brew_upgrade"
        controller.onImageName = "logo_brew_upgrade"
        controller.action = #selector(self.doBrewUpgrade(sender:))
        return controller
    }


    func makeGenericScriptController(_ title: String) -> ScriptItemViewController {

        // Create and return a generic switch view controller
        let controller: ScriptItemViewController = makeScriptController(title: title)
        controller.offImageName = "logo_generic"
        controller.onImageName = "logo_generic"
        controller.action = #selector(self.doScript(sender:))
        return controller
    }


    func makeSwitchController(title: String) -> SwitchItemViewController {

        // Create and return a new base switch view controller
        let controller: SwitchItemViewController = SwitchItemViewController.init(nibName: nil, bundle: nil)
        controller.text = title
        controller.state = false
        return controller
    }


    func makeScriptController(title: String) -> ScriptItemViewController {

        // Create and return a new base button view controller
        let controller: ScriptItemViewController = ScriptItemViewController.init(nibName: nil, bundle: nil)
        controller.text = title
        controller.state = true
        return controller
    }


    // MARK: - Helper Functions

    func registerPreferences() {

        // Called by the app at launch to register its initial defaults
        // Set up the following keys/values:
        //   "com.bps.mnu.default-items" - An array of default items
        //   "com.bps.mnu.item-order"    - An array of items (default and user-defined) set
        //                                 once the user makes any change to the default set

        // NOTE The index of a user item in the 'item-order' array is its location in the menu.

        let keyArray: [String] = ["com.bps.mnu.default-items",
                                  "com.bps.mnu.item-order",
                                  "com.bps.mnu.startup-launch",
                                  "com.bps.menu.first-run"]

        let valueArray: [Any]  = [[MNU_CONSTANTS.ITEMS.SWITCH.UIMODE, MNU_CONSTANTS.ITEMS.SWITCH.DESKTOP,
                                   MNU_CONSTANTS.ITEMS.SWITCH.SHOW_HIDDEN, MNU_CONSTANTS.ITEMS.SCRIPT.GIT,
                                   MNU_CONSTANTS.ITEMS.SCRIPT.BREW_UPDATE, MNU_CONSTANTS.ITEMS.SCRIPT.BREW_UPGRADE],
                                  [],
                                  false,
                                  true]

        assert(keyArray.count == valueArray.count)
        let defaultsDict = Dictionary(uniqueKeysWithValues: zip(keyArray, valueArray))
        let defaults = UserDefaults.standard
        defaults.register(defaults: defaultsDict)
        defaults.synchronize()
    }


    func setTooltips() {

        // Add tooltips to key UI items
        appControlHelpButton.toolTip = "Get online help"
        appControlQuitButton.toolTip = "Quit MNU"
        appControlConfigureButton.toolTip = "Configure the items in the menu"
    }


    func itemWithTitle(_ title: String) -> MenuItem? {

        // Return the Menu Item whose title matches the passed one
        // TODO Probably should use a UUID rather than the title
        for item in self.items {
            if item.title == title {
                return item
            }
        }

        return nil
    }


    func presentError() {

        // Present a basic alert if an internal, non fatal error occurred.
        // This is primarily a debugging tool
        let alert = NSAlert.init()
        alert.messageText = "Sorry, an internal error occurred"
        alert.informativeText = "Please check the details in your computer's log."
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }


    func runScript(_ code: String) {

        // Add the supplied script code ('code') to the boilerplate AppleScript and run it
        let script: NSAppleScript = NSAppleScript.init(source: "tell application \"Terminal\"\nactivate\ndo script (\"\(code)\") in tab 1 of window 1\nend tell")!
        script.executeAndReturnError(nil)
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

