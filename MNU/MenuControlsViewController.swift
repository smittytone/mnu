
/*
    MenuControlsViewController.swift
    MNU

    Created by Tony Smith on 20/08/2019.
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


final class MenuControlsViewController: NSViewController {

    // MARK: - UI Outlets

    @IBOutlet var appControlView: NSView!                   // The last view on the menu is the control bar
    @IBOutlet var appControlQuitButton: NSButton!           // The Quit button
    @IBOutlet var appControlConfigureButton: NSButton!      // The Configure button
    @IBOutlet var appControlHelpButton: NSButton!           // The Help button


    // MARK: - Public Class Properties

    var controlMenuItem: NSMenuItem? = nil


    // MARK: - View Lifecycle Functions

    override func viewDidLoad() {

        super.viewDidLoad()

        // Set up the control bar button tooltips
        self.appControlConfigureButton.toolTip = "Click to configure MNU"
        self.appControlQuitButton.toolTip = "Click to quit MNU"
        self.appControlHelpButton.toolTip = "Click to view online help information"

        // Set up the menu item
        self.controlMenuItem = NSMenuItem.init(title: "APP-CONTROL",
                                               action: nil,
                                               keyEquivalent: "")
        self.controlMenuItem!.view = self.appControlView
        self.controlMenuItem!.target = self
    }


    // MARK: - App Action Functions

    @IBAction @objc private func doQuit(sender: Any?) {

        // Quit the app
        NSApp.terminate(self)
    }


    @IBAction @objc private func doHelp(sender: Any?) {

        // Show the 'Help' via the website
        // TODO provide offline help
        if let helpURL: URL = URL.init(string: MNU_SECRETS.WEBSITE.URL_MAIN + "#how-to-use-mnu") {
            NSWorkspace.shared.open(helpURL)
        }
    }


    @IBAction @objc private func doConfigure(sender: Any?) {

        // Tell the app delegate to open the Configure window
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "com.bps.mnu.show-configure"),
                                        object: self)
    }
    
}
