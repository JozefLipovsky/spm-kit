//
//  SupportedPlatform.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2025-12-13.
//

import Foundation
import Noora

/// Supported Platforms
package enum SupportedPlatform: String, Platform {
    /// iPhone and iPad operating system
    case iOS
    /// Mac computers operating system
    case macOS
    /// Apple TV operating system
    case tvOS
    /// Vision Pro operating system
    case visionOS
    /// Apple Watch operating system
    case watchOS

    /// The identifier for the platform.
    package var identifier: String {
        rawValue
    }

    /// The key of the build setting used to specify the deployment target version.
    package var deploymentTargetSettingKey: String {
        switch self {
            case .iOS: return "IPHONEOS_DEPLOYMENT_TARGET"
            case .macOS: return "MACOSX_DEPLOYMENT_TARGET"
            case .tvOS: return "TVOS_DEPLOYMENT_TARGET"
            case .visionOS: return "XROS_DEPLOYMENT_TARGET"
            case .watchOS: return "WATCHOS_DEPLOYMENT_TARGET"
        }
    }

    /// CustomStringConvertible textual representation
    package var description: String {
        rawValue
    }

    /// The title displayed when prompting the user to select a version for this platform.
    package var versionSelectionPromptTitle: TerminalText {
        TerminalText(stringLiteral: "Minimum \(rawValue) deployment target")
    }

    /// The question displayed when asking the user to select a version for this platform.
    package var versionSelectionPromptQuestion: TerminalText {
        TerminalText(stringLiteral: "Which \(rawValue) version would you like to target?")
    }
}
