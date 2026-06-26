//
//  VideoWallpaperUITestsLaunchTests.swift
//  VideoWallpaperUITests
//
//  Created by Rio Fujita on 2025/06/05.
//

import XCTest

final class VideoWallpaperUITestsLaunchTests: XCTestCase {
    private var runningApplication: XCUIApplication?

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        runningApplication?.terminate()
        runningApplication = nil
    }

    @MainActor
    func testLaunch() throws {
        let app = makeApplication()
        app.launch()

        // Insert steps here to perform after app launch but before taking a screenshot,
        // such as logging into a test account or navigating somewhere in the app

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func makeApplication() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["VIDEO_WALLPAPER_UI_TESTING"] = "1"
        runningApplication = app
        return app
    }
}
