
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


import Foundation
import AppKit

/**
    Manager class for the NSTabView
 */

class PMTabManager {
    
    // MARK: - Public Properties
    
    var buttons: [NSButton] = []
    var callbacks: [(()->Void)?] = []
    var parent: ConfigureViewController? = nil
    var currentIndex: Int = 0
    
    
    /**
     Return the most recently clicked button.
     
     - Returns:
        The button as an NSButton instance.
     */
    func currentButton() -> NSButton {
        
        return self.buttons[self.currentIndex]
    }
    
    
    /**
     Process the action of clicking one of the tab manager's buttons.
     
     - Parameters:
        - button: The NSButton clicked.
     */
    func buttonClicked(_ button: NSButton) {
        
        // Check the user isn't just clicking the button for the tab that
        // they're already on. If they do, bail.
        if button == self.buttons[currentIndex] {
            self.buttons[currentIndex].state = .on
            self.buttons[currentIndex].contentTintColor = .controlAccentColor
            return
        }

        // Make sure we have access to the parent controller
        guard let cvc: ConfigureViewController = self.parent else { return }
        
        // Select the required tab based on the button clicked
        guard let nextIndex: Int = self.buttons.firstIndex(of: button) else { return }
        
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
        switch nextIndex {
            case 1:
                if let handler = self.callbacks[1] {
                    handler()
                }
            case 2:
                if let handler = self.callbacks[2] {
                    handler()
                }
            default: // 0
                if let handler = self.callbacks[0] {
                    handler()
                }
        }
        
        // Select the tab we're going to show
        cvc.windowTabView.selectTabViewItem(at: nextIndex)
    }
    
    
    /**
     Auto-click a button by passing in the 'clicked' button.
     */
    func programmaticallyClickButton(_ button: NSButton) {
        
        buttonClicked(button)
    }
    
    
    /**
     Auto-click a button by passing in the index of the 'clicked' button.
     */
    func programmaticallyClickButton(at index: Int) {
        
        buttonClicked(self.buttons[index])
    }
}


