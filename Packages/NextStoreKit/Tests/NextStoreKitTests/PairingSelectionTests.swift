import XCTest
@testable import NextStoreKit

final class PairingSelectionTests: XCTestCase {
    private let both: Set<PairingSelection.Kind> = [.lockdown, .rppairing]

    func testBothFilesNothingSetOnModernIOSChoosesRemotePairing() {
        XCTAssertEqual(
            PairingSelection.choose(preferred: nil, active: nil, available: both, supportsRemotePairing: true),
            .rppairing
        )
    }

    func testPreferredLockdownWinsEvenOnModernIOS() {
        XCTAssertEqual(
            PairingSelection.choose(preferred: .lockdown, active: nil, available: both, supportsRemotePairing: true),
            .lockdown
        )
    }

    func testPreferredMissingFileFallsBackToAvailable() {
        XCTAssertEqual(
            PairingSelection.choose(preferred: .lockdown, active: nil, available: [.rppairing], supportsRemotePairing: true),
            .rppairing
        )
    }

    func testOnlyRemotePairingOnOldIOSSelectsNothing() {
        XCTAssertNil(
            PairingSelection.choose(preferred: nil, active: nil, available: [.rppairing], supportsRemotePairing: false)
        )
    }

    func testOnlyLockdownOnModernIOSChoosesLockdown() {
        XCTAssertEqual(
            PairingSelection.choose(preferred: nil, active: nil, available: [.lockdown], supportsRemotePairing: true),
            .lockdown
        )
    }

    func testNothingAvailableSelectsNothing() {
        XCTAssertNil(
            PairingSelection.choose(preferred: .rppairing, active: .lockdown, available: [], supportsRemotePairing: true)
        )
    }

    func testActiveUsedWhenPreferredNil() {
        XCTAssertEqual(
            PairingSelection.choose(preferred: nil, active: .lockdown, available: both, supportsRemotePairing: true),
            .lockdown
        )
    }

    func testRawValuesMatchMinimuxerProtocols() {
        XCTAssertEqual(PairingSelection.Kind.lockdown.rawValue, "lockdown")
        XCTAssertEqual(PairingSelection.Kind.rppairing.rawValue, "rppairing")
    }
}
