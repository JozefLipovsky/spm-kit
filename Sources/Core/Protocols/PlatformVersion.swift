//
//  PlatformVersion.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2025-12-13.
//

import ArgumentParser

/// A type that defines version requirements for a specific platform.
package protocol PlatformVersion: Sendable, CaseIterable, CustomStringConvertible, ExpressibleByArgument {
    /// The minimum tools version required for the platform.
    var toolsVersion: Double { get }

    /// The string representation of the tools version (e.g., "5.9").
    var toolsVersionIdentifier: String { get }

    /// The version identifier for the platform (e.g., "v15").
    var versionIdentifier: String { get }

    /// The value of the build setting used to specify the deployment target version.
    var deploymentTargetSettingValue: String { get }

    /// The associated platform for this version.
    var platform: SupportedPlatform { get }
}

package extension PlatformVersion {
    /// The string representation of the tools version (e.g., "5.9").
    var toolsVersionIdentifier: String {
        String(format: "%.1f", toolsVersion)
    }
}
