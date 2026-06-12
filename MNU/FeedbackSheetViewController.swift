/*
    FeedbackSheetViewController.swift
    MNU

    Created by Tony Smith on 27/07/2019.
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


final class FeedbackSheetViewController: NSViewController,
                                         NSTextFieldDelegate,
                                         URLSessionDelegate,
                                         URLSessionDataDelegate {

    // MARK: - UI Outlets

    @IBOutlet var feedbackSheet: NSWindow!
    @IBOutlet var feedbackText: AddUserItemTextField!
    @IBOutlet var connectionProgress: NSProgressIndicator!
    

    // MARK: - Public Class Properties

    var parentWindow: NSWindow? = nil


    // MARK: - Lifecycle Functions

    /**
     This function should be called to prepare the feedback sheet for viewing.
     */
    func showSheet() {
        
        // Reset the UI
        self.connectionProgress.stopAnimation(self)
        self.feedbackText.stringValue = ""
        self.feedbackText.isEditable = true
        self.feedbackText.becomeFirstResponder()

        // Present the sheet
        if let window = self.parentWindow {
            window.beginSheet(self.feedbackSheet,
                              completionHandler: nil)
        }
    }


    // MARK: - User Actions
    
    @IBAction
    @objc
    func doCancel(sender: Any?) {
        
        // Stop editing the NSTextField
        endEditing()

        // Close the sheet
        closeFeedackSheet()
    }


    @IBAction
    @objc
    func doSend(sender: Any?) {
        
        let feedback = self.feedbackText.stringValue
        if feedback.isEmpty {
            closeFeedackSheet()
            return
        }

        // FROM 2.5.0
        // Use Swift Concurrency
        // NOTE Use of Task and closure required because @IBAction functions
        //      cannot be `async`, but we make an `await` call later on
        Task { @MainActor in
            // Post the feedback asynchronously
            let error = await self.sendFeedback(feedback)
            self.connectionProgress.stopAnimation(self)
            if error.code != .noError {
                // Error - inform the user
                await presentFeedbackError(error)
            } else {
                // No error - feedback sent successfully
                await presentFeedbackSuccess()
            }
        }
    }


    // MARK: - Alert Functions

    /**
     Present an error message specific to sending feedback.

     This is called from multiple locations: if the initial request can't be created,
     there was a send failure, or a server error.

     FROM 2.5.0
     */
    private func presentFeedbackError(_ error: FeedbackError) async {

        await showFeedbackAlert("Feedback Could Not Be Sent",
                                "Unfortunately, your comments could not be send at this time. Please try again later.\n\nReason: \(error.localizedDescription)")
    }


    /**
     Present a message on successfully sending feedback.

     FROM 2.5.0
     */
    private func presentFeedbackSuccess() async {

        await showFeedbackAlert("Thanks For Your Feedback!",
                                "Your comments have been received and we’ll take a look at them shortly.")

    }


    /**
     Generic alert generator.

     FROM 2.5.0

     - Parameters:
        - head:        The alert's title.
        - message:     The alert's message.
     */
    private func showFeedbackAlert(_ head: String, _ message: String) async {

        let alert = NSAlert()
        alert.messageText = head
        alert.informativeText = message
        alert.beginSheetModal(for: self.feedbackSheet) { (_) in
            self.endEditing()
            self.closeFeedackSheet()
        }
    }


    // MARK: - Misc Functions

    /**
     Send entered feedback to the server.

     FROM 2.5.0

     - Parameters:
        - `feedback`: The text of the feedback

     - Returns: An error instance.
     */
    private func sendFeedback(_ feedback: String) async -> FeedbackError {

        // Start the connection indicator if it's not already visible
        self.connectionProgress.startAnimation(self)
        defer { self.connectionProgress.stopAnimation(self) }

        // Send the string etc.
        let userAgent = getUserAgentForFeedback()
        let date = getDateForFeedback()

        // Assemble the message string
        let message = """
         *FEEDBACK REPORT*
         *Date:* \(date)
         *User Agent:* \(userAgent)
         *Feedback:*
         \(feedback)
         """

        // Build the data we will POST:
        let payload = NSMutableDictionary()
        payload.setObject(message, forKey: NSString(string: "text"))
        payload.setObject(true, forKey: NSString(string: "mrkdown"))

        if let url = URL(string: MNU_SECRETS.ADDRESS.B + MNU_SECRETS.ADDRESS.A) {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue(userAgent, forHTTPHeaderField: "User-Agent")
            request.addValue("application/json", forHTTPHeaderField: "Content-type")

            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: payload,
                                                              options:JSONSerialization.WritingOptions(rawValue: 0))
            } catch {
                return FeedbackError(code: .badEncode)
            }

            // Send the feedback
            do {
                let (_, response): (Data, URLResponse) = try await URLSession.shared.data(for: request)

                // Check we received an HTTP response
                guard let httpResponse = response as? HTTPURLResponse else {
                    return FeedbackError(code: .badResponse)
                }

                // Check the HTTP response status code
                guard (200..<300).contains(httpResponse.statusCode) else {
                    return FeedbackError(code: .badStatusCode, text: "\(httpResponse.statusCode)")
                }
            } catch {
                // TX failed
                return FeedbackError(code: .badSession)
            }
        }

        return FeedbackError(code: .noError)
    }


    /**
     Build a basic 'major.manor' version string for prefs usage.
     
     // FROM 1.5.1
     
     - Returns The version string.
     */
    func getVersion() -> String {
        
        let version: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        let parts: [String] = (version as NSString).components(separatedBy: ".")
        return parts[0] + "-" + parts[1]
    }


    /**
     Get the current date.
     
     FROM 1.5.1 -- Refactor code out into separate function for clarity.
     
     - Returns The date string.
     */
    private func getDateForFeedback() -> String {

        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        return dateFormatter.string(from: date)
    }


    /**
     Get the user agent.
     
     FROM 1.5.1 -- Refactor code out into separate function for clarity.
     
     - Returns The user agent string.
     */
    private func getUserAgentForFeedback() -> String {

        let sysVer = ProcessInfo.processInfo.operatingSystemVersion
        let bundle = Bundle.main
        let app = bundle.object(forInfoDictionaryKey: "CFBundleExecutable") as! String
        let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        let build = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as! String

        // FROM 1.7.0
        // Standardise the user agent format
        return "\(app)/\(version)-\(build) (macOS/\(sysVer.majorVersion).\(sysVer.minorVersion).\(sysVer.patchVersion))"
    }


    /**
     End editing of the primary text field.
     */
    @MainActor
    private func endEditing() {

        if let theText = self.feedbackText.currentEditor() {
            self.feedbackText.endEditing(theText)
        }
    }


    /**
     Close the feedback sheet and zap the reference to the parent window.
     */
    @MainActor
    private func closeFeedackSheet() {

        self.parentWindow!.endSheet(self.feedbackSheet)
        self.parentWindow = nil
    }

}
