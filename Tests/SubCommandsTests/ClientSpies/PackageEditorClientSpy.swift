//
//  PackageEditorClientSpy.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2026-01-19.
//

import Core
import Dependencies

actor PackageEditorClientSpy {
    private(set) var addedPlatforms: [Platform]?

    func recordAdd(platforms: [any PlatformVersion], toManifestAt path: String) {
        let platforms = platforms.map { Platform(platform: $0.platform, version: $0.versionIdentifier, path: path) }

        if addedPlatforms == nil {
            addedPlatforms = platforms
        } else {
            addedPlatforms?.append(contentsOf: platforms)
        }
    }
}

extension PackageEditorClientSpy {
    struct Platform {
        let platform: SupportedPlatform
        let version: String
        let path: String
    }
}
