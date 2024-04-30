//
//  MNUTests.swift
//  MNUTests
//
//  Created by Tony Smith on 21/07/2020.
//  Copyright © 2024 Tony Smith. All rights reserved.
//

import XCTest
import AppKit

@testable import MNU


class MNUTests: XCTestCase {


    // MARK: - AppDelegate Tests

    let appDelegate = NSApplication.shared.delegate as! AppDelegate
    let allowedOpenTime = 10.0


    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    /*
    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }
     */
    
    // MARK: Escaper Function Tests

    func testEscaper() throws {

        // Happy paths

        // Plain DQs: echo "$GIT"
        XCTAssert("echo \\\"$GIT\\\"" == self.appDelegate.escaper(#"echo "$GIT""#))
        // Escape tick in plain DQs: echo "You \`have `ls | wc -l` files in `pwd`"
        XCTAssert("echo \\\"You \\\\`have `ls | wc -l` files in `pwd`\\\"" == self.appDelegate.escaper(#"echo "You \`have `ls | wc -l` files in `pwd`""#))
        // Escape $ in plain DQs: echo "The value of \$HOME is $HOME"
        XCTAssert("echo \\\"The value of \\\\$HOME is $HOME\\\"" == self.appDelegate.escaper(#"echo "The value of \$HOME is $HOME""#))
        // escape DQs within SQs: echo '"GIT"'
        XCTAssert("echo \'\\\"$GIT\\\"\'" == self.appDelegate.escaper(#"echo '"$GIT"'"#))
        // escape DQs within DQs: echo "\"zz\""
        XCTAssert("echo \\\"\\\\\\\"zz\\\\\\\"\\\"" == self.appDelegate.escaper(#"echo "\"zz\"""#))
        // escape \s in grep regex
        XCTAssert("ifconfig | grep -Eo 'inet (addr:)?([0-9]*\\\\.){3}[0-9]*' | grep -Eo '([0-9]*\\\\.){3}[0-9]*' | grep -v '127.0.0.1'" == self.appDelegate.escaper(#"ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1'"#))
    }


    // MARK: Process Management Function Tests

    func testRunScriptDirect() throws {

        // Happy path
        _testRunScriptDirectHelper("/opt/homebrew/bin/python3 --version")

        // Correct app, bad argument -- should show dialog
        _testRunScriptDirectHelper("/opt/homebrew/bin/python3 --blast")

        // Misnamed app -- should show dialog
        _testRunScriptDirectHelper("/usr/bin/pdfmooker")

        // No app or args -- should show dialog
        _testRunScriptDirectHelper("")
        
        // FROM 1.6.0
        // Not escaped space -- should show dialog
        _testRunScriptDirectHelper("/usr/bin/open /Users/smitty/GitHub/mnu/MNUTests/Test Files/README.md")
        
        // Escaped space -- should open file
        _testRunScriptDirectHelper("/usr/bin/open /Users/smitty/GitHub/mnu/MNUTests/Test\\ Files/README.md")
        
        // Escaped spaces -- should open file
        _testRunScriptDirectHelper("/usr/bin/open /Users/smitty/GitHub/mnu/MNUTests/Test\\ Files/README.md -a visual\\ studio\\ code")
    }


    func _testRunScriptDirectHelper(_ codeSample: String) {

        let expectation = XCTestExpectation(description: "Script run")

        self.appDelegate.runScriptDirect(codeSample)

        let _ = Timer.scheduledTimer(withTimeInterval: allowedOpenTime, repeats: false) { (firedTimer) in
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: allowedOpenTime * 3)
    }


    func testRunScriptiTerm() throws {

        let codeSample = "cd \"$HOME\"; rm test.txt; echo TEST > test.txt"
        self.appDelegate.terminalIndex = 1
        self.appDelegate.runScript(codeSample)

        let expectation = XCTestExpectation(description: "Script run")

        let _ = Timer.scheduledTimer(withTimeInterval: allowedOpenTime, repeats: false) { (firedTimer) in
            let fm = FileManager.default
            let npath: NSString = "~/test.txt"
            XCTAssert(fm.fileExists(atPath: npath.expandingTildeInPath))
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: allowedOpenTime * 3)
    }
    
    
    func testRunScriptTerminal() throws {

        let codeSample = "cd \"$HOME\"; rm test.txt; echo TEST > test.txt"
        self.appDelegate.terminalIndex = 0
        self.appDelegate.runScript(codeSample)

        let expectation = XCTestExpectation(description: "Script run")

        let _ = Timer.scheduledTimer(withTimeInterval: allowedOpenTime, repeats: false) { (firedTimer) in
            let fm = FileManager.default
            let npath: NSString = "~/test.txt"
            XCTAssert(fm.fileExists(atPath: npath.expandingTildeInPath))
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: allowedOpenTime * 3)
    }

    
    func testtOpenApp() throws {

        // Should succeed
        _testtOpenAppHelper("Squinter", "com.bps.Squinter", 1)

        // Should succeed
        _testtOpenAppHelper("Firefox.app", "org.mozilla.firefox", 1)

        // Should fail
        _testtOpenAppHelper("Bollocks.app", "com.bollocks.bollocks", 0)
    }


    func _testtOpenAppHelper(_ appName: String, _ bundleID: String, _ expectedValue: Int) {

        let launchedApp = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)

        // Assert app not running
        XCTAssert(launchedApp.count == 0)

        let expectation = XCTestExpectation(description: "\(appName) opened")

        let _ = Timer.scheduledTimer(withTimeInterval: allowedOpenTime, repeats: false) { (firedTimer) in
            let launchedApp = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
            XCTAssert(launchedApp.count == expectedValue)
            expectation.fulfill()
        }

        self.appDelegate.openApp(appName);

        wait(for: [expectation], timeout: allowedOpenTime * 3)
    }


    // MARK: Pre-made MNU Item Maker Tests

    func testMakeModeSwitch() throws {

        let menuItem: MenuItem = self.appDelegate.makeModeSwitch()
        XCTAssert(menuItem.title == "macOS Dark Mode")
        XCTAssert(menuItem.code == 0)
        XCTAssert(menuItem.type == 0)
    }


    func testMakeDesktopSwitch() throws {

        let menuItem: MenuItem = self.appDelegate.makeDesktopSwitch()
        XCTAssert(menuItem.title == "Show Files on Desktop")
        XCTAssert(menuItem.code == 1)
        XCTAssert(menuItem.type == 0)
    }


    func testMakeHiddenFilesSwitch() throws {

        let menuItem: MenuItem = self.appDelegate.makeHiddenFilesSwitch()
        XCTAssert(menuItem.title == "Show Hidden Files")
        XCTAssert(menuItem.code == 2)
        XCTAssert(menuItem.type == 0)
    }


    func testMakeGitScript() throws {

        let menuItem: MenuItem = self.appDelegate.makeGitScript()
        XCTAssert(menuItem.title == "Update Git with Gitup")
        XCTAssert(menuItem.code == 10)
        XCTAssert(menuItem.type == 1)
    }

    func testMakeBrewDateScript() throws {

        let menuItem: MenuItem = self.appDelegate.makeBrewUpdateScript()
        XCTAssert(menuItem.title == "Update Homebrew")
        XCTAssert(menuItem.code == 11)
        XCTAssert(menuItem.type == 1)
    }

    func testMakeBrewUpgradeScript() throws {

        let menuItem: MenuItem = self.appDelegate.makeBrewUpgradeScript()
        XCTAssert(menuItem.title == "Upgrade Homebrew")
        XCTAssert(menuItem.code == 12)
        XCTAssert(menuItem.type == 1)
    }

    func testMakeShowIPScript() throws {

        let menuItem: MenuItem = self.appDelegate.makeShowIPScript()
        XCTAssert(menuItem.title == "Show Mac IP address")
        XCTAssert(menuItem.code == 13)
        XCTAssert(menuItem.type == 1)
    }
    
    func testMakeShowDiskFullScript() throws {

        let menuItem: MenuItem = self.appDelegate.makeShowDiskFullScript()
        XCTAssert(menuItem.title == "Show free disk space")
        XCTAssert(menuItem.code == 14)
        XCTAssert(menuItem.type == 1)
    }
    
    func testMakeGetScreenshotOpen() throws {

        let menuItem: MenuItem = self.appDelegate.makeGetScreenshotOpen()
        XCTAssert(menuItem.title == "Screengrab a window")
        XCTAssert(menuItem.code == 15)
        XCTAssert(menuItem.type == 2)
    }
    
    func testMakeIconMatrix() throws {

        let list = ["logo_generic", "logo_bash", "logo_brew", "logo_github", "logo_gitlab", "logo_python", "logo_node", "logo_java", "logo_lua", "logo_rust", "logo_perl", "logo_ruby", "logo_as", "logo_multipass", "logo_php", "logo_js", "logo_docker", "logo_doc", "logo_dir", "logo_app", "logo_cog", "logo_sync", "logo_power", "logo_mac", "logo_x"]

        let icons = self.appDelegate.icons
        icons.removeAllObjects()
        self.appDelegate.makeIconMatrix()
        XCTAssert(icons.count == list.count)
    }


    func testKillFinder() throws {

        let expectation = XCTestExpectation(description: "Finder killed")

        let _ = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { (firedTimer) in
            let launchedApp = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.Finder")
            XCTAssert(launchedApp.count == 0)
            expectation.fulfill()
        }

        self.appDelegate.killFinder(andDock: false)

        wait(for: [expectation], timeout: allowedOpenTime * 3)
    }


    // MARK: JSON Method Tests

    func testSerializerJsonize() throws {

        let item: MenuItem = MenuItem()
        // Impose static UUID
        item.uuid = "8222D482-B44B-4EB5-AD62-1D60D7EA8DBD"
        var result: String = Serializer.jsonize(item)
        print(result)
        // Update for 1.7.0 -- add extra members
        XCTAssert(result == #"{"code":-1,"direct":false,"hidden":false,"icon":0,"keyequivalent":"","keymodflags":0,"script":"","title":"","type":-1,"uuid":"8222D482-B44B-4EB5-AD62-1D60D7EA8DBD"}"#)

        item.script = "open \"test\";"
        result = Serializer.jsonize(item)
        print(result)
        // Update for 1.7.0 -- add extra members
        XCTAssert(result == #"{"code":-1,"direct":false,"hidden":false,"icon":0,"keyequivalent":"","keymodflags":0,"script":"open \"test\";","title":"","type":-1,"uuid":"8222D482-B44B-4EB5-AD62-1D60D7EA8DBD"}"#)
    }


    func testSerializerJsonizeAll() throws {

        let item: MenuItem = MenuItem()
        // Impose static UUID
        item.uuid = "8222D482-B44B-4EB5-AD62-1D60D7EA8DBD"
        let items: MenuItemList = MenuItemList()
        items.items.append(item)
        let result: String = Serializer.jsonizeAll(items)
        print("*** ",result)
        XCTAssert(result == #"{"data":[{"code":-1,"direct":false,"hidden":false,"icon":0,"keyequivalent":"","keymodflags":0,"script":"","title":"","type":-1,"uuid":"8222D482-B44B-4EB5-AD62-1D60D7EA8DBD"}]}"#)
    }


    func testSerializerDejsonize() throws {

        let jsonString: String = #"{"code":-1,"direct":false,"hidden":false,"icon":0,"script":"open \"test\";","title":"","type":-1,"uuid":"8222D482-B44B-4EB5-AD62-1D60D7EA8DBD"}"#
        let menuItem: MenuItem? = Serializer.dejsonize(jsonString)
        if let item: MenuItem = menuItem {
            XCTAssert(item.isHidden == false && item.iconIndex == 0 && item.code == -1 && item.isDirect == false && item.title == "" && item.type == -1 && item.script == "open \"test\";")
        } else {
            XCTAssertNotNil(menuItem)
        }
    }


    func testSerializerDejsonizeAll() throws {

        let jsonString: String = #"{"data":[{"code":-1,"direct":false,"hidden":false,"icon":0,"script":"","title":"","type":-1,"uuid":"8222D482-B44B-4EB5-AD62-1D60D7EA8DBD"}]}"#
        if let jsonData: Data = jsonString.data(using: String.Encoding.utf8) {
            let menuItems: MenuItemList? = Serializer.dejsonizeAll(jsonData)
            if let items: MenuItemList = menuItems {
                let item = items.items[0]
                XCTAssert(item.isHidden == false && item.iconIndex == 0 && item.code == -1 && item.isDirect == false && item.title == "" && item.type == -1 && item.script == "")
            } else {
                XCTAssertNotNil(menuItems)
            }
        }
    }

    
    func testGetAppPath() throws {
        
        var app: String = "Visual Studio Code"
        XCTAssertNotNil(appDelegate.getAppPath(app))
        XCTAssert(appDelegate.getAppPath(app)! == "/Applications/Visual Studio Code.app")
        
        app = "TextEdit"
        XCTAssertNotNil(appDelegate.getAppPath(app))
        XCTAssert(appDelegate.getAppPath(app)! == "/System/Applications/TextEdit.app")
        
        app = "Screenshot"
        XCTAssertNotNil(appDelegate.getAppPath(app))
        XCTAssert(appDelegate.getAppPath(app)! == "/System/Applications/Utilities/Screenshot.app")
        
        
    }

    // MARK: Misc Tests

    func testCheckScriptExists() throws {
        
        // Remove: this is dependent on Mac type and where (and if)
        //         brew is installed
        //var app: String = "/usr/local/bin/brew"
        //XCTAssertTrue(appDelegate.checkScriptExists(app, true))

        var app: String = "/usr/bin/git"
        XCTAssertTrue(appDelegate.checkScriptExists(app, true))

        app = "/usr/bin/madeupapp"
        XCTAssertFalse(appDelegate.checkScriptExists(app, true))
    }

    
    // MARK: - AddUserItemViewController Tests

    func testMakeAbsolutePath() throws {

        let aivc: AddUserItemViewController = AddUserItemViewController()
        var item: String = "/a/b/../c/d /x/y/z"
        var result: String = "/a/c/d /x/y/z"
        item = aivc.makeAbsolutePath(item)
        XCTAssert(item == result)

        item = "/a/b/../c/d /x/y/../z"
        result = "/a/c/d /x/z"
        item = aivc.makeAbsolutePath(item)
        XCTAssert(item == result)

        item = "/a/b/../c/d /x/y/../../z"
        result = "/a/c/d /z"
        item = aivc.makeAbsolutePath(item)
        XCTAssert(item == result)
    }


    func testCheckDirectCommand() throws {

        let aivc: AddUserItemViewController = AddUserItemViewController()
        // Path componentes ["~", "$", "*", "?", "!", "+", "@", "\"", "'", "{", "["]
        var item: String = "cat *.txt"
        var result: Bool = aivc.checkDirectCommand(item)
        XCTAssert(result)

        item = "echo $var"
        result = aivc.checkDirectCommand(item)
        XCTAssert(result)

        item = "echo \"Value: ${var}\""
        result = aivc.checkDirectCommand(item)
        XCTAssert(result)

        item = "$(dlist)"
        result = aivc.checkDirectCommand(item)
        XCTAssert(result)

        item = "cd ~/desktop"
        result = aivc.checkDirectCommand(item)
        XCTAssert(result)

        item = "echo 'This is a text \"string\"'"
        result = aivc.checkDirectCommand(item)
        XCTAssert(result)
    }

}
