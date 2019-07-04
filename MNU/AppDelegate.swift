
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

    var controllers: [String:Any] = [:]
    var task: Process? = nil

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
        var controller: MenuItemViewController = makeSwitchController(title: "macOS UI Mode")
        controller.offImageName = "light_mode_icon"
        controller.onImageName = "dark_mode_icon"
        controller.state = self.inDarkMode
        controller.action = #selector(self.doModeSwitch(sender:))

        var anItem: NSMenuItem = NSMenuItem.init(title: "MODE-SW",
                                                 action: nil,
                                                 keyEquivalent: "")
        anItem.view = controller.view

        // If we're running on a version of macOS that doesn't do Dark Mode, grey out
        // the control and disable the switch
        controller.viewSwitch.isEnabled = !disableDarkMode
        if (disableDarkMode) {
            controller.viewText.textColor = NSColor.secondaryLabelColor
            controller.viewImage.alphaValue = 0.4
        }

        // Add the menu item and a separator
        self.appMenu!.addItem(anItem)
        self.appMenu!.addItem(NSMenuItem.separator())

        // Desktop Usage Item
        controller = makeSwitchController(title: "Show Files on Desktop")
        controller.onImageName = "desktop_icon_on"
        controller.offImageName = "desktop_icon_off"
        controller.state = self.useDesktop
        controller.action = #selector(self.doDesktopSwitch(sender:))

        anItem = NSMenuItem.init(title: "DESK-SW",
                                 action: nil,
                                 keyEquivalent: "")
        anItem.view = controller.view
        self.appMenu!.addItem(anItem)
        self.appMenu!.addItem(NSMenuItem.separator())

        // Gitup Item
        var buttonController: ButtonViewController = makeButtonController(title: "Update Git")
        buttonController.offImageName = "logo_gt"
        buttonController.onImageName = "logo_gt"
        buttonController.action = #selector(self.doGit(sender:))

        anItem = NSMenuItem.init(title: "GIT-ACT",
                                 action: nil,
                                 keyEquivalent: "")
        anItem.view = buttonController.view
        self.appMenu!.addItem(anItem)
        self.appMenu!.addItem(NSMenuItem.separator())

        // brew Item
        buttonController = makeButtonController(title: "Update Brew")
        buttonController.offImageName = "logo_br"
        buttonController.onImageName = "logo_br"
        buttonController.action = #selector(self.doBrew(sender:))

        anItem = NSMenuItem.init(title: "BREW-ACT",
                                 action: nil,
                                 keyEquivalent: "")
        anItem.view = buttonController.view
        self.appMenu!.addItem(anItem)
        self.appMenu!.addItem(NSMenuItem.separator())

        // Info/Help Item
        anItem = NSMenuItem.init(title: "APP-INFO",
                                 action: #selector(self.doHelp),
                                 keyEquivalent: "")
        anItem.view = self.appInfoView
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

        // Close the menu - required for controls within views added to menu items
        // self.appMenu!.cancelTracking()

        let controller: MenuItemViewController = self.controllers["Show Files on Desktop"] as! MenuItemViewController
        controller.setImage(isOn: self.useDesktop)

        // Run the task
        runProcess(app: "/usr/bin/osascript", with: [arg], doBlock: true)
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

        let controller: MenuItemViewController = self.controllers["Show Files on Desktop"] as! MenuItemViewController
        controller.setImage(isOn: self.useDesktop)

        // Run the task to restart the Finder
        killFinder(andDock: false)
    }


    @IBAction @objc func doGit(sender: Any?) {

        let args: [String] = ["-e tell application \"Terminal\" to activate", "-e tell application \"Terminal\" to do script (\"gitup\")"]

        // Close the menu - required for controls within views added to menu items
        self.appMenu!.cancelTracking()

        // Run the task
        runProcess(app: "/usr/bin/osascript", with: args, doBlock: true)
    }


    @IBAction @objc func doBrew(sender: Any?) {

        let args: [String] = ["-e tell application \"Terminal\" to activate", "-e tell application \"Terminal\" to set currentTab to do script (\"brew update\")"]

        // Close the menu - required for controls within views added to menu items
        self.appMenu!.cancelTracking()

        // Run the task
        runProcess(app: "/usr/bin/osascript", with: args, doBlock: true)
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


    @IBAction @objc func doTest(sender: Any?) {

        let deskSwitch: NSButton = sender as! NSButton
        let controller: MenuItemViewController = self.controllers["Use Desktop Features"] as! MenuItemViewController
        controller.setImage(isOn: (deskSwitch.state == NSControl.StateValue.on ? true : false))
    }


    // MARK: - Miscellaneous Functions

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


    func makeSwitchController(title: String) -> MenuItemViewController {

        // Create and return a new generic switch view controller
        let controller: MenuItemViewController = MenuItemViewController.init(nibName: nil, bundle: nil)
        controller.text = title
        controller.state = false

        // Add the new controller to the list of controllers
        self.controllers[title] = controller

        // Return the controller for usage
        return controller
    }


    func makeButtonController(title: String) -> ButtonViewController {

        // Create and return a new generic button view controller
        let controller: ButtonViewController = ButtonViewController.init(nibName: nil, bundle: nil)
        controller.text = title
        controller.state = true

        // Add the new controller to the list of controllers
        self.controllers[title] = controller

        // Return the controller for usage
        return controller
    }
}

