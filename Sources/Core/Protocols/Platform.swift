//
//  Platform.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2025-07-19.
//

import ArgumentParser

/// A type that defines build setting keys for supported platforms.
package protocol Platform: Sendable, CaseIterable, CustomStringConvertible, ExpressibleByArgument {
    /// The key of the build setting used to specify the display name.
    var displayNameSettingKey: String { get }

    /// The key of the build setting used to specify the bundle identifier.
    var bundleIdentifierSettingKey: String { get }
}

package extension Platform {
    /// The key of the build setting used to specify the display name.
    var displayNameSettingKey: String {
        "INFOPLIST_KEY_CFBundleDisplayName"
    }

    /// The key of the build setting used to specify the bundle identifier.
    var bundleIdentifierSettingKey: String {
        "PRODUCT_BUNDLE_IDENTIFIER"
    }
}
