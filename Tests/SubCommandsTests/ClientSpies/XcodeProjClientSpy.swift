//
//  XcodeProjClientSpy.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2026-01-19.
//

import Core
import Dependencies
import Foundation

actor XcodeProjClientSpy {
    private(set) var projectReferenceUpdates: [ProjectReferenceUpdate]?
    private(set) var projectConfigurations: [Configuration]?

    func recordUpdateProjectReference(inWorkspace workspace: String, newProjectName: String) {
        let update = ProjectReferenceUpdate(workspacePath: workspace, newProjectName: newProjectName)
        if projectReferenceUpdates == nil {
            projectReferenceUpdates = [update]
        } else {
            projectReferenceUpdates?.append(update)
        }
    }

    func recordConfigureProject(
        projectPath: String,
        projectRootPath: String,
        newProjectName: String,
        selectedPlatforms: [any PlatformVersion],
        bundleIdentifier: String,
        rootModuleName: String
    ) {
        let recordedPlatforms = selectedPlatforms.map {
            Platform(platform: $0.platform, version: $0.versionIdentifier)
        }
        let recording = Configuration(
            projectPath: projectPath,
            projectRootPath: projectRootPath,
            newProjectName: newProjectName,
            selectedPlatforms: recordedPlatforms,
            bundleIdentifier: bundleIdentifier,
            rootModuleName: rootModuleName
        )

        if projectConfigurations == nil {
            projectConfigurations = [recording]
        } else {
            projectConfigurations?.append(recording)
        }
    }
}

extension XcodeProjClientSpy {
    struct ProjectReferenceUpdate {
        let workspacePath: String
        let newProjectName: String
    }

    struct Configuration {
        let projectPath: String
        let projectRootPath: String
        let newProjectName: String
        let selectedPlatforms: [Platform]
        let bundleIdentifier: String
        let rootModuleName: String
    }

    struct Platform: Equatable {
        let platform: SupportedPlatform
        let version: String
    }
}
