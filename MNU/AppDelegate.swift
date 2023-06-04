
/*
    AppDelegate.swift
    MNU

    Created by Tony Smith on 03/07/2019.
    Copyright © 2022 Tony Smith. All rights reserved.

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
final class AppDelegate: NSObject,
                         NSApplicationDelegate,
                         NSMenuDelegate {

    // MARK: - UI Outlets

    @IBOutlet var cwvc: ConfigureViewController!                // The Configure window controller
    @IBOutlet var acvc: MenuControlsViewController!             // The control bar view controller
    
    // MARK: - Public App Properties
    
    var icons: NSMutableArray = NSMutableArray.init()
                                                // Menu icons list
    // FROM 1.6.0
    var terminalIndex: Int = 0                  // Which terminal has the user selected?
                                                // 0  - macOS Terminal (default)
                                                // 1  - iTerm
                                                // 2+ - TBD
                                                // NOTE This is not private so that it's accessible in tests
    
    // MARK: - Private App Properties
    
    private var statusItem: NSStatusItem? = nil // The macOS main menu item providing the menu
    private var appMenu: NSMenu? = nil          // The NSMenu presenting the switches and scripts
    private var items: [MenuItem] = []          // The menu items that are present (but may be hidden)
    private var task: Process? = nil            // A sub-process we use for triggered scripts
    private var doNewTermTab: Bool = false      // Should we open terminal scripts in a new window
    private var showImages: Bool = false        // Should we show menu icons as well as names
    private var disableDarkMode: Bool = false   // Should the menu disable the dark mode control (ie. not supported on the host)
    private var inDarkMode: Bool = false        // Is the Mac in dark mode (true) or not (false)
    private var useDesktop: Bool = false        // Is the Finder using the desktop (true) or not (false)
    private var showHidden: Bool = false        // Is the Finder showing hidden files (true) or not (false)
    private var optionClick: Bool = false       // Did the user option-click the menu
    // FROM 1.3.0
    private var reloadDefaults: Bool = false    // Do we need to reload preferences?
    // FROM 1.3.1
    private var isElevenPlus: Bool = false      // Are we running on Big Sur?


    // MARK: - App Lifecycle Functions

    func applicationDidFinishLaunching(_ aNotification: Notification) {

        // First, check system state and record system truth
        recordSystemState()
        
        // MARK: DEBUG SWITCHES
        // Uncomment the next three lines to wipe stored prefs
        //let defaults: UserDefaults = UserDefaults.standard
        //defaults.set([], forKey: "com.bps.mnu.item-order")
        //defaults.set(true, forKey: "com.bps.mnu.first-run")
        
        // Register default preferences
        registerPreferences()
        
        // FROM 1.6.0
        // Record key preferences
        recordKeyPreferences()
        
        // Check for first run
        firstRunCheck()

        // Create the app's menu
        createMenu()
        
        // Register notification handlers
        let nc: NotificationCenter = NotificationCenter.default
        nc.addObserver(self,
                       selector: #selector(self.updateAndSaveMenu),
                       name: NSNotification.Name(rawValue: "com.bps.mnu.list-updated"),
                       object: self.cwvc)

        // Watch for changes to the startup launch preference
        nc.addObserver(self,
                       selector: #selector(self.enableAutoStart),
                       name: NSNotification.Name(rawValue: "com.bps.mnu.startup-enabled"),
                       object: self.cwvc)

        nc.addObserver(self,
                       selector: #selector(self.disableAutoStart),
                       name: NSNotification.Name(rawValue: "com.bps.mnu.startup-disabled"),
                       object: self.cwvc)
        
        // Watch for an 'it's OK to quit' message from the Configure Window
        // NOTE This is issued in response to an attempt to quit the app when the Configure
        //      Window has unapplied changes, which will interrupt the termination flow -
        //      this puts it back on track by calling 'performTermination()'
        nc.addObserver(self,
                       selector: #selector(self.performTermination),
                       name: NSNotification.Name(rawValue: "com.bps.mnu.can-quit"),
                       object: self.cwvc)
        
        // Watch for the appearance of the Configure Window
        // NOTE This is sent by the Menu Controls view controller
        nc.addObserver(self,
                       selector: #selector(self.showConfigureWindow),
                       name: NSNotification.Name(rawValue: "com.bps.mnu.show-configure"),
                       object: self.acvc)
        
        // FROM 1.6.0
        // The user has changed their preferred terminal
        nc.addObserver(self,
                       selector: #selector(self.switchTerminal),
                       name: NSNotification.Name(rawValue: "com.bps.mnu.term-updated"),
                       object: self.cwvc)
        
        // The user has changed their tab openning preference
        nc.addObserver(self,
                       selector: #selector(self.toggleTerminalTabbing),
                       name: NSNotification.Name(rawValue: "com.bps.mnu.term-tab-updated"),
                       object: self.cwvc)
    }

                       
    @objc private func performTermination() {
        
        // Tell the application can now terminate, following the issuing of a
        // NSApplication.TerminateReply.terminateLater (see 'applicationShouldTerminate()')
        NSApplication.shared.reply(toApplicationShouldTerminate: true)
    }
    
    
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        
        // This prevents the app closing when the user clicks the Quit control, if the
        // Configure Window is visible and is presenting the Add Item sheet
        if self.cwvc.isVisible && self.cwvc.aivc.parentWindow != nil {
            return NSApplication.TerminateReply.terminateCancel
        }
        
        // This prevents the app closing when the user clicks the Quit control, if the Configure
        // Window has unapplied changes
        if self.cwvc.isVisible && self.cwvc.hasChanged {
            // Close the menu - required for controls within views added to menu items
            self.appMenu!.cancelTrackingWithoutAnimation()
            
            // Set the Configure Window for one last apperance
            self.cwvc.lastChance = true
            self.cwvc.doCancel(sender: self)
            return NSApplication.TerminateReply.terminateLater
        }
        
        return NSApplication.TerminateReply.terminateNow
    }
    
    
    func applicationWillTerminate(_ aNotification: Notification) {

        // Save the current menu - this is redundant and may be removed
        saveItems()

        // Disable notification listening (to be tidy)
        NotificationCenter.default.removeObserver(self)
    }


    func applicationWillResignActive(_ notification: Notification) {

        // App is backgrounding - inform interested view controllers
        NotificationCenter.default.post(name: NSNotification.Name.init(rawValue: "com.bps.mnu.will-background"),
                                        object: self)
    }


    private func firstRunCheck() {

        // Check whether we're running for the first time
        // If so, invite the user to run MNU at launch

        // Read in the defaults to see if this is MNU's first run: value will be true
        let defaults: UserDefaults = UserDefaults.standard
        let isFirstRun: Bool = defaults.bool(forKey: "com.bps.mnu.first-run")
        if isFirstRun {
            // This is the first run - set the default to false so we don't
            // ever do this again
            defaults.set(false, forKey: "com.bps.mnu.first-run")

            // Ask the user if they want to run MNU at startup
            let alert: NSAlert = NSAlert.init()
            alert.messageText = "Run MNU at Login?"
            alert.informativeText = "Do you wish to set your Mac to run MNU when you log in? This can also be set in MNU’s Preferences."
            alert.addButton(withTitle: "Yes")
            alert.addButton(withTitle: "No")
            let selection: NSApplication.ModalResponse = alert.runModal()
            if selection == NSApplication.ModalResponse.alertFirstButtonReturn {
                // The user said yes, so add MNU to the login items system preference
                enableAutoStart()

                // Update MNU's own prefs
                defaults.set(true, forKey: "com.bps.mnu.startup-launch")
            }
        }
    }

    
    private func getTrueBool(_ value: Any, _ truthString: String = "YES") -> Bool {
        
        // FROM 1.5.2
        // Convert values received from GlobalDomain and Finder to true Booleans
        // NOTE They may be read as "1", "YES", or an __NSCFBoolean, which does
        //      not cast to a String, but does to Int or Bool
        if let v = value as? Bool {
            return v
        }
        
        if let v = value as? Int {
            return v == 1
        }
        
        if let v = value as? String {
            return v == truthString || v == "YES" || v == "1"
        }
        
        return false
    }
    
    
    private func recordSystemState() {
        
        // FROM 1.6.0
        // Refactored from 'applicationDidFinishLaunching()'
        // Get system and state information and record it for use during run
        
        // First ensure we are running on Mojave or above - Dark Mode is not supported by earlier versons
        let sysVer: OperatingSystemVersion = ProcessInfo.processInfo.operatingSystemVersion

        // FROM 1.3.1
        // Support macOS 11.0.0 version numbering by forcing check to 10.13.x
        if sysVer.majorVersion == 10 && sysVer.minorVersion < 14 {
            // Wrong version, so present a warning message
            let alert: NSAlert = NSAlert.init()
            alert.messageText = "Unsupported version of macOS"
            alert.informativeText = "MNU makes use of features not present in the version of macOS (\(sysVer.majorVersion).\(sysVer.minorVersion).\(sysVer.patchVersion)) running on your computer. Please conisder upgrading to macOS 10.14 or higher."
            alert.addButton(withTitle: "OK")
            alert.runModal()
            self.disableDarkMode = true
        }

        // Are we running on Big Sur?
        self.isElevenPlus = sysVer.majorVersion >= 11
        self.cwvc.isElevenPlus = self.isElevenPlus

        // Set the default values for the states we control
        self.inDarkMode = false
        self.useDesktop = true
        self.showHidden = false

        // Use the standard user defaults to first determine whether the host Mac is in Dark Mode,
        // and the the other states of supported switches
        let defaults: UserDefaults = UserDefaults.standard
        if let defaultsDict: [String: Any] = defaults.persistentDomain(forName: UserDefaults.globalDomain) {
            if let anyValue: Any = defaultsDict["AppleInterfaceStyle"] {
                self.inDarkMode = getTrueBool(anyValue, "Dark")
            }
        }
        
        if let defaultsDict: [String: Any] = defaults.persistentDomain(forName: "com.apple.finder") {
            if let anyValue: Any = defaultsDict["CreateDesktop"] {
                self.useDesktop = getTrueBool(anyValue)
            }
            
            if let anyValue: Any = defaultsDict["AppleShowAllFiles"] {
                self.showHidden = getTrueBool(anyValue)
            }
        }
    }
    
    
    private func recordKeyPreferences() {
        
        // FROM 1.6.0
        // NOTE We read and store the following two preferences because
        //      we need to refer to them regularly. We only re-read the
        //      saved value in response to a notification that it has
        //      been changed by the user
        
        let defaults: UserDefaults = UserDefaults.standard
        
        // Read in the preferred terminal by index value, then
        // check that it is actually available. If not, use the default
        self.terminalIndex = defaults.integer(forKey: "com.bps.mnu.term-choice")
        if isTerminalMissing(self.terminalIndex) {
            self.terminalIndex = 0
        }
        
        // Set the current tab opening choice: open in new window/tab or not
        self.doNewTermTab = defaults.bool(forKey: "com.bps.mnu.new-term-tab")
        
        // Set whether the menu shows images or not
        self.showImages = defaults.bool(forKey: "com.bps.mnu.show-controls")
    }
    
    
    // MARK: - Auto-start Functions

    @objc private func enableAutoStart() {

        // Notification handler for the launch at login preference
        toggleStartupLaunch(doTurnOn: true)
    }


    @objc private func disableAutoStart() {

        // Notification handler for the launch at login preference
        toggleStartupLaunch(doTurnOn: false)
    }


    private func toggleStartupLaunch(doTurnOn: Bool) {

        // Enable or disable (depending on the value of 'doTurnOn') the launching
        // of MNU at user login. This is activated by a notification from the
        // Configure Window view controller (via 'enableAutoStart()' and 'disableAutoStart()'
        runBundleScript(named: (doTurnOn ? "AddToLogin" : "RemoveLogin"),
                        doAddPath: doTurnOn)
        
        // FROM 1.5.2
        // Make sure preference is saved
        let defaults: UserDefaults = UserDefaults.standard
        defaults.set(doTurnOn, forKey: "com.bps.mnu.startup-launch")
        defaults.synchronize()
    }
    
    
    @objc private func switchTerminal() {
        
        // FROM 1.6.0
        // This function is called in response to a change of terminal being
        // made in the Prefs pane of the ConfigureViewController, via the
        // 'com.bps.mnu.term-updated' notification
        if self.cwvc.terminalChoice != 0 {
            // The user has selected a non-default terminal,
            // so check that it's available for use
            if isTerminalMissing(self.cwvc.terminalChoice) {
                // Selected terminal doesn't exist, so use the default
                self.terminalIndex = 0
                return
            }
        }
        
        // Set the current terminal to the valid one
        // NOTE This doesn't affect the stored preferences
        self.terminalIndex = self.cwvc.terminalChoice
    }
    
    
    @objc private func toggleTerminalTabbing() {
        
        // FROM 1.6.0
        // Update internal record of the user's tab opening choice: current window or new
        // Configure Window has already saved the preference
        self.doNewTermTab = self.cwvc.tabOpenChoice
    }
    
    
    private func isTerminalMissing(_ choice: Int) -> Bool {
        
        // FROM 1.6.0
        // Check that the selected terminal is installed by making sure
        // it is in the standard Application folders (see 'getAppPath()')
        // Configure Window has already saved the preference
        // NOTE Returns 'true' if the app is NOT present, false if it IS present
        if choice != 0 {
            // The user has selected a non-default terminal
            let terminals: [String] = ["iTerm"]
            
            // 'getAppPath()' returns nil if the app isn't present
            // Remember to zero-index 'choice'
            return getAppPath(terminals[choice - 1]) == nil
        }
        
        // Default to false -- app present (the default)
        return false
    }


    // MARK: - Loading And Saving Serialization Functions

    private func saveItems() {
        
        // Store the current state of the menu if it has changed
        // NOTE We convert Menu Item objects into basic JSON strings and save
        //      these into an array that we will use to recreate the Menu Item list
        //      at next start up. This is because Strings can be PLIST'ed whereas
        //      custom objects cannot
        var savedItems: [Any] = []
        
        for item: MenuItem in self.items {
            savedItems.append(Serializer.jsonize(item))
        }
        
        let defaults: UserDefaults = UserDefaults.standard
        defaults.set(savedItems, forKey: "com.bps.mnu.item-order")
        defaults.synchronize()
    }


    // MARK: - App Action Functions

    @IBAction @objc private func doModeSwitch(sender: Any?) {

        // Switch mode record
        self.inDarkMode = !self.inDarkMode

        // Update the NSMenuItem
        let menuItem: NSMenuItem = sender as! NSMenuItem
        menuItem.title = self.inDarkMode ? "Switch to Light Mode" : "Switch to Dark Mode"
        if self.showImages {
            menuItem.image = NSImage.init(named: (self.inDarkMode ? "light_mode_icon" : "dark_mode_icon"))
        }

        // Set up the script that will switch the UI mode
        var arg: String = "tell application \"System Events\" to tell appearance preferences to set dark mode to "
        arg += self.inDarkMode ? "true" : "false"

        // Run the AppleScript
        let aps: NSAppleScript = NSAppleScript.init(source: arg)!
        aps.executeAndReturnError(nil)

        // Run the task
        // NOTE This code is no longer required, but retain it for reference
        // runProcess(app: "/usr/bin/osascript", with: [arg], doBlock: true)
    }


    @IBAction @objc private func doDesktopSwitch(sender: Any?) {

        // Switch the stored state
        self.useDesktop = !self.useDesktop

        // Update the NSMenuItem
        let menuItem: NSMenuItem = sender as! NSMenuItem
        menuItem.title = self.useDesktop ? "Hide Files on Desktop" : "Show Files on Desktop"
        if self.showImages {
            menuItem.image = NSImage.init(named: (self.useDesktop ? "desktop_icon_off" : "desktop_icon_on"))
        }

        // Get the defaults for Finder as this contains the 'use desktop' option
        let defaults: UserDefaults = UserDefaults.standard
        var defaultsDict: [String:Any] = defaults.persistentDomain(forName: "com.apple.finder")!

        if self.useDesktop {
            // Desktop is ON, so remove the 'CreateDesktop' key from 'com.apple.finder'
            defaultsDict.removeValue(forKey: "CreateDesktop")
        } else {
            // Desktop is OFF, so add the 'CreateDesktop' key, with value 0, to 'com.apple.finder'
            defaultsDict["CreateDesktop"] = "0"
        }

        // Write the defaults back out
        defaults.setPersistentDomain(defaultsDict,
                                     forName: "com.apple.finder")

        // Run the task to restart the Finder
        killFinder(andDock: false)
    }


    @IBAction @objc private func doShowHiddenFilesSwitch(sender: Any?) {

        // Switch the stored state
        self.showHidden = !self.showHidden

        // Update the NSMenuItem
        let menuItem: NSMenuItem = sender as! NSMenuItem
        menuItem.title = self.showHidden ? "Hide Hidden Files in Finder" : "Show Hidden Files in Finder"
        if self.showImages {
            menuItem.image = NSImage.init(named: (self.showHidden ? "hidden_files_icon_off" : "hidden_files_icon_on"))
        }

        // Get the defaults for Finder as this contains the 'use desktop' option
        let defaults: UserDefaults = UserDefaults.standard
        var defaultsDict: [String:Any] = defaults.persistentDomain(forName: "com.apple.finder")!

        if self.showHidden {
            // Show Hidden is ON, so add the 'AppleShowAllFiles' key to 'com.apple.finder'
            defaultsDict["AppleShowAllFiles"] = "YES"
        } else {
            // Show Hidden is OFF, so remove the 'AppleShowAllFiles' key from 'com.apple.finder'
            defaultsDict.removeValue(forKey: "AppleShowAllFiles")
        }

        // Write the defaults back out
        defaults.setPersistentDomain(defaultsDict,
                                     forName: "com.apple.finder")

        // Run the task to restart the Finder
        killFinder(andDock: false)
    }


    @IBAction @objc private func doGit(sender: Any?) {

        // Set up the script that will open Terminal and run 'gitup'
        // NOTE This requires that the user has gitup installed (see https://github.com/earwig/git-repo-updater)
        //      and will fail (in Terminal) if it is not

        // Check for installation of gitup and warn if it's missing
        if checkScriptExists("/usr/local/bin/gitup") {
            runScript("gitup")
        }
    }


    @IBAction @objc private func doBrewUpdate(sender: Any?) {

        // Set up the script that will open Terminal and run 'brew update'
        // NOTE This requires that the user has homebrew installed (see https://brew.sh/)

        // Check for installation of brew and warn if it's missing
        // FROM 1.5.1 Support standard ARM Mac install location too
        //            This will see if we have brew in either location,
        //            but won't display a warning
        let brewAvailable: Bool = (checkScriptExists("/usr/local/bin/brew", true) || checkScriptExists("/opt/homebrew/bin/brew", true))
        if brewAvailable {
            runScript("brew update")
        } else {
            // This will check for brew again, which we've already done,
            // but this time we don't pass 'true' so a warning is presented to the user
            _ = checkScriptExists("/usr/local/bin/brew")
        }
    }


    @IBAction @objc private func doBrewUpgrade(sender: Any?) {

        // Set up the script that will open Terminal and run 'brew upgrade'
        // NOTE This requires that the user has homebrew installed (see https://brew.sh/)
        // Check for installation of brew and warn if it's missing
        // FROM 1.5.1 Support standard ARM Mac install location too
        //            This will see if we have brew in either location,
        //            but won't display a warning
        let brewAvailable: Bool = (checkScriptExists("/usr/local/bin/brew", true) || checkScriptExists("/opt/homebrew/bin/brew", true))
        if brewAvailable {
            runScript("brew upgrade")
        } else {
            // This will check for brew again, which we've already done,
            // but this time we don't pass 'true' so a warning is presented to the user
            _ = checkScriptExists("/usr/local/bin/brew")
        }
   }

    
    @IBAction @objc private func doScript(sender: Any?) {

        // Get the source Menu Item that the menu button is linked to
        let menuItem: NSMenuItem = sender as! NSMenuItem
        if let item: MenuItem = menuItem.representedObject as? MenuItem {
            if item.type == MNU_CONSTANTS.TYPES.SCRIPT {
                if item.isDirect {
                    // FROM 1.3.0
                    // Switch to new method
                    // (old one: runCallDirect(item.script))
                    runScriptDirect(item.script)
                } else {
                    runScript(item.script)
                }
            } else {
                openApp(item.script)
            }
        }
    }


    @objc private func showConfigureWindow() {

        // Duplicate the current item list to pass on to the configure window view controller
        let list: MenuItemList = MenuItemList()

        if self.items.count > 0 {
            for item: MenuItem in self.items {
                let itemCopy: MenuItem = item.copy() as! MenuItem
                list.items.append(itemCopy)
            }
        }

        self.cwvc.menuItems = list
        // FROM 1.0.1 - move the following line to the view controller
        // self.cwvc.menuItemsTableView.reloadData()

        // Close the menu - required for controls within views added to menu items
        self.appMenu!.cancelTracking()

        // FROM 1.3.1
        self.cwvc.isElevenPlus = self.isElevenPlus
        
        // FROM 1.5.0
        self.cwvc.appDelegate = self

        // Tell the configure window controller to show its window
        self.cwvc.show()
    }


    // MARK: - Menu And View Controller Maker Functions

    @objc private func createMenu() {

        // Create the app's menu when the app is run
        
        // Load the icons
        makeIconMatrix()
        
        // Prepare the NSMenu
        self.appMenu = NSMenu.init(title: "MNU")
        self.appMenu!.autoenablesItems = false
        self.appMenu!.delegate = self

        // Clear the items list
        self.items.removeAll()
        
        // Get the stored list of items, if there are any - an empty array will be loaded if there are not
        let defaults: UserDefaults = UserDefaults.standard
        let loadedItems: [String] = defaults.array(forKey: "com.bps.mnu.item-order") as! [String]

        if !reloadDefaults && loadedItems.count > 0 {
            // We have loaded a set of Menu Items, in serialized form, so run through the list to
            // convert the serializations into real objects: Menu Items and their representative
            // NSMenuItems
            
            for loadedItem: String in loadedItems {
                if let itemInstance: MenuItem = Serializer.dejsonize(loadedItem) {
                    // Add the Menu Item to the list
                    self.items.append(itemInstance)
                    let menuItem: NSMenuItem = makeNSMenuItem(itemInstance)

                    // If the item is not hidden, add it to the menu
                    if !itemInstance.isHidden {
                        // Add the item's NSMenuItem to the NSMenu
                        self.appMenu!.addItem(menuItem)

                        // FROM 1.3.0 -- Only add a separator if we're showing images
                        if self.showImages { self.appMenu!.addItem(NSMenuItem.separator()) }
                    }
                } else {
                    // FROM 1.3.0
                    // We couldn't load one of the saved list of MNU items, so ask the user what to do
                    DispatchQueue.main.async {
                        let alert: NSAlert = NSAlert.init()
                        alert.messageText = "Stored MNU items are damanged"
                        alert.informativeText = "Do you wish to continue with the default items?"
                        alert.addButton(withTitle: "Continue")
                        alert.addButton(withTitle: "Quit MNU")
                        let response: NSApplication.ModalResponse = alert.runModal()

                        if response == NSApplication.ModalResponse.alertFirstButtonReturn {
                            // User chose to reload defaults
                            self.reloadDefaults = true
                            self.createMenu()
                        } else {
                            // User chose to quit
                            NSApplication.shared.terminate(self)
                        }
                    }

                    // NSLog("Error in MNU.createMenu()(): Cound not deserialize \(loadedItem)")
                    // presentError()

                    return
                }
                
                // FROM 1.6.0
                // Add new defaults to the menu if the user has already customised the menu
                let insertNewDefaults: Int = defaults.integer(forKey: "com.bps.mnu.new-defs-1-6")
                if insertNewDefaults > 0 {
                    let defaultItems: [Int] = defaults.array(forKey: "com.bps.mnu.default-items") as! [Int]
                    for i: Int in 0..<insertNewDefaults {
                        if let item: MenuItem = getNewMenuItem(defaultItems[MNU_CONSTANTS.BASE_DEFAULT_COUNT + i]) {
                            // Add the menu item to the list and make a menu item
                            self.items.append(item)
                            let menuItem: NSMenuItem = makeNSMenuItem(item)
                            self.appMenu!.addItem(menuItem)
                            if self.showImages {
                                self.appMenu!.addItem(NSMenuItem.separator())
                            }
                        }
                    }
                    
                    // Record for next time that the operation was done
                    defaults.set(0, forKey: "com.bps.mnu.new-defs-1-6")
                    
                    // Save the update menu item list
                    saveItems()
                }
            }
        } else {
            // No serialized items are present, so assemble a list based on the default values
            // NOTE This will typically only be called on first run (we save the order after that)
            let defaultItems: [Int] = defaults.array(forKey: "com.bps.mnu.default-items") as! [Int]

            for itemCode in defaultItems {
                if let item: MenuItem = getNewMenuItem(itemCode) {
                    // Add the menu item to the list
                    self.items.append(item)

                    // Create the NSMenuItem that will represent the Menu Item
                    let menuItem: NSMenuItem = makeNSMenuItem(item)

                    // Add the NSMenuItem to the NSMenu
                    self.appMenu!.addItem(menuItem)
                    self.appMenu!.addItem(NSMenuItem.separator())
                }
            }

            // FROM 1.3.0
            self.reloadDefaults = false
        }

        // Finally, add the app menu
        addAppMenuItem(!self.showImages)

        // Now add the app menu to the macOS menu bar
        let bar: NSStatusBar = NSStatusBar.system
        self.statusItem = bar.statusItem(withLength: NSStatusItem.squareLength)

        if self.statusItem != nil && self.appMenu != nil {
            self.statusItem!.button!.image = NSImage.init(named: "menu_icon")
            self.statusItem!.button!.isHighlighted = false
            self.statusItem!.behavior = NSStatusItem.Behavior.terminationOnRemoval
            self.statusItem!.menu = self.appMenu!
            let version: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
            let build: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
            self.statusItem!.button!.toolTip = "MNU: handy actions in one easy-to-reach place\nVersion \(version) (\(build))"
            self.statusItem!.isVisible = true
        } else {
            NSLog("Error in MNU.createMenu()(): Could not initialise menu")
            presentError()
        }
    }

    
    private func getNewMenuItem(_ itemCode: Int) -> MenuItem? {
        
        // FROM 1.6.0
        // Refactor out the code so it can be reused
        
        var newItem: MenuItem? = nil
        
        if itemCode == MNU_CONSTANTS.ITEMS.SWITCH.UIMODE {
            // Create and add a Light/Dark Mode MNU item
            newItem = makeModeSwitch()
        }

        if itemCode == MNU_CONSTANTS.ITEMS.SWITCH.DESKTOP {
            // Create and add a Desktop Usage MNU Item
            newItem = makeDesktopSwitch()
        }

        if itemCode == MNU_CONSTANTS.ITEMS.SWITCH.SHOW_HIDDEN {
            // Create and add a Show Hidden Files item
            newItem = makeHiddenFilesSwitch()
        }

        if itemCode == MNU_CONSTANTS.ITEMS.SCRIPT.GIT {
            // Create and add a Git Update item
            newItem = makeGitScript()
        }

        if itemCode == MNU_CONSTANTS.ITEMS.SCRIPT.BREW_UPGRADE {
            // Create and add a Brew Upgrade item
            newItem = makeBrewUpgradeScript()
        }

        if itemCode == MNU_CONSTANTS.ITEMS.SCRIPT.BREW_UPDATE {
            // Create and add a Brew Update item
            newItem = makeBrewUpdateScript()
        }
        
        // FROM 1.6.0 -- Next three items
        if itemCode == MNU_CONSTANTS.ITEMS.SCRIPT.SHOW_IP {
            // Create and add a Show IP Address item
            newItem = makeShowIPScript()
        }

        if itemCode == MNU_CONSTANTS.ITEMS.SCRIPT.SHOW_DF {
            // Create and add a Show Disk Free Space item
            newItem = makeShowDiskFullScript()
        }

        if itemCode == MNU_CONSTANTS.ITEMS.OPEN.GRAB_WINDOW {
            // Create and add a Grab Window item
            newItem = makeGetScreenshotOpen()
        }
        
        return newItem
    }
    
    
    @objc private func updateMenu() {
        
        // Redraw the menu based on the current list of items
        // NOTE If 'optionClick' has been set, we show all items, even if they would normally
        //      be hidden from view via the Configure Window
        
        // Clear the menu in order to rebuild it
        self.appMenu!.removeAllItems()
        
        // Iteratre through the menu items, creating NSMenuItems to represent the visible ones
        for item: MenuItem in self.items {
            // Create an NSMenuItem that will display the current MNU item
            let menuItem: NSMenuItem = makeNSMenuItem(item)

            // If the item is not hidden, add it to the NSMenu
            // However, on an option-click show ALL the items anyway
            if !item.isHidden || self.optionClick {
                self.appMenu!.addItem(menuItem)

                // FROM 1.3.0 -- Only add a separator if we're showing images
                if self.showImages { self.appMenu!.addItem(NSMenuItem.separator()) }
            }
        }
        
        // No items being shown at all? Then add a note about it!
        if self.appMenu!.items.count < 1 {
            let noteItem: NSMenuItem = NSMenuItem.init(title: "You have hidden all your items",
                                                       action: #selector(self.showConfigureWindow),
                                                       keyEquivalent: "")
            noteItem.isEnabled = false
            self.appMenu!.addItem(noteItem)
            self.appMenu!.addItem(NSMenuItem.separator())
        }

        // Finally, add the app menu item at the end of the menu
        addAppMenuItem(!self.showImages)
    }
    
    
    @objc private func updateAndSaveMenu() {
        
        // We have received a notification from the Configure Window's controller that the
        // list of Menu Items has changed in some way, so rebuild the menu from scratch
        if let itemList: MenuItemList = cwvc.menuItems {
            self.items = itemList.items
        }
        
        // FROM 1.6.0
        recordKeyPreferences()
        
        // Regenerate the menu
        updateMenu()
        
        // Save the update menu item list
        saveItems()
    }
    


    private func makeNSMenuItem(_ item: MenuItem) -> NSMenuItem {

        // Create and return an NSMenuItem for the specified Menu Item instance
        let menuItem: NSMenuItem = NSMenuItem.init(title: item.title,
                                                   action: nil,
                                                   keyEquivalent: item.keyEquivalent)
        
        // FROM 1.7.0
        // Implement key modifiers if required
        if item.keyEquivalent.count > 0 {
            var flags: NSEvent.ModifierFlags = []
            if (item.keyModFlags & 0x01) != 0 { flags.insert(.shift) }
            if (item.keyModFlags & 0x02) != 0 { flags.insert(.command) }
            if (item.keyModFlags & 0x04) != 0 { flags.insert(.option) }
            if (item.keyModFlags & 0x08) != 0 { flags.insert(.control) }
            menuItem.keyEquivalentModifierMask = flags
        }

        // Reference the MenuItem instance
        menuItem.representedObject = item

        // Make item-specific changes
        // These will set specific titles (based on state) and icons
        // or fall back to default behaviour which as per user-added items
        switch item.code {
            case MNU_CONSTANTS.ITEMS.SWITCH.UIMODE:
                if self.disableDarkMode { menuItem.isEnabled = false }
                menuItem.action = #selector(self.doModeSwitch(sender:))
                menuItem.title = self.inDarkMode ? "Switch to Light Mode" : "Switch to Dark Mode"
            case MNU_CONSTANTS.ITEMS.SWITCH.DESKTOP:
                menuItem.action = #selector(self.doDesktopSwitch(sender:))
                menuItem.title = self.useDesktop ? "Hide Files on Desktop" : "Show Files on Desktop"
            case MNU_CONSTANTS.ITEMS.SWITCH.SHOW_HIDDEN:
                menuItem.action = #selector(self.doShowHiddenFilesSwitch(sender:))
                menuItem.title = self.showHidden ? "Hide Hidden Files in Finder" : "Show Hidden Files in Finder"
            case MNU_CONSTANTS.ITEMS.SCRIPT.GIT:
                menuItem.title = MNU_CONSTANTS.BUILT_IN_TITLES.GIT
                menuItem.action = #selector(self.doGit(sender:))
            case MNU_CONSTANTS.ITEMS.SCRIPT.BREW_UPDATE:
                menuItem.title = MNU_CONSTANTS.BUILT_IN_TITLES.BREW_UPDATE
                menuItem.action = #selector(self.doBrewUpdate(sender:))
            case MNU_CONSTANTS.ITEMS.SCRIPT.BREW_UPGRADE:
                menuItem.title = MNU_CONSTANTS.BUILT_IN_TITLES.BREW_UPGRADE
                menuItem.action = #selector(self.doBrewUpgrade(sender:))
            default:
                menuItem.action = #selector(self.doScript(sender:))
        }

        if self.showImages {
            switch item.code {
                case MNU_CONSTANTS.ITEMS.SWITCH.UIMODE:
                   menuItem.image = NSImage.init(named: (self.inDarkMode ? "light_mode_icon" : "dark_mode_icon"))
                case MNU_CONSTANTS.ITEMS.SWITCH.DESKTOP:
                    menuItem.image = NSImage.init(named: (self.useDesktop ? "desktop_icon_off" : "desktop_icon_on"))
                case MNU_CONSTANTS.ITEMS.SWITCH.SHOW_HIDDEN:
                    menuItem.image = NSImage.init(named: (self.showHidden ? "hidden_files_icon_off" : "hidden_files_icon_on"))
                case MNU_CONSTANTS.ITEMS.SCRIPT.GIT:
                    menuItem.image = NSImage.init(named: "logo_github")
                case MNU_CONSTANTS.ITEMS.SCRIPT.BREW_UPDATE:
                    menuItem.image = NSImage.init(named: "logo_brew")
                case MNU_CONSTANTS.ITEMS.SCRIPT.BREW_UPGRADE:
                    menuItem.image = NSImage.init(named: "logo_brew")
                default:
                    // Default is a standard icon from the list
                    menuItem.image = icons.object(at: item.iconIndex) as? NSImage
            }
        }
        
        return menuItem
    }
    
    
    private func addAppMenuItem(_ doSeparate: Bool) {

        // Add the app's control bar item
        // We always add this after creating or updating the menu
        // FROM 1.3.0 - Add a 'show separator' parameter

        if let appItem: NSMenuItem = self.acvc.controlMenuItem {
            // FROM 1.3.0 - Add a separator if we're NOT showing item images
            if doSeparate { self.appMenu!.addItem(NSMenuItem.separator()) }
            self.appMenu!.addItem(appItem)
        }
    }

    
    func makeIconMatrix() {
        
        // Build the array of icons that we will use for the popover selector and the button
        // that triggers its appearance
        // NOTE There should be 25 icons in total in this release

        if self.icons.count == 0 {
            var image: NSImage? = NSImage.init(named: "logo_generic")
            self.icons.add(image!)
            image = NSImage.init(named: "logo_bash")
            self.icons.add(image!)
            image = NSImage.init(named: "logo_z")
            self.icons.add(image!)
            image = NSImage.init(named: "logo_code")
            self.icons.add(image!)
            image = NSImage.init(named: "logo_git")
            self.icons.add(image!)
            image = NSImage.init(named: "logo_python")
            self.icons.add(image!)
            image = NSImage.init(named: "logo_node")
            self.icons.add(image!)
            image = NSImage.init(named: "logo_as")
            self.icons.add(image!)
            image = NSImage.init(named: "logo_ts")
            self.icons.add(image!)
            image = NSImage.init(named: "logo_coffee")
            self.icons.add(image!)
            image = NSImage.init(named: "logo_github")
            self.icons.add(image!)
            image = NSImage.init(named: "logo_gitlab")
            self.icons.add(image!)
            image = NSImage.init(named: "logo_brew")
            self.icons.add(image!)
            image = NSImage.init(named: "logo_docker")
            self.icons.add(image!)
            image = NSImage.init(named: "logo_php")
            self.icons.add(image!)
            image = NSImage.init(named: "logo_web")
            self.icons.add(image!)
            image = NSImage.init(named: "logo_cloud")
            self.icons.add(image!)
            image = NSImage.init(named: "logo_doc")
            self.icons.add(image!)
            image = NSImage.init(named: "logo_dir")
            self.icons.add(image!)
            image = NSImage.init(named: "logo_app")
            self.icons.add(image!)
            image = NSImage.init(named: "logo_cog")
            self.icons.add(image!)
            image = NSImage.init(named: "logo_sync")
            self.icons.add(image!)
            image = NSImage.init(named: "logo_power")
            self.icons.add(image!)
            image = NSImage.init(named: "logo_mac")
            self.icons.add(image!)
            image = NSImage.init(named: "logo_x")
            self.icons.add(image!)
        }
    }
    
    
    // MARK: Dark Mode Switching

    func makeModeSwitch() -> MenuItem {

        // Make and return a stock UI mode switch
        let newItem: MenuItem = MenuItem()
        newItem.title = MNU_CONSTANTS.BUILT_IN_TITLES.UIMODE
        newItem.code = MNU_CONSTANTS.ITEMS.SWITCH.UIMODE
        newItem.type = MNU_CONSTANTS.TYPES.SWITCH
        return newItem
    }


    // MARK: Desktop Usage Switching

    func makeDesktopSwitch() -> MenuItem {

        // Make and return a stock desktop usage mode switch
        let newItem: MenuItem = MenuItem()
        newItem.title = MNU_CONSTANTS.BUILT_IN_TITLES.DESKTOP
        newItem.code = MNU_CONSTANTS.ITEMS.SWITCH.DESKTOP
        newItem.type = MNU_CONSTANTS.TYPES.SWITCH
        return newItem
    }


    // MARK: Show Hidden Files Switching

    func makeHiddenFilesSwitch() -> MenuItem {

        // Make and return a stock desktop usage mode switch
        let newItem: MenuItem = MenuItem()
        newItem.title = MNU_CONSTANTS.BUILT_IN_TITLES.SHOW_HIDDEN
        newItem.code = MNU_CONSTANTS.ITEMS.SWITCH.SHOW_HIDDEN
        newItem.type = MNU_CONSTANTS.TYPES.SWITCH
        return newItem
    }


    // MARK: Update Git Trigger

    func makeGitScript() -> MenuItem {

        // Make and return a stock Git Update item
        let newItem: MenuItem = MenuItem()
        newItem.title = MNU_CONSTANTS.BUILT_IN_TITLES.GIT
        newItem.code = MNU_CONSTANTS.ITEMS.SCRIPT.GIT
        newItem.type = MNU_CONSTANTS.TYPES.SCRIPT
        return newItem
    }


    // MARK: Update Brew Trigger

    func makeBrewUpdateScript() -> MenuItem {

        // Make and return a stock Brew Update item
        let newItem: MenuItem = MenuItem()
        newItem.title = MNU_CONSTANTS.BUILT_IN_TITLES.BREW_UPDATE
        newItem.code = MNU_CONSTANTS.ITEMS.SCRIPT.BREW_UPDATE
        newItem.type = MNU_CONSTANTS.TYPES.SCRIPT
        return newItem
    }


    // MARK: Upgrade Brew Trigger

    func makeBrewUpgradeScript() -> MenuItem {

        // Make and return a stock Brew Update item
        let newItem: MenuItem = MenuItem()
        newItem.title = MNU_CONSTANTS.BUILT_IN_TITLES.BREW_UPGRADE
        newItem.code = MNU_CONSTANTS.ITEMS.SCRIPT.BREW_UPGRADE
        newItem.type = MNU_CONSTANTS.TYPES.SCRIPT
        return newItem
    }


    // MARK: Show IP Address Trigger

    func makeShowIPScript() -> MenuItem {

        // FROM 1.6.0
        // Make and return a stock Show IP Address item
        let newItem: MenuItem = MenuItem()
        newItem.title = MNU_CONSTANTS.BUILT_IN_TITLES.SHOW_IP
        newItem.code = MNU_CONSTANTS.ITEMS.SCRIPT.SHOW_IP
        newItem.type = MNU_CONSTANTS.TYPES.SCRIPT
        newItem.script = #"ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1'"#
        newItem.iconIndex = 15
        return newItem
    }


    // MARK: Show Disk Usage Trigger

    func makeShowDiskFullScript() -> MenuItem {

        // FROM 1.6.0
        // Make and return a stock Show Disk Free Space item
        let newItem: MenuItem = MenuItem()
        newItem.title = MNU_CONSTANTS.BUILT_IN_TITLES.SHOW_DF
        newItem.code = MNU_CONSTANTS.ITEMS.SCRIPT.SHOW_DF
        newItem.type = MNU_CONSTANTS.TYPES.SCRIPT
        newItem.script = "df -H /System/Volumes/Data"
        newItem.iconIndex = 2
        return newItem
    }


    // MARK: Show Grab Window Trigger

    func makeGetScreenshotOpen() -> MenuItem {

        // FROM 1.6.0
        // Make and return a stock Grab Windw item
        let newItem: MenuItem = MenuItem()
        newItem.title = MNU_CONSTANTS.BUILT_IN_TITLES.GRAB_WINDOW
        newItem.code = MNU_CONSTANTS.ITEMS.OPEN.GRAB_WINDOW
        newItem.type = MNU_CONSTANTS.TYPES.OPEN
        newItem.script = "Screenshot"
        newItem.iconIndex = 23
        return newItem
    }


    // MARK: - Helper Functions

    private func registerPreferences() {

        // Called by the app at launch to register its initial defaults
        // Set up the following keys/values:
        //   "com.bps.mnu.default-items"  - Array - MNU's default items
        //   "com.bps.mnu.item-order"     - Array - MNU's actual items (default and user-defined),
        //                                          set once the user makes any change to the default set
        //   "com.bps.mnu.startup-launch" - Bool  - Is MNU set to launch at login?
        //   "com.bps.mnu.first-run"      - Bool  - Is this MNU's first run? Set to false afterwards
        //   "com.bps.mnu.new-term-tab"   - Bool  - Should MNU run scripts in a new Terminal tab
        //   "com.bps.mnu.show-controls"  - Bool  - Should MNU show icons in the menu?
        //   From 1.6.0
        //   "com.bps.mnu.term-choice"    - Int   - Preferred Terminal by index
        //                                          0 = Apple Terminal
        //                                          1 = iTerm
        //   "com.bps.mnu.new-defs-1-6"   - Bool  - Have stored items been updated?

        // NOTE The index of a user item in the 'item-order' array is its location in the menu.
        
        // FROM 1.6.0
        let defaultItemArray: [Int] = [MNU_CONSTANTS.ITEMS.SWITCH.UIMODE, MNU_CONSTANTS.ITEMS.SWITCH.DESKTOP,
                                       MNU_CONSTANTS.ITEMS.SWITCH.SHOW_HIDDEN, MNU_CONSTANTS.ITEMS.SCRIPT.GIT,
                                       MNU_CONSTANTS.ITEMS.SCRIPT.BREW_UPDATE, MNU_CONSTANTS.ITEMS.SCRIPT.BREW_UPGRADE,
                                       MNU_CONSTANTS.ITEMS.SCRIPT.SHOW_IP, MNU_CONSTANTS.ITEMS.SCRIPT.SHOW_DF,
                                       MNU_CONSTANTS.ITEMS.OPEN.GRAB_WINDOW]

        let keyArray: [String] = ["com.bps.mnu.default-items",
                                  "com.bps.mnu.item-order",
                                  "com.bps.mnu.startup-launch",
                                  "com.bps.mnu.first-run",
                                  "com.bps.mnu.new-term-tab",
                                  "com.bps.mnu.show-controls",
                                  "com.bps.mnu.term-choice",
                                  "com.bps.mnu.new-defs-1-6"]

        let valueArray: [Any]  = [defaultItemArray,
                                  [Any](),
                                  false,
                                  true,
                                  false,
                                  true,
                                  0,
                                  3]

        assert(keyArray.count == valueArray.count, "Default preferences arrays are mismatched")
        let defaultsDict = Dictionary(uniqueKeysWithValues: zip(keyArray, valueArray))
        let defaults: UserDefaults = UserDefaults.standard
        defaults.register(defaults: defaultsDict)
        
        // FROM 1.6.0
        // Reset the stored defaults to add new items
        // NOTE This catches users only working with the default items
        if let storedDefaults: [Any] = defaults.array(forKey: "com.bps.mnu.default-items") {
            if storedDefaults.count < defaultItemArray.count {
                // Previously stored defaults don't contain new values,
                // so write them into the store
                defaults.set(defaultItemArray, forKey: "com.bps.mnu.default-items")
            }
        }
        
        defaults.synchronize()
    }


    func checkScriptExists(_ path: String, _ isTest: Bool = false) -> Bool {

        // FROM 1.5.0
        // Confirm that the user has the requisite script on their system
        // and warn them if it does not. Returns true of the script exists
        // NOTE Second parameter used to prevent alert being shown during unit testing

        if FileManager.default.fileExists(atPath: path) {
            // Command exists
            return true
        }

        if !isTest {
            let scriptName: String = (path as NSString).lastPathComponent
            showError("\(scriptName) is not installed", "You will need to install this script to run this MNU item (or hide the item).")
        }
        
        return false
    }


    private func presentError() {

        // Present a basic alert if an internal, non fatal error occurred.
        // This is primarily a debugging tool
        showError("Sorry, an internal error occurred", "Please check the details in your computer's log.")
    }


    private func showError(_ head: String, _ text: String) {

        // FROM 1.3.0
        // Show an error modal dialog on the main (UI) thread

        DispatchQueue.main.async {
            let alert: NSAlert = NSAlert.init()
            alert.messageText = head
            alert.informativeText = text
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }


    // MARK: - External Process Management Functions

    func runScriptDirect(_ code: String) {

        // Run command line apps direct, without Terminal

        #if DEBUG
        NSLog("MNU running direct command \'\(code)\'")
        #endif

        // FROM 1.3.0 - Make sure we have a command to run
        if code.count == 0 {
            showError("Command Error", "The MNU item has no command entered.")
            return
        }

        // Decode the passed string into the app and arguments
        // For example:
        //   '/usr/local/bin/pdfmaker -f jpg -s /Users/z/source -d /users/z/target'
        // becomes:
        //   'parts': ['/usr/local/bin/pdfmaker', '-f', 'jpg', '-s', '/Users/z/source', '-d', '/users/z/target']
        
        // FROM 1.6.0 -- first handle for path space escapes
        let spacedCode: String = (code as NSString).replacingOccurrences(of: "\\ ", with: "!--ESC_SPACE--!")
        let parts = (spacedCode as NSString).components(separatedBy: " ")

        // FROM 1.3.0 - Just in case that didn't quite work...
        if parts.count == 0 {
            showError("Command Error", "The command triggerd by the MNU item was malformed and couldn’t be run. Please check your code.")
            return
        }

        // TODO Add limited quoting

        // Get the app and its arguments
        let app: String = parts[0]
        var args: [String] = [String]()

        if parts.count > 1 {
            // Copy args beyond index 0 (the app)
            for i in 1..<parts.count {
                // FROM 1.6.0 -- put back per-arg spaces
                args.append((parts[i] as NSString).replacingOccurrences(of: "!--ESC_SPACE--!", with: " "))
            }
        }

        // Run the process
        // NOTE This time we wait for its conclusion
        runProcess(app: app,
                   with: (args.count > 0 ? args : []),
                   doBlock: true)
    }


    func runScript(_ code: String) {

        // Run a command line app in the Terminal

        #if DEBUG
        NSLog("MNU running shell command \'\(code)\'")
        #endif

        // Handle escapable characters
        let escapedCode: NSString = escaper(code)

        // FROM 1.6.0
        // Support multiple terminals
        let script: String
        switch (self.terminalIndex) {
        // Add the supplied script code ('escapedCode') to the boilerplate AppleScript and run it,
        // in a new Terminal tab if that is required by the user -- 'tabSelection' contains
        // script variations to accommodate this
        case 1:
            let tabSelection: String = self.doNewTermTab ? "create tab with default profile" : "current tab"
            script = """
                tell application \"iTerm\"
                activate
                if exists front window then
                set newTab to (\(tabSelection) of front window)
                else
                set newWindow to (create window with default profile)
                set newTab to (tab 0 of newWindow)
                end if
                tell current session of newTab
                write text \"\(escapedCode)\"
                end tell
                end tell
                """
        // Add other non-zero cases here to include other terminals
        default:
            if self.doNewTermTab {
                script = """
                    tell application \"Terminal\"
                    activate
                    do script (\"\(escapedCode)\")
                    end tell
                    """
            } else {
                script = """
                    tell application \"Terminal\"
                    activate
                    if not (exists first window) then
                    do script (\"\(escapedCode)\")
                    else
                    do script (\"\(escapedCode)\") in first window
                    end if
                    end tell
                    """
            }
        }
        
        #if DEBUG
        NSLog("MNU running AppleScript:\n\(script)")
        #endif
        
        runProcess(app: "/usr/bin/osascript",
                   with: ["-e", script],
                   doBlock: true)
    }


    func escaper(_ unescapedString: String) -> NSString {

        // FROM 1.3.0
        // Process the user's code string to double-escape
        // For example, if the user enters:
        //      echo "$GIT"
        // then the string is stored as:
        //      echo \"$GIT\"
        // But because this will be inserted into another string (see 'runScript()') within escaped double-quotes,
        // we have to double-escape everything, ie. make the string:
        //      echo \\\"$GIT\\\""
        // osascript then correctly interprets all the escapes
        // See also MNUTests.swift::testEscaper() for more examples

        // Convert the script string to an NSString so we can run 'replacingOccurrences()'
        var escapedCode: NSString = unescapedString as NSString
        
        // Look for user-escaped DQs and temporarily hide them
        escapedCode = escapedCode.replacingOccurrences(of: "\\\"", with: "!-USER-ESCAPED-D-QUOTES-!") as NSString
        
        // FROM 1.6.0
        // Process escaped slashes ***
        escapedCode = escapedCode.replacingOccurrences(of: "\\", with: "\\\\") as NSString
        // Look for escaped DQs
        escapedCode = escapedCode.replacingOccurrences(of: "\"", with: "\\\"") as NSString
        
        // FROM 1.6.0
        // Remove specific slash-symbol combos, which should now be covered by *** above
        // Look for escaped $ symbols: \$ -> \\$ -> \\\\$
        //escapedCode = escapedCode.replacingOccurrences(of: "\\$", with: "\\\\$") as NSString
        // Look for escaped ` symbols
        //escapedCode = escapedCode.replacingOccurrences(of: "\\`", with: "\\\\`") as NSString
        
        // Put back user-escaped DQs
        escapedCode = escapedCode.replacingOccurrences(of: "!-USER-ESCAPED-D-QUOTES-!", with: "\\\\\\\"") as NSString

        return escapedCode
    }


    func openApp(_ appName: String) {

        // ADDED 1.2.0
        // Don't present the Terminal; just open the named app directly

        #if DEBUG
        NSLog("MNU opening app \'\(appName)\'")
        #endif

        // FROM 1.5.0
        // Get the app's valid path (or nil if there isn't one)
        if let path: String = getAppPath(appName) {
            #if DEBUG
            NSLog("MNU running script \'open \(path)\'")
            #endif

            // Call 'open'
            runProcess(app: "/usr/bin/open",
                       with: [path],
                       doBlock: false)
        } else {
            showError("App \(appName) cannot be found", "Please provide an absolute path for this app in MNU’s settings")
        }
    }
    
    
    func getAppPath(_ appName: String) -> String? {

        // FROM 1.5.0
        // Set the app against each of the possible app locations
        // TODO Add ~/Applications
        
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
    
    
    private func runBundleScript(named scriptName: String, doAddPath: Bool) {

        // Load and run the named script from the application bundle

        if let scriptPath: String = Bundle.main.path(forResource: scriptName,
                                                     ofType: "scpt") {
            let appPath: String = Bundle.main.bundlePath
            var args: [String] = [scriptPath]
            if doAddPath {
                // Add 'appPath' to the args so it's passed into the
                // AppleScript 'AddToLogin' by osascript. Not required
                // for the AppleScript 'RemoveLogin'
                args.append(appPath)
            }

            // Run the process
            runProcess(app: "/usr/bin/osascript",
                       with: args,
                       doBlock: true)
        }
    }
    
    
    private func runProcess(app path: String, with args: [String], doBlock: Bool) {

        // Generic task creation and run function
        // FROM 1.3.0 - remove deprecated methods:
        //   'launchPath' -> 'executableURL',
        //   'launch()' -> 'run()'

        // FROM 1.6.1
        // Run the process on a secondary thread
        let processQueue: DispatchQueue = DispatchQueue.init(label: "com.bps.mnu.process-q")
        processQueue.async {
            let task: Process = Process.init()
            task.executableURL = URL.init(fileURLWithPath: path)
            if args.count > 0 { task.arguments = args }

            // Pipe out the output to avoid putting it in the log
            let outputPipe: Pipe = Pipe()
            task.standardOutput = outputPipe
            task.standardError = outputPipe

            /*let outputHandle = outputPipe.fileHandleForReading
            // WARNING THIS LEADS TO EXCESS CPU USAGE DURING RUN
            var outString: String = ""
            outputHandle.readabilityHandler = { fshandle in
                if let line = String(data: fshandle.availableData, encoding: String.Encoding.utf8) {
                    outString += line
                }
            }*/

            do {
                try task.run()
            } catch {
                // The script exited with an error -- most likely it doesn't exist
                self.showError("Command Error", "The app called by the MNU item doesn’t exist. Please check your code.")
                return
            }

            if doBlock {
                // Block until the task has completed (short tasks ONLY)
                task.waitUntilExit()
            }

            if !task.isRunning {
                if (task.terminationStatus != 0) {
                    // Command failed -- collect the output if there is any
                    // DOES THIS EVEN WORK?
                    let outputHandle: FileHandle = outputPipe.fileHandleForReading
                    var outString: String = ""
                    if let line: String = String(data: outputHandle.availableData, encoding: String.Encoding.utf8) {
                        outString = line
                    }

                    if outString.count > 0 {
                        self.showError("Command Error", "The MNU item’s command reported an error: \(outString)")
                    } else {
                        self.showError("Command Error", "The MNU item’s command reported an error.\nExit code \(task.terminationStatus)")
                    }
                }
            }
        }
    }


    func killFinder(andDock: Bool) {

        // Set up a task to kill the macOS Finder and, optionally, the Dock

        var args: [String] = ["Finder"]
        if andDock { args.append("Dock") }

        // Run the process
        runProcess(app: "/usr/bin/killall",
                   with: args,
                   doBlock: true)
    }


    // MARK: - NSMenuDelegate Functions

    func menuDidClose(_ menu: NSMenu) {

        // The menu has closed - tell the subviews
        NotificationCenter.default.post(name: NSNotification.Name.init(rawValue: "com.bps.mnu.will-background"),
                                        object: self)
    }


    func menuWillOpen(_ menu: NSMenu) {

        // Check to see if the Option key was down when the menu was clicked
        if NSEvent.modifierFlags.contains(NSEvent.ModifierFlags.option) {
            // Option key held down for the time, so refresh the menu with the alternative view
            // If this is a follow-on option-click, don't rebuild the menu
            if !self.optionClick {
                self.optionClick = true
                updateMenu()
            }
        } else if self.optionClick {
            // Last click, the option key was held down, but this time it is not.
            // We need to rebuild the menu to show it without the standard view
            self.optionClick = false
            updateMenu()
        }
    }

}
