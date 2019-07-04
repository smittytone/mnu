
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

    // MARK: - UI Properties - Built-ins

    @IBOutlet weak var modeSwitchView: NSView!
    @IBOutlet weak var modeSwitchControl: NSSegmentedControl!
    @IBOutlet weak var modeSwitchText: NSTextField!

    @IBOutlet weak var appInfoView: NSView!
    @IBOutlet weak var appInfoControl: NSButton!


    // MARK: - App Functions

    var statusItem: NSStatusItem? = nil
    var appMenu: NSMenu? = nil
    var inDarkMode: Bool = false
    var useDesktop: Bool = false

    var controllers: [MenuItemViewController]? = nil


    // MARK: - App Lifecycle Functions

    func applicationDidFinishLaunching(_ aNotification: Notification) {

        // First ensure we are running on Mojave or above -
        // Dark Mode not supported by earlier versons
        var disableDarkMode: Bool = false
        let sysVer: OperatingSystemVersion = ProcessInfo.processInfo.operatingSystemVersion
        if sysVer.minorVersion < 14 {
            // Wrong version!
            let alert = NSAlert.init()
            alert.messageText = "Unsupported version of macOS"
            alert.informativeText = "MNU makes use of features not present in the version of macOS (\(sysVer.majorVersion).\(sysVer.minorVersion).\(sysVer.patchVersion)) running on your computer. Please conisder upgrading to macOS 10.14 or higher."
            alert.addButton(withTitle: "OK")
            alert.runModal()
            disableDarkMode = true
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

        // Create the app's menu
        self.appMenu = NSMenu.init(title: "MNU")

        // Add the stock Dark Mode item
        var anItem: NSMenuItem = NSMenuItem.init(title: "MODE-SW",
                                                 action: nil,
                                                 keyEquivalent: "")
        anItem.view = modeSwitchView
        anItem.target = self;
        modeSwitchControl.selectSegment(withTag: (self.inDarkMode ? 1 : 0))

        // If we're running on a version of macOS that doesn't do Dark Mode, grey out
        // the control and disable the switch
        modeSwitchControl.isEnabled = !disableDarkMode
        if (disableDarkMode) { modeSwitchText.textColor = NSColor.secondaryLabelColor }

        // Add the menu item and a separator
        self.appMenu!.addItem(anItem)
        self.appMenu!.addItem(NSMenuItem.separator())

        // Desktop Usage Item
        var controller = makeController(title: "Show Files on Desktop")
        controller.state = self.useDesktop
        controller.action = #selector(self.doDesktopSwitch(sender:))

        anItem = NSMenuItem.init(title: "DESK-SW",
                                 action: nil,
                                 keyEquivalent: "")
        anItem.view = controller.view
        self.appMenu!.addItem(anItem)
        self.appMenu!.addItem(NSMenuItem.separator())

        // Test Item
        controller = makeController(title: "Use Desktop Features")
        controller.action = #selector(self.doQuit)

        anItem = NSMenuItem.init(title: "TEST-SW",
                                 action: nil,
                                 keyEquivalent: "")
        anItem.view = controller.view
        self.appMenu!.addItem(anItem)
        self.appMenu!.addItem(NSMenuItem.separator())

        // Info/Help Item
        anItem = NSMenuItem.init(title: "APP-INFO",
                                 action: #selector(self.doHelp),
                                 keyEquivalent: "")
        anItem.view = appInfoView
        anItem.target = self;
        self.appMenu!.addItem(anItem)

        // Add the app menu to the macOS menu bar
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


    func applicationWillTerminate(_ aNotification: Notification) {

        // Insert code here to tear down your application
    }


    // MARK: - App Action Functions

    @IBAction @objc func doModeSwitch(sender: Any?) {

        // Set up the task that will call the shell/AppleScript
        // to switch the UI mode

        var arg: String = "-e tell application \"System Events\" to tell appearance preferences to set dark mode to "

        // Modify the script according to user selection
        let modeSwitch: NSSegmentedControl = sender as! NSSegmentedControl

        if modeSwitch.selectedSegment == 0 {
            // Light Mode
            arg += "false"
            self.inDarkMode = false
        } else {
            // Dark mode
            arg += "true"
            self.inDarkMode = true
        }

        // Close the menu - required for controls within views added to menu items
        self.appMenu!.cancelTracking()

        // Run the task
        runProcess(app: "/usr/bin/osascript", with: [arg])
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

        // Run the task to restart the Finder
        killFinder(andDock: false)
    }


    @IBAction @objc func doQuit(sender: Any?) {

        // Quit the app
        NSApp.terminate(self)
    }


    @IBAction @objc func doHelp(sender: Any?) {

        // Show the 'Help' via the website
        let nswsp = NSWorkspace.shared
        nswsp.open(URL.init(string:"https://smittytone.github.io/squinter/index.html")!)
    }


    // MARK: - Miscellaneous Functions

    func killFinder(andDock: Bool) {

        // Set up a task to kill the macOS Finder and, optionally, the Dock
        var args: [String] =  ["Finder"]
        if andDock { args.append("Dock") }
        runProcess(app: "/usr/bin/killall", with: args)
    }


    func runProcess(app path: String, with args: [String]) {

        // Generic task creation and run function
        let task = Process()
        task.launchPath = path
        task.arguments = args
        task.launch()
        task.waitUntilExit()
    }


    func makeController(title: String) -> MenuItemViewController {

        // Create and return a new generic switch controller
        let controller: MenuItemViewController = MenuItemViewController.init(nibName: nil, bundle: nil)
        controller.text = title
        controller.state = false

        // Add the new controller to the list of controllers
        if self.controllers == nil {
            self.controllers = [controller]
        } else {
            self.controllers!.append(controller)
        }

        return controller
    }
}

