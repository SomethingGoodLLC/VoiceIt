import XCTest
@testable import VoiceIt

@MainActor
final class StealthModeServiceTests: XCTestCase {
    func testNoArgActivationPreservesSelectedDecoy_regression() {
        let service = StealthModeService()
        service.setDecoyScreen(.voiceChanger)

        // Simulate a lifecycle/auto-hide activation (no decoy argument), as fired by
        // handleAppDidEnterBackground / checkAutoHide.
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

    func testWillResignActive_doesNotActivateStealth_regression() {
        let service = StealthModeService()
        service.isStealthActive = false

        service.handleAppWillResignActive()

        XCTAssertFalse(
            service.isStealthActive,
            "REGRESSION: transient inactive must not commit stealth lock"
        )
        XCTAssertTrue(
            service.isPrivacyShieldVisible,
            "Transient inactive should show privacy shield overlay"
        )
    }

    func testDidEnterBackground_activatesStealth() {
        let service = StealthModeService()
        service.isStealthActive = false

        service.handleAppDidEnterBackground()

        XCTAssertTrue(service.isStealthActive)
        XCTAssertFalse(service.isPrivacyShieldVisible)
    }

    func testDidBecomeActive_afterTransientInactive_clearsShieldWithoutLocking_regression() {
        let service = StealthModeService()
        service.isStealthActive = false

        service.handleAppWillResignActive()
        service.handleAppDidBecomeActive()

        XCTAssertFalse(
            service.isStealthActive,
            "REGRESSION: returning from transient inactive must stay unlocked"
        )
        XCTAssertFalse(service.isPrivacyShieldVisible)
    }

    func testDidBecomeActive_afterBackground_keepsStealthLocked() {
        let service = StealthModeService()
        service.isStealthActive = false

        service.handleAppWillResignActive()
        service.handleAppDidEnterBackground()
        service.handleAppDidBecomeActive()

        XCTAssertTrue(
            service.isStealthActive,
            "App must remain locked after true background"
        )
        XCTAssertFalse(service.isPrivacyShieldVisible)
    }

    func testDismissPrivacyShield_clearsOverlayWithoutUnlocking() {
        let service = StealthModeService()
        service.isStealthActive = false
        service.handleAppWillResignActive()

        service.dismissPrivacyShield()

        XCTAssertFalse(service.isPrivacyShieldVisible)
        XCTAssertFalse(service.isStealthActive)
    }

    func testQuickHideClearsPrivacyShield_regression() {
        let service = StealthModeService()
        service.isStealthActive = false
        service.handleAppWillResignActive()
        XCTAssertTrue(service.isPrivacyShieldVisible)

        service.quickHide()

        XCTAssertTrue(service.isStealthActive)
        XCTAssertFalse(
            service.isPrivacyShieldVisible,
            "REGRESSION: quick hide must commit stealth and clear transient shield"
        )
    }

    func testCompleteUnlock_clearsShieldAndTracking() {
        let service = StealthModeService()
        service.handleAppWillResignActive()
        service.handleAppDidEnterBackground()

        service.completeUnlock()

        XCTAssertFalse(service.isStealthActive)
        XCTAssertFalse(service.isPrivacyShieldVisible)
    }
}
