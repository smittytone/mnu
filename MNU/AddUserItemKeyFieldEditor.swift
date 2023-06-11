/*
    AddUserItemKeyFieldEditor.swift
    MNU

    Created by Tony Smith on 11/06/2023.
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


import Foundation
import Cocoa


final class AddUserItemKeyFieldEditor: NSTextView {


    // MARK: - Public Class Properties

    var keyTextField: AddUserItemKeyTextField? = nil

    
    // MARK: - Private Class Properties

    private let commandKey: UInt = NSEvent.ModifierFlags.command.rawValue
    private let shiftKey: UInt = NSEvent.ModifierFlags.shift.rawValue
    private let optKey: UInt = NSEvent.ModifierFlags.option.rawValue
    private let ctrlKey: UInt = NSEvent.ModifierFlags.control.rawValue


    // MARK: - Standard Key Handling Functions

    override func keyDown(with event: NSEvent) {

        // This traps Shift and Option modifiers, plus unmodified key presses

        let _ = processEvent(event)
    }


    override func performKeyEquivalent(with event: NSEvent) -> Bool {

        // This traps Command and Control modifiers

        return processEvent(event)
    }


    // MARK: - Standard Edit Functions

    override func copy(_ sender: Any?) {

        processStandard(MNU_CONSTANTS.EDIT_CMD_COPY)
    }


    override func cut(_ sender: Any?) {

        processStandard(MNU_CONSTANTS.EDIT_CMD_CUT)
    }


    override func paste(_ sender: Any?) {

        processStandard(MNU_CONSTANTS.EDIT_CMD_PASTE)
    }


    override func selectAll(_ sender: Any?) {

        processStandard(MNU_CONSTANTS.EDIT_CMD_ALL)
    }


    // MARK: - Internal Key Combination Handlers

    private func processEvent(_ event: NSEvent) -> Bool {

        // A generic key press handler

        var modKeyUsed: Bool = false

        // Extract the modifier key held (if one was
        let bitfield = event.modifierFlags.rawValue & NSEvent.ModifierFlags.deviceIndependentFlagsMask.rawValue

        if let keyTextField: AddUserItemKeyTextField = self.keyTextField {
            if let segment: NSSegmentedControl = keyTextField.segment {
                // NOTE Deselect all segments first on a per-press basis, in case
                //      the user taps an unmodified key afterwards, ie. only a
                //      different modifiers should clear existing modifiers.
                if bitfield & commandKey != 0 {
                    segment.selectedSegment = -1
                    segment.selectSegment(withTag: MNU_CONSTANTS.MOD_KEY_CMD)
                    modKeyUsed = true
                }

                if bitfield & shiftKey != 0 {
                    segment.selectedSegment = -1
                    segment.selectSegment(withTag: MNU_CONSTANTS.MOD_KEY_SHIFT)
                    modKeyUsed = true
                }

                if bitfield & optKey != 0 {
                    segment.selectedSegment = -1
                    segment.selectSegment(withTag: MNU_CONSTANTS.MOD_KEY_OPT)
                    modKeyUsed = true
                }

                if bitfield & ctrlKey != 0 {
                    segment.selectedSegment = -1
                    segment.selectSegment(withTag: MNU_CONSTANTS.MOD_KEY_CTRL)
                    modKeyUsed = true
                }
            }

            // Drop the pressed key into the linked NSTextField, ensuring we
            // only drop the first character from multi-character strings
            let theKeys: String = event.charactersIgnoringModifiers ?? ""
            if theKeys.count > 1 {
                let index: String.Index = String.Index(utf16Offset: 1, in: theKeys)
                keyTextField.stringValue = String(theKeys[index...]).uppercased()
            } else {
                keyTextField.stringValue = theKeys.uppercased()
            }
        }

        return modKeyUsed
    }


    private func processStandard(_ code: Int) {

        // Handle the Field Editor's standard text editing key equivalents.
        // These are not trapped by `performKeyEquivalent()`.

        let rawKeys: [String] = ["C", "X", "V", "A", "Z"]

        if let keyTextField: AddUserItemKeyTextField = self.keyTextField {
            if let segment: NSSegmentedControl = keyTextField.segment {
                // Deselect all segments...
                segment.selectedSegment = -1

                // ...then select the segment representing the pressed modifier
                segment.selectedSegment = MNU_CONSTANTS.MOD_KEY_CMD
            }

            // Set the text field's string
            keyTextField.stringValue = rawKeys[code]
        }
    }


    @objc func undo() {

        // Handler for Undo operations
        
        processStandard(MNU_CONSTANTS.EDIT_CMD_UNDO)
    }
}
