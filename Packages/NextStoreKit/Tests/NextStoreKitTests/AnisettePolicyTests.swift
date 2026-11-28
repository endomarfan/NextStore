import XCTest
@testable import NextStoreKit

final class AnisettePolicyTests: XCTestCase {
    private let sierra = "<MacBookPro13,3> <Mac OS X;10.12.6;16G29> <com.apple.AuthKit/1 (com.apple.akd/1.0)>"

    func testNormalizeReplacesMacOSPlatform() {
        let input = "<MacBookPro18,3> <macOS;26.6;25F84> <com.apple.AuthKit/1 (com.apple.akd/1.0)>"
        XCTAssertEqual(AnisettePolicy.normalizedClientInfo(input), AnisettePolicy.defaultClientInfo)
    }

    func testNormalizeReplacesXcodeBundle() {
        let input = "<MacBookPro18,3> <Mac OS X;26.6;25F84> <com.apple.AuthKit/1 (com.apple.dt.Xcode/3594.4.19)>"
        XCTAssertEqual(AnisettePolicy.normalizedClientInfo(input), AnisettePolicy.defaultClientInfo)
    }

    func testNormalizeKeepsGoodStringAndTrims() {
        XCTAssertEqual(AnisettePolicy.normalizedClientInfo(sierra), sierra)
        XCTAssertEqual(AnisettePolicy.normalizedClientInfo("  \(sierra)\n"), sierra)
    }

    func testIsBrokenClientInfo() {
        XCTAssertTrue(AnisettePolicy.isBrokenClientInfo(""))
        XCTAssertTrue(AnisettePolicy.isBrokenClientInfo("   "))
        XCTAssertTrue(AnisettePolicy.isBrokenClientInfo("<MacBookPro18,3> <macOS;26.6;25F84> <x>"))
        XCTAssertTrue(AnisettePolicy.isBrokenClientInfo("<MacBookPro18,3> <Mac OS X;26.6;25F84> <com.apple.AuthKit/1 (com.apple.dt.Xcode/1)>"))
        XCTAssertTrue(AnisettePolicy.isBrokenClientInfo("<Pixel> <Android;14;x> <x>"))
        XCTAssertTrue(AnisettePolicy.isBrokenClientInfo("<PC> <Windows;11;x> <x>"))
        XCTAssertFalse(AnisettePolicy.isBrokenClientInfo(sierra))
        XCTAssertFalse(AnisettePolicy.isBrokenClientInfo(AnisettePolicy.defaultClientInfo))
    }

    func testIsMacADIServer() {
        XCTAssertTrue(AnisettePolicy.isMacADIServer("https://MAC-ANI.jkcoxson.com/"))
        XCTAssertTrue(AnisettePolicy.isMacADIServer("https://ani.iloader.app"))
        XCTAssertFalse(AnisettePolicy.isMacADIServer("https://ani.sidestore.io"))
        XCTAssertFalse(AnisettePolicy.isMacADIServer("not a url"))
    }

    func testFailoverOrderPutsUnknownSelectedFirstAndDropsNonMac() {
        let selected = "https://my.own.server"
        let available = [
            "https://ani.sidestore.io",
            "https://ani.iloader.app",
            "https://android.example.com",
            "https://MAC-ANI.jkcoxson.com/",
        ]
        let order = AnisettePolicy.failoverOrder(selected: selected, available: available)
        XCTAssertEqual(order.first, selected)
        XCTAssertEqual(Array(order[1...2]), ["https://ani.iloader.app", "https://MAC-ANI.jkcoxson.com/"])
        XCTAssertFalse(order.contains("https://ani.sidestore.io"))
        XCTAssertFalse(order.contains("https://android.example.com"))
        XCTAssertEqual(order.count, 1 + AnisettePolicy.macADIServerURLs.count)
    }

    func testFailoverOrderHasNoDuplicates() {
        let selected = "https://mac-ani.jkcoxson.com/"
        let order = AnisettePolicy.failoverOrder(selected: selected, available: AnisettePolicy.macADIServerURLs + [selected])
        XCTAssertEqual(order.first, selected)
        XCTAssertEqual(order.count, AnisettePolicy.macADIServerURLs.count)
    }

