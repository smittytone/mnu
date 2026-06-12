/*
    FeedbackEntities.swift
    MNU

    Created by Tony Smith on 12/06/2026.
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


public enum FeedbackErrorKind: Int, Error {

    case noError                                = 0
    case badResponse                            = 1
    case badStatusCode                          = 2
    case badSession                             = 3
    case badEncode                              = 4
    case badErrorUnknown                        = 5
}


public struct FeedbackError: Error, LocalizedError {

    public var code: FeedbackErrorKind                 = .noError
    public var text: String?                           = nil
    public var errorDescription: String? {
        switch self.code {
            case .noError:
                return nil
            case .badEncode:
                return "could not encode the feedback"
            case .badResponse:
                return "received a bad response from the feedback server"
            case .badStatusCode:
                if let text = self.text {
                    return "received a bad status code (\(text)) from the feedback server"
                } else {
                    return "received a bad status code from the feedback server"
                }
            case .badSession:
                return "could not connect to the feedback server"
            case .badErrorUnknown:
                return "unknown"
            }
        }
}


