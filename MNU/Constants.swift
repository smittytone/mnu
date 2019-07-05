
//  Constants.swift
//  MNU
//
//  Created by Tony Smith on 05/07/2019.
//  Copyright © 2019 Tony Smith. All rights reserved.


import Foundation


struct MNU_CONSTANTS {

    struct ITEMS {

        struct SWITCH {
            static let UIMODE  = 0
            static let DESKTOP = 1
        }

        struct SCRIPT {
            static let GIT  = 20
            static let BREW = 21
        }
    }

    struct TYPES {
        static let SWITCH = 0
        static let SCRIPT = 1
    }

    struct BUILT_IN_TITLES {
        static let UIMODE = "macOS UI Mode"
        static let DESKTOP = "Show Files on Desktop"
        static let GIT = "Update Git"
        static let BREW = "Update Brew"
    }
}
