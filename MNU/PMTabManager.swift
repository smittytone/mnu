
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
    
    var buttons: [NSButton] = []
    var parentController: ConfigureViewController? = nil
    var currentIndex: Int = 0
    // FROM 2.2.0
    var parentWindow: NSWindow? = nil
    var tabs: [PMTab] = []

    var currentName: String? {
        get {
            guard self.tabs.count > self.currentIndex else { return nil }
            return self.tabs[self.currentIndex].name
        }
    }

    var currentButton: NSButton? {
        get {
            guard self.buttons.count > self.currentIndex else { return nil }
            return self.buttons[self.currentIndex]
        }
    }

    var currentTab: PMTab? {
        get {
            guard self.tabs.count > self.currentIndex else { return nil }
            return self.tabs[self.currentIndex]
        }
    }

    
    /**
     Process the action of clicking one of the tab manager's buttons.
     
     - Parameters:
        - button: The NSButton clicked.
     */
    public func buttonClicked(_ button: NSButton) {

        // Check the user isn't just clicking the button for the tab that
        // they're already on. If they do, bail.
        guard self.buttons.count > self.currentIndex else { return }
        guard button != self.buttons[currentIndex] else { return }
        //    self.buttons[currentIndex].state = .on
        //    self.buttons[currentIndex].contentTintColor = .controlAccentColor
        //    return
        //}

        // Make sure we have access to the parent controller
        guard let cvc: ConfigureViewController = self.parentController else { return }
        
        // Select the required tab based on the button clicked
        guard let nextIndex: Int = self.buttons.firstIndex(of: button) else { return }

        // Moving from tab zero? Then preserve its size
        if let pw = self.parentWindow {
            if self.currentIndex == 0 {
                self.tabs[0].currentSize = pw.contentView?.frame.size ?? MNU_CONSTANTS.CONFIG_TAB_PANEL_SIZE.MENU_LIST
            }
        }

        // Enable the current tab's button and disable the rest
        self.currentIndex = nextIndex
        for i in 0..<self.buttons.count {
            if i != nextIndex {
                self.buttons[i].state = .off
                self.buttons[i].contentTintColor = .gray
            } else {
                self.buttons[i].state = .on
                self.buttons[i].contentTintColor = .controlAccentColor
            }
        }
        
        // Perform tab-specific logic BEFORE switching
        // NOTE These closures are set in the app delegate
        let nextTab = self.tabs[nextIndex]
        if let handler = nextTab.callback {
            handler()
        }

        // Select the tab we're going to show
        cvc.windowTabView.selectTabViewItem(at: nextIndex)
        sizeWindow()
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

        buttonClicked(self.buttons[index])
    }


    /**
     Set the window's content size on a tab switch, provided a size has
     been set.
     */
    private func sizeWindow() {

        guard let pw = parentWindow else { return }
        guard self.tabs.count > self.currentIndex else { return }
        let targetTab = self.tabs[self.currentIndex]
        guard let targetSize = self.tabs[self.currentIndex].currentSize else { return }
        pw.setContentSize(targetSize)

        if targetTab.isResizeable {
            guard let maxSize = self.tabs[self.currentIndex].maximumSize else { return }
            guard let minSize = self.tabs[self.currentIndex].minimumSize else { return }
            pw.contentMaxSize = maxSize
            pw.contentMinSize = minSize
        }
    }
}