    func testNeedsReprovisioning() {
        XCTAssertFalse(AnisettePolicy.needsReprovisioning(provisionedClientInfo: nil, currentClientInfo: sierra))
        XCTAssertFalse(AnisettePolicy.needsReprovisioning(
            provisionedClientInfo: "<MacBookPro18,3> <macOS;26.6;25F84> <com.apple.AuthKit/1 (com.apple.akd/1.0)>",
            currentClientInfo: AnisettePolicy.defaultClientInfo
        ))
        XCTAssertTrue(AnisettePolicy.needsReprovisioning(provisionedClientInfo: sierra, currentClientInfo: AnisettePolicy.defaultClientInfo))
    }

    func testMigrateLeavesWorkingOwnerSetupUntouched() {
        let settings = AnisettePolicy.Settings(
            useOnDeviceAnisette: false,
            serverURL: "https://mac-ani.jkcoxson.com",
            clientInfo: sierra,
            userAgent: "AuthKit/1 (Macintosh; OS X 10.12.6) (com.apple.akd/1.0)"
        )
        let migration = AnisettePolicy.migrate(settings)
        XCTAssertEqual(migration.settings, settings)
        XCTAssertFalse(migration.resetAdiBlob)
        XCTAssertTrue(migration.changes.isEmpty)
    }

    func testMigrateFreshDefaults() {
        let settings = AnisettePolicy.Settings(useOnDeviceAnisette: true, serverURL: "https://ani.sidestore.io", clientInfo: nil, userAgent: nil)
        let migration = AnisettePolicy.migrate(settings)
        XCTAssertFalse(migration.settings.useOnDeviceAnisette)
        XCTAssertEqual(migration.settings.serverURL, AnisettePolicy.defaultServerURL)
        XCTAssertNil(migration.settings.clientInfo)
        XCTAssertTrue(migration.resetAdiBlob)
        XCTAssertEqual(migration.changes.count, 3)
    }

    func testMigrateReplacesMacOSOverride() {
        let settings = AnisettePolicy.Settings(
            useOnDeviceAnisette: false,
            serverURL: "https://mac-ani.jkcoxson.com",
            clientInfo: "<MacBookPro18,3> <macOS;26.6;25F84> <com.apple.AuthKit/1 (com.apple.akd/1.0)>",
            userAgent: "AuthKit/1 (Macintosh; macOS 26.6) (com.apple.akd/1.0)"
        )
        let migration = AnisettePolicy.migrate(settings)
        XCTAssertEqual(migration.settings.clientInfo, AnisettePolicy.defaultClientInfo)
        XCTAssertEqual(migration.settings.userAgent, AnisettePolicy.defaultUserAgent)
        XCTAssertTrue(migration.resetAdiBlob)
    }

    func testMigrateReplacesAndroidOverrideWithMacServer() {
        let settings = AnisettePolicy.Settings(
            useOnDeviceAnisette: false,
            serverURL: "https://ani.iloader.app",
            clientInfo: "<Pixel> <Android;14;x> <x>",
            userAgent: "x"
        )
        let migration = AnisettePolicy.migrate(settings)
        XCTAssertEqual(migration.settings.clientInfo, AnisettePolicy.defaultClientInfo)
        XCTAssertEqual(migration.settings.serverURL, "https://ani.iloader.app")
        XCTAssertTrue(migration.resetAdiBlob)
    }

    func testSignInFailureClassification() {
        XCTAssertEqual(SignInFailure.classify(errorCode: -22410, rawPayload: nil), .deviceIdentityRejected)
        XCTAssertEqual(SignInFailure.classify(errorCode: -80046, rawPayload: nil), .anisetteServerRefused)
        XCTAssertEqual(SignInFailure.classify(errorCode: nil, rawPayload: "<html><h1>503 Service Unavailable</h1></html>"), .serviceRefused)
        XCTAssertNil(SignInFailure.classify(errorCode: -20101, rawPayload: nil))
        XCTAssertNil(SignInFailure.classify(errorCode: nil, rawPayload: "garbage"))
    }
}
