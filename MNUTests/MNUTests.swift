//
//  MNUTests.swift
//  MNUTests
//
//  Created by Tony Smith on 21/07/2020.
//  Copyright © 2020 Tony Smith. All rights reserved.
//

import XCTest
import AppKit

@testable import MNU


class MNUTests: XCTestCase {


    let appDelegate = NSApplication.shared.delegate as! AppDelegate
    let allowedOpenTime = 10.0


    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }


    // MARK: Process Management Function Tests

    func testRunScriptDirect() throws {

        // Happy path
        _testRunScriptDirectHelper("/usr/local/bin/python3 --version")

        // Correct app, bad argument -- should show dialog
        _testRunScriptDirectHelper("/usr/local/bin/python3 --blast")

        // Misnamed app -- should show dialog
        _testRunScriptDirectHelper("/usr/local/bin/pdfmooker")

        // No app or args -- should show dialog
        _testRunScriptDirectHelper("")
    }


    func _testRunScriptDirectHelper(_ codeSample: String) {

        let expectation = XCTestExpectation(description: "Script run")

        self.appDelegate.runScriptDirect(codeSample)

        let _ = Timer.scheduledTimer(withTimeInterval: allowedOpenTime, repeats: false) { (firedTimer) in
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: allowedOpenTime * 3)
    }


    func testtOpenApp() throws {

        // Should succeed
        _testtOpenAppHelper("Squinter", "com.bps.Squinter", 1)

        // Should succeed
        _testtOpenAppHelper("OmniDiskSweeper.app", "com.omnigroup.OmniDiskSweeper", 1)

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
        XCTAssert(menuItem.title == "Update Git")
        XCTAssert(menuItem.code == 10)
        XCTAssert(menuItem.type == 1)
    }

    func testMakeBrewDateScript() throws {

        let menuItem: MenuItem = self.appDelegate.makeBrewUpdateScript()
        XCTAssert(menuItem.title == "Update Brew")
        XCTAssert(menuItem.code == 11)
        XCTAssert(menuItem.type == 1)
    }

    func testMakeBrewUpgradeScript() throws {

        let menuItem: MenuItem = self.appDelegate.makeBrewUpgradeScript()
        XCTAssert(menuItem.title == "Upgrade Brew")
        XCTAssert(menuItem.code == 12)
        XCTAssert(menuItem.type == 1)
    }
}
