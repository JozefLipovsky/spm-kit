//
//  PlatformOptions.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2025-07-20.
//

import ArgumentParser

/// A group of options for specifying platform versions.
package struct PlatformOptions: ParsableArguments {
    @Option(
        name: .customLong("iOS"),
        help: "Specify the iOS version. (e.g., v26)"
    )
    package var iOSVersion: IOSVersion?

    @Option(
        name: .customLong("macOS"),
        help: "Specify the macOS version. (e.g., v26)"
    )
    package var macOSVersion: MacOSVersion?

    @Option(
        name: .customLong("tvOS"),
        help: "Specify the tvOS version. (e.g., v26)"
    )
    package var tvOSVersion: TVOSVersion?

    @Option(
        name: .customLong("visionOS"),
        help: "Specify the visionOS version. (e.g., v26)"
    )
    package var visionOSVersion: VisionOSVersion?

    @Option(
        name: .customLong("watchOS"),
        help: "Specify the watchOS version. (e.g., v26)"
    )
    package var watchOSVersion: WatchOSVersion?

    package init() {}
}

package extension PlatformOptions {
    /// A collection of the selected platform versions.
    var selectedVersions: [any PlatformVersion] {
        let versions: [(any PlatformVersion)?] = [
            iOSVersion,
            macOSVersion,
            tvOSVersion,
            visionOSVersion,
            watchOSVersion
        ]

        return versions.compactMap { $0 }
    }
}
