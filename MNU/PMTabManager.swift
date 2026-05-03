/*
    PMTabManager.swift
    MNU

    Created by Tony Smith on 30/09/2024.
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


/**
    Manager class for the NSTabView
 */
final public class PMTabManager {

    // MARK: - Public Properties
    
    var tabs: [PMTab]                                   = []
    var parentController: ConfigureViewController?      = nil
    var parentWindow: NSWindow?                         = nil
    var currentIndex: Int                               = 0

    var currentTabName: String? {
        get {
            guard self.tabs.count > self.currentIndex else { return nil }
            return self.tabs[self.currentIndex].name
        }
    }

    var currentButton: NSButton? {
        get {
            guard self.tabs.count > self.currentIndex else { return nil }
            return self.tabs[self.currentIndex].button
        }
    }

    var currentTab: PMTab? {
        get {
            guard self.tabs.count > self.currentIndex else { return nil }
            return self.tabs[self.currentIndex]
        }
    }


    // MARK: - Tab Control Functions

    /**
     Process the action of clicking one of the tab manager's buttons.
     
     - Parameters:
        - button: The NSButton clicked.
     */
    public func buttonClicked(_ button: NSButton) {

        // Check the user isn't just clicking the button for the tab that
        // they're already on. If they do, bail.
        guard self.tabs.count > self.currentIndex else { return }

        // Check if the current button is being clicked
        guard button != self.tabs[currentIndex].button else {
            button.state = .on
            button.contentTintColor = .controlAccentColor
            return
        }

        // Make sure we have access to the parent controller
        guard let cvc: ConfigureViewController = self.parentController else { return }

        // Select the required tab based on the button clicked
        var nextIndex = -1
        for (index, tab) in self.tabs.enumerated() {
            if tab.button == button {
                nextIndex = index
                break
            }
        }

        guard nextIndex != -1 else { return }

        // Moving from a resizeable tab? Then preserve its size
        // NOTE The called fuunction performs the resizeable check
        preserveCurrentSizeOfTabAt(index: self.currentIndex)

        // Enable the current tab's button and disable the rest
        self.currentIndex = nextIndex
        for i in 0..<self.tabs.count {
            if let button = self.tabs[i].button {
                if i != nextIndex {
                    button.state = .off
                    button.contentTintColor = .gray
                } else {
                    button.state = .on
                    button.contentTintColor = .controlAccentColor
                }
            }
        }
        
        // Perform tab-specific logic BEFORE switching
        // NOTE These closures are set in the app delegate
        let nextTab = self.tabs[nextIndex]
        if let handler = nextTab.callback {
            handler()
        }

        // Select the actual tab we're going to show
        cvc.windowTabView.selectTabViewItem(at: nextIndex)

        // Adjust the parent window's size to match the tab content size
        setWindowSize()
    }
    
    
    /**
     Auto-click a button by passing in the 'clicked' button.
     */
    public func programmaticallyClickButton(_ button: NSButton) {

        buttonClicked(button)
    }
    
    
    /**
     Auto-click a button by passing in the index of the 'clicked' button.
     */
    public func programmaticallyClickButton(at index: Int) {

        guard let button = self.tabs[index].button else { return }
        buttonClicked(button)
    }


    /**
     Set the window's content size on a tab switch, provided a size has
     been set.
     */
    public func setWindowSize() {

        guard let pw = parentWindow else { return }
        guard self.tabs.count > self.currentIndex else { return }

        let targetTab = self.tabs[self.currentIndex]
        guard let targetSize = self.tabs[self.currentIndex].currentSize else { return }

        var windowTopLeftPoint = pw.frame.origin
        windowTopLeftPoint.y += pw.frame.size.height - targetSize.height - 32

        let targetRect = NSRect(origin: pw.frame.origin, size: targetSize)
        var targetFrame = pw.frameRect(forContentRect: targetRect)
        targetFrame.origin = windowTopLeftPoint

        // Make sure the window fits in the screen, but only if it's resizeable
        if targetTab.isResizeable {
            // Make sure it's not off the bottom of the screen
            if targetFrame.origin.y < 0 {
                targetFrame.origin.y = 0
            }

            // Check the above adjustment doesn't move the window
            // up off the screen
            let screenFrame: CGRect
            if let screen = pw.screen {
                screenFrame = screen.frame
            } else {
                screenFrame = targetFrame
            }

            if targetFrame.size.height + targetFrame.origin.y > screenFrame.size.height + screenFrame.origin.y {
                let delta = targetFrame.origin.y + targetFrame.size.height - screenFrame.size.height - screenFrame.origin.y
                targetFrame.size.height -= delta
            }

            // Apply max and min heights, if set
            if let maxSize = self.tabs[self.currentIndex].maximumSize { pw.contentMaxSize = maxSize }
            if let minSize = self.tabs[self.currentIndex].minimumSize { pw.contentMinSize = minSize }
        }

        // Apply the new window size
        pw.setFrame(targetFrame, display: false, animate: true)
    }


    /**
     If the tab at the specified index is resizeable, store its
     current content size.

     - Parameters:
        - index: The specified tab index.
     */
    public func preserveCurrentSizeOfTabAt(index: Int) {

        guard self.tabs.count > index else { return }

        if self.tabs[index].isResizeable && self.parentWindow != nil {
            self.tabs[index].currentSize = self.parentWindow!.contentView?.frame.size ?? MNU_CONSTANTS.CONFIG_TAB_PANEL_SIZE.MENU_LIST
        }
    }


    /**
     Clear all of the manager's tabs' current size values ensuring from this
     call onwwards, each tab will report its default size.
     */
    public func resetSizes() {

        for tab in self.tabs {
            tab.currentSize = nil
        }
    }
}


