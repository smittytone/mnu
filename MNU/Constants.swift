
/*
    Constants.swift
    MNU

    Created by Tony Smith on 5/07/2019.
    Copyright © 2019-20 Tony Smith. All rights reserved.

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


// Combine the app's various constants into a struct

struct MNU_CONSTANTS {

    struct ITEMS {

        struct SWITCH {
            static let UIMODE       = 0
            static let DESKTOP      = 1
            static let SHOW_HIDDEN  = 2
        }

        struct SCRIPT {
            static let GIT          = 10
            static let BREW_UPDATE  = 11
            static let BREW_UPGRADE = 12
            static let USER         = 20
        }
    }

    struct TYPES {
        static let SWITCH           = 0
        static let SCRIPT           = 1
        static let OPEN             = 2
    }

    struct BUILT_IN_TITLES {
        static let UIMODE           = "macOS Dark Mode"
        static let DESKTOP          = "Show Files on Desktop"
        static let SHOW_HIDDEN      = "Show Hidden Files"
        static let GIT              = "Update Git"
        static let BREW_UPDATE      = "Update Brew"
        static let BREW_UPGRADE     = "Upgrade Brew"
    }

    static let MENU_TEXT_LEN        = 30
    
    static let MENU_ESC_KEY         = 53
    static let MENU_ARR_KEY         = 124
    static let MENU_ARL_KEY         = 123
    
    static let MAX_ITEM_COUNT       = 25
}
