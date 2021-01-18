
/*
    FeedbackSheetViewController.swift
    MNU

    Created by Tony Smith on 27/07/2019.
    Copyright © 2021 Tony Smith. All rights reserved.

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


class FeedbackSheetViewController: NSViewController,
                                   URLSessionDelegate,
                                   URLSessionDataDelegate {

    // MARK: - UI Outlets

    @IBOutlet var feedbackSheet: NSWindow!
    @IBOutlet var feedbackText: NSTextField!
    @IBOutlet var connectionProgress: NSProgressIndicator!
    

    // MARK: - Class Properties

    var parentWindow: NSWindow? = nil
    private var feedbackTask: URLSessionTask? = nil


    // MARK: - Lifecycle Functions

    func showSheet() {
        
        // This function should be called to prepare the feedback sheet for viewing
        
        // Reset the UI
        self.connectionProgress.stopAnimation(self)
        self.feedbackText.stringValue = ""

        // Present the sheet
        if let window = self.parentWindow {
            window.beginSheet(self.feedbackSheet,
                              completionHandler: nil)
        }
    }

    
    // MARK: - User Actions

    @IBAction @objc func doCancel(sender: Any?) {

        // User has clicked 'Cancel', so just close the sheet
        
        self.parentWindow!.endSheet(self.feedbackSheet)
        self.parentWindow = nil
    }


    @IBAction @objc func doSend(sender: Any?) {

        // User clicked 'Send' so get the message (if there is one) from the text field and send it
        
        let feedback: String = self.feedbackText.stringValue

        if feedback.count > 0 {
            // Start the connection indicator if it's not already visible
            self.connectionProgress.startAnimation(self)

            // Send the string etc.
            let sysVer: OperatingSystemVersion = ProcessInfo.processInfo.operatingSystemVersion
            let bundle: Bundle = Bundle.main
            let app: String = bundle.object(forInfoDictionaryKey: "CFBundleExecutable") as! String
            let version: String = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
            let build: String = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as! String
            let userAgent: String = "\(app) \(version) (build \(build)) (macOS \(sysVer.majorVersion).\(sysVer.minorVersion).\(sysVer.patchVersion))"

            let date: Date = Date()
            var dateString = "Unknown"

            let def: DateFormatter = DateFormatter()
            def.locale = Locale(identifier: "en_US_POSIX")
            def.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
            def.timeZone = TimeZone(secondsFromGMT: 0)
            dateString = def.string(from: date)

            let dict: NSMutableDictionary = NSMutableDictionary()
            dict.setObject("*FEEDBACK REPORT*\n*DATE* \(dateString))\n*USER AGENT* \(userAgent)\n*FEEDBACK* \(feedback)",
                            forKey: NSString.init(string: "text"))
            dict.setObject(true, forKey: NSString.init(string: "mrkdown"))

            if let url: URL = URL.init(string: MNU_SECRETS.ADDRESS.A + MNU_SECRETS.ADDRESS.B) {
                var request: URLRequest = URLRequest.init(url: url)
                request.httpMethod = "POST"
                do {
                    request.httpBody = try JSONSerialization.data(withJSONObject: dict,
                                                                  options:JSONSerialization.WritingOptions.init(rawValue: 0))

                    request.addValue(userAgent, forHTTPHeaderField: "User-Agent")
                    request.addValue("application/json", forHTTPHeaderField: "Content-type")

                    let config: URLSessionConfiguration = URLSessionConfiguration.ephemeral
                    let session: URLSession = URLSession.init(configuration: config,
                                                              delegate: self,
                                                              delegateQueue: OperationQueue.main)
                    self.feedbackTask = session.dataTask(with: request)
                    self.feedbackTask?.resume()
                } catch {
                    sendFeedbackError()
                }
            }
        } else {
            self.parentWindow!.endSheet(self.feedbackSheet)
            self.parentWindow = nil
        }
    }

    
    // MARK: - URLSession Delegate Functions

    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {

        // Some sort of connection error - report it
        
        sendFeedbackError()
    }


    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {

        // The operation to send the comment completed
        
        if let _ = error {
            // An error took place - report it
            sendFeedbackError()
        } else {
            // The comment was submitted successfully
            let alert: NSAlert = NSAlert()
            alert.messageText = "Thanks For Your Feedback!"
            alert.informativeText = "Your comments have been received and we’ll take a look at them shortly."
            alert.addButton(withTitle: "OK")
            alert.beginSheetModal(for: self.feedbackSheet) { (resp) in
                // Close the feedback window when the modal alert returns
                self.parentWindow!.endSheet(self.feedbackSheet)
            }
        }
    }

    
    // MARK: - Misc Functions

    func sendFeedbackError() {

        // Present an error message specific to sending feedback
        // This is called from multiple locations: if the initial request can't be created,
        // there was a send failure, or a server error
        
        let alert: NSAlert = NSAlert()
        alert.messageText = "Feedback Could Not Be Sent"
        alert.informativeText = "Unfortunately, your comments could not be send at this time. Please try again later."
        alert.addButton(withTitle: "OK")
        alert.beginSheetModal(for: self.feedbackSheet,
                              completionHandler: nil)
    }

}
