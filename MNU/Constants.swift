/*
    Constants.swift
    MNU

    Created by Tony Smith on 5/07/2019.
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
            static let SHOW_IP      = 13
            static let SHOW_DF      = 14
            static let USER         = 20
        }

        struct OPEN {
            static let GRAB_WINDOW  = 15
        }

        struct MISC {
            static let NO_ITEM      = -1
        }
    }

    struct BUILT_IN_TITLES {
        static let UIMODE           = "macOS Dark Mode"
        static let DESKTOP          = "Show Files on Desktop"
        static let SHOW_HIDDEN      = "Show Hidden Files"
        static let GIT              = "Update Git with Gitup"
        static let BREW_UPDATE      = "Update Homebrew"
        static let BREW_UPGRADE     = "Upgrade Homebrew"
        static let SHOW_IP          = "Show Mac IP address"
        static let SHOW_DF          = "Show free disk space"
        static let GRAB_WINDOW      = "Screengrab a window"
    }

    static let MENU_TEXT_LEN        = 128

    static let MENU_ESC_KEY         = 53
    static let MENU_ARR_KEY         = 124
    static let MENU_ARL_KEY         = 123
    static let MENU_COPY_KEY        = "c"
    static let MENU_CUT_KEY         = "x"
    static let MENU_PASTE_KEY       = "v"
    static let MENU_SELECT_ALL_KEY  = "a"
    static let MENU_UNDO_KEY        = "z"
    static let MENU_REDO_KEY        = "Z"

    static let MAX_ITEM_COUNT       = 30

    static let BASE_DEFAULT_COUNT   = 6

    // FROM 1.7.0
    static let MOD_KEY_SHIFT        = 0
    static let MOD_KEY_CMD          = 1
    static let MOD_KEY_OPT          = 2
    static let MOD_KEY_CTRL         = 3

    static let EDIT_CMD_COPY        = 0
    static let EDIT_CMD_CUT         = 1
    static let EDIT_CMD_PASTE       = 2
    static let EDIT_CMD_ALL         = 3
    static let EDIT_CMD_UNDO        = 4

    // THIS IS THE DEFINITIVE ICON ORDER
    static let DEFAULT_ICONS: [String] = [
        "generic", "bash", "z", "brew", "macports",
        "as", "python", "swift", "node", "code",
        "docker", "multipass", "emulation", "git", "ssh",
        "web", "cloud", "nas", "server", "mac",
        "cog", "sync", "power", "app", "x"
    ]

    // FROM 2.0.0
    struct TERMINAL {

        static let MACOS                        = 0
        static let ITERM                        = 1
        // FROM 2.4.0
        static let GHOSTTY                        = 2
    }

    struct SETTINGS_IDS {

        static let DEFAULT_ITEMS                = "com.bps.mnu.default-items"
        static let STORED_ITEMS                 = "com.bps.mnu.item-order"
        static let STARTUP_LAUNCH               = "com.bps.mnu.startup-launch"
        static let FIRST_RUN                    = "com.bps.mnu.first-run"
        static let NEW_TERM_TAB                 = "com.bps.mnu.new-term-tab"
        static let SHOW_MENU_IMAGES             = "com.bps.mnu.show-controls"
        static let TERMINAL                     = "com.bps.mnu.term-choice"
        static let AUTO_SEPARATE                = "com.bps.mnu.auto-separate-items"
        static let SHOW_DIRECT_OUTPUT           = "com.bps.mnu.show-direct-output"
        static let DEFINITIONS_1_6              = "com.bps.mnu.new-defs-1-6"
        static let IMAGE_CLEANUP                = "com.bps.mnu.image-cleanup"           // UNUSED
    }

    struct NOTIFICATION_IDS {

        static let UPDATE_LIST                  = "com.bps.mnu.list-updated"
        static let RESTORE_DEFAULTS             = "com.bps.mnu.restore-defaults"
        static let ICON_SELECTED                = "com.bps.mnu.select-image"
        static let ITEM_ADDED                   = "com.bps.mnu.item-added"
        static let AUTOSTART_ENABLED            = "com.bps.mnu.startup-enabled"
        static let AUTOSTART_DISABLED           = "com.bps.mnu.startup-disabled"
        static let CAN_QUIT                     = "com.bps.mnu.can-quit"
        static let SHOW_CONFIGURE               = "com.bps.mnu.show-configure"
        static let TERM_UPDATED                 = "com.bps.mnu.term-updated"
        static let TERM_TABBING_SET             = "com.bps.mnu.term-tab-updated"
        static let OUTPUT_UPDATED               = "com.bps.mnu.output-updated"
        static let CLEAN_ICONS                  = "com.bps.mnu.do-clean-icons"
    }

    struct MISC_IDS {

        static let APS_QUEUE                    = "com.bps.mnu.aps-queue"
        static let PROCESS_QUEUE                = "com.bps.mnu.process-q"
        static let PASTEBOARD                   = "com.bps.mnu.pb"
    }

    struct CONFIG_TABLE_CONTEXT_MENU {

        static let SHOW_HIDE                    = 0
        static let EDIT                         = 1
        static let DELETE                       = 2
        static let NEW                          = 3
        static let SEPARATOR                    = 4
    }

    static let DEFAULT_SYSTEM_FONT_SIZE         = 13.0

    // FROM 2.1.0
    static let TAHOE_ICON_SIZE                  = 16.0
    static let BIG_SUR_ICON_SIZE                = 20.0
    static let CONFIG_TABLE_ROW_HEIGHT          = 32.0
    static let CUSTOM_ICON_WIDTH                = 192.0     // Picon @3x width

    // FROM 2.2.0
    static let CONFIG_WINDOW_WIDTH              = 600.0
    struct CONFIG_TAB_PANEL_SIZE {

        static let MENU_LIST                    = NSSize(width: CONFIG_WINDOW_WIDTH, height: 500.0)
        static let MENU_LIST_MAX                = NSSize(width: CONFIG_WINDOW_WIDTH, height: 1500.0)
        static let SETTINGS                     = NSSize(width: CONFIG_WINDOW_WIDTH, height: 440.0)
        static let ABOUT                        = NSSize(width: CONFIG_WINDOW_WIDTH, height: 320.0)
    }

}
