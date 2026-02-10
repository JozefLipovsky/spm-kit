//
//  ProjectConfiguration.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2025-10-30.
//

import Foundation
import PathKit

/// Configuration for an Xcode project.
package struct ProjectConfiguration {
    /// The path to the `.xcodeproj` file.
    package let projectPath: Path

    /// The root path of the project directory.
    package let projectRootPath: Path

    /// The new name to apply to the project and related scheme references.
    package let newProjectName: String

    /// The platforms to keep and configure in the project.
    package let selectedPlatforms: [any PlatformVersion]

    /// The bundle identifier to apply to app targets.
    package let bundleIdentifier: String

    /// The name of the root module to link as a Swift Package dependency.
    package let rootModuleName: String

    /// Creates a new Xcode project configuration.
    /// - Parameters:
    ///   - projectPath: The path to the `.xcodeproj` file.
    ///   - projectRootPath: The root path of the project directory.
    ///   - newProjectName: The new name to apply to the project and related scheme references.
    ///   - selectedPlatforms: The platforms to keep and configure in the project.
    ///   - bundleIdentifier: The bundle identifier to apply to app targets.
    ///   - rootModuleName: The name of the root module to link as a Swift Package dependency.
    package init(
        projectPath: Path,
        projectRootPath: Path,
        newProjectName: String,
        selectedPlatforms: [any PlatformVersion],
        bundleIdentifier: String,
        rootModuleName: String
    ) {
        self.projectPath = projectPath
        self.projectRootPath = projectRootPath
        self.newProjectName = newProjectName
        self.selectedPlatforms = selectedPlatforms
        self.bundleIdentifier = bundleIdentifier
        self.rootModuleName = rootModuleName
    }
}

private extension ProjectConfiguration {
    var availableTargets: [ProjectDirectory] {
        [
            .app(.iOS()),
            .app(.macOS()),
            .app(.tvOS()),
            .app(.visionOS()),
            .app(.watchOS())
        ]
    }

    var availableApps: [ProjectDirectory.AppsDirectory] {
        [
            .iOS(.file("iOSApp", fileExtension: .swift)),
            .macOS(.file("macOSApp", fileExtension: .swift)),
            .tvOS(.file("tvOSApp", fileExtension: .swift)),
            .visionOS(.file("visionOSApp", fileExtension: .swift)),
            .watchOS(.file("watchOSApp", fileExtension: .swift))
        ]
    }

    var selectedPlatformIdentifiers: Set<String> {
        Set(selectedPlatforms.map(\.platform.identifier))
    }
}

package extension ProjectConfiguration {
    /// The selected targets based on the selected platforms.
    var selectedTargets: [ProjectDirectory] {
        availableTargets.filter { target in
            guard let targetPlatformIdentifier = target.pathSegments.last else {
                return false
            }

            return selectedPlatformIdentifiers.contains(targetPlatformIdentifier)
        }
    }

    /// The targets that should be deleted based on the selected platforms.
    var targetsToDelete: [ProjectDirectory] {
        availableTargets.filter { target in
            guard let platformIdentifier = target.pathSegments.last else {
                return false
            }

            return !selectedPlatformIdentifiers.contains(platformIdentifier)
        }
    }

    /// The absolute paths to the app template files for the selected platforms.
    var selectedTargetsAppTemplates: [Path] {
        availableApps.filter { app in
            !selectedPlatformIdentifiers.isDisjoint(with: app.pathSegments)
        }.map {
            projectRootPath + $0.pathString
        }
    }
}
