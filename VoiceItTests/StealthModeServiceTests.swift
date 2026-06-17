import XCTest
@testable import VoiceIt

@MainActor
final class StealthModeServiceTests: XCTestCase {
    func testNoArgActivationPreservesSelectedDecoy_regression() {
        let service = StealthModeService()
        service.setDecoyScreen(.voiceChanger)

        // Simulate a lifecycle/auto-hide activation (no decoy argument), as fired by
        // handleAppWillResignActive / handleAppDidBecomeActive / checkAutoHide.
        service.activateStealthMode()

        XCTAssertEqual(
            service.decoyScreen,
            .voiceChanger,
            "REGRESSION: backgrounding/auto-hide must not reset the decoy to Calculator"
        )
        XCTAssertTrue(service.isStealthActive)
    }

    func testExplicitDecoyOverridesSelection() {
        let service = StealthModeService()
        service.setDecoyScreen(.voiceChanger)

        service.activateStealthMode(decoy: .notes)

        XCTAssertEqual(service.decoyScreen, .notes)
        XCTAssertTrue(service.isStealthActive)
    }

    func testServiceLaunchesLocked() {
        let service = StealthModeService()

        XCTAssertTrue(
            service.isStealthActive,
            "Service must launch locked so the disguised decoy is shown on the first frame"
        )
    }

    func testQuickHidePreservesSelectedDecoy() {
        let service = StealthModeService()
        service.setDecoyScreen(.weather)

        service.quickHide()

        XCTAssertEqual(service.decoyScreen, .weather)
        XCTAssertTrue(service.isStealthActive)
    }
}
