import XCTest
@testable import NextStoreKit

final class PairingSelectionTests: XCTestCase {
    private let both: Set<PairingSelection.Kind> = [.lockdown, .rppairing]

    func testBothFilesNothingSetOnModernIOSChoosesRemotePairing() {
        XCTAssertEqual(
            PairingSelection.choose(preferred: nil, available: both, supportsRemotePairing: true),
            .rppairing
        )
    }

    func testPreferredLockdownWinsEvenOnModernIOS() {
        XCTAssertEqual(
            PairingSelection.choose(preferred: .lockdown, available: both, supportsRemotePairing: true),
            .lockdown
        )
    }

    func testPreferredMissingFileFallsBackToAvailable() {
        XCTAssertEqual(
            PairingSelection.choose(preferred: .lockdown, available: [.rppairing], supportsRemotePairing: true),
            .rppairing
        )
    }

    func testOnlyRemotePairingOnOldIOSSelectsNothing() {
        XCTAssertNil(
            PairingSelection.choose(preferred: nil, available: [.rppairing], supportsRemotePairing: false)
        )
    }

    func testOnlyLockdownOnModernIOSChoosesLockdown() {
        XCTAssertEqual(
            PairingSelection.choose(preferred: nil, available: [.lockdown], supportsRemotePairing: true),
            .lockdown
        )
    }

    func testNothingAvailableSelectsNothing() {
        XCTAssertNil(
            PairingSelection.choose(preferred: .rppairing, available: [], supportsRemotePairing: true)
        )
    }

    func testBothFilesNothingPreferredOnIOS16ChoosesLockdown() {
        XCTAssertEqual(
            PairingSelection.choose(preferred: nil, available: both, supportsRemotePairing: false),
            .lockdown
        )
    }

    func testRecommended() {
        XCTAssertEqual(PairingSelection.recommended(supportsRemotePairing: true), .rppairing)
        XCTAssertEqual(PairingSelection.recommended(supportsRemotePairing: false), .lockdown)
    }

    func testNeedsConfirmationWarning() {
        XCTAssertTrue(PairingSelection.needsConfirmationWarning(for: .lockdown, supportsRemotePairing: true))
        XCTAssertFalse(PairingSelection.needsConfirmationWarning(for: .rppairing, supportsRemotePairing: true))
        XCTAssertTrue(PairingSelection.needsConfirmationWarning(for: .rppairing, supportsRemotePairing: false))
        XCTAssertFalse(PairingSelection.needsConfirmationWarning(for: .lockdown, supportsRemotePairing: false))
    }

    func testRawValuesMatchMinimuxerProtocols() {
        XCTAssertEqual(PairingSelection.Kind.lockdown.rawValue, "lockdown")
        XCTAssertEqual(PairingSelection.Kind.rppairing.rawValue, "rppairing")
    }
}
