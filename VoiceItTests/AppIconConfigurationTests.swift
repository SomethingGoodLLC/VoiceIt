import XCTest
@testable import VoiceIt

final class AppIconConfigurationTests: XCTestCase {
    func testAlternateIconsRegisteredInInfoPlist() throws {
        let plistURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: "VoiceIt/Resources/Info.plist")

        let plistData = try Data(contentsOf: plistURL)
        let plist = try PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any]

        let bundleIcons = plist?["CFBundleIcons"] as? [String: Any]
        let alternateIcons = bundleIcons?["CFBundleAlternateIcons"] as? [String: Any]
        let registeredNames = Set(alternateIcons?.keys.map { $0 } ?? [])

        for iconName in AppIcon.registeredAlternateIconNames {
            XCTAssertTrue(
                registeredNames.contains(iconName),
                "Expected '\(iconName)' in CFBundleAlternateIcons but it was missing from Info.plist"
            )
        }
    }

    func testDecoyScreenTypesMapToRegisteredAlternateIcons() throws {
        let plistURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: "VoiceIt/Resources/Info.plist")

        let plistData = try Data(contentsOf: plistURL)
        let plist = try PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any]

        let bundleIcons = plist?["CFBundleIcons"] as? [String: Any]
        let alternateIcons = bundleIcons?["CFBundleAlternateIcons"] as? [String: Any]
        let registeredNames = Set(alternateIcons?.keys.map { $0 } ?? [])

        for decoy in DecoyScreenType.allCases {
            let appIcon = AppIcon.forDecoy(decoy)
            XCTAssertTrue(
                registeredNames.contains(appIcon.rawValue),
                "Decoy '\(decoy.rawValue)' maps to '\(appIcon.rawValue)' which is not registered in Info.plist"
            )
        }
    }

    func testVoiceChangerAndCrossStitchRegisteredInInfoPlist_regression() throws {
        let plistURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: "VoiceIt/Resources/Info.plist")

        let plistData = try Data(contentsOf: plistURL)
        let plist = try PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any]

        let bundleIcons = plist?["CFBundleIcons"] as? [String: Any]
        let alternateIcons = bundleIcons?["CFBundleAlternateIcons"] as? [String: Any]
        let registeredNames = Set(alternateIcons?.keys.map { $0 } ?? [])

        XCTAssertTrue(
            registeredNames.contains(AppIcon.voiceChanger.rawValue),
            "REGRESSION: VoiceChanger must be registered for stealth mode icon switching"
        )
        XCTAssertTrue(
            registeredNames.contains(AppIcon.crossStitch.rawValue),
            "REGRESSION: CrossStitch must be registered for default stealth decoy icon"
        )
    }
}
