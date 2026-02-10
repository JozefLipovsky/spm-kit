//
//  MacOSVersion.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2025-07-19.
//

import ArgumentParser

/// Supported macOS Versions
package enum MacOSVersion: String, PlatformVersion {
    /// First available in PackageDescription 5.9
    case v14

    /// First available in PackageDescription 6.0
    case v15

    /// First available in PackageDescription 6.2
    case v26

    /// The minimum tools version required for the platform.
    package var toolsVersion: Double {
        switch self {
            case .v14:
                return 5.9
            case .v15:
                return 6.0
            case .v26:
                return 6.2
        }
    }

    /// The version identifier for the platform version
    package var versionIdentifier: String {
        rawValue
    }

    /// The value of the build setting used to specify the deployment target version.
    package var deploymentTargetSettingValue: String {
        switch self {
            case .v14:
                return "14.0"
            case .v15:
                return "15.0"
            case .v26:
                return "26.0"
        }
    }

    /// The associated platform.
    package var platform: SupportedPlatform {
        .macOS
    }

    /// CustomStringConvertible textual representation
    package var description: String {
        rawValue
    }
}
