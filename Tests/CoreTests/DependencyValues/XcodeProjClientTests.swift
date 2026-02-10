//
//  XcodeProjClientTests.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2025-09-28.
//

import Core
import Dependencies
import Foundation
import PathKit
import TestHelpers
import Testing
import XcodeProj

// swiftlint:disable function_body_length type_body_length
@Suite("XcodeProjClient Tests", .tags(.integration))
struct XcodeProjClientTests {
    @Test("updateProjectReference() - with valid workspace - updates file reference")
    func updateProjectReference_withValidWorkspace_updatesFileRef() async throws {
        try await withDependencies {
            $0.xcodeProjClient = .liveValue
        } operation: {
            // Given
            let tempPath = try Path.uniqueTemporary()
            defer { try? tempPath.delete() }

            let workspaceStubPath = try copyFixtureToTempPath(
                resourceName: "ValidWorkspace",
                resourceExtension: "xcworkspace",
                tempPath: tempPath
            )

            @Dependency(\.xcodeProjClient) var sut

            // When
            let newProjectName = "NewProjectName"
            try await sut.updateProjectReference(inWorkspace: workspaceStubPath, newProjectName: newProjectName)

            // Then
            let updatedWorkspace = try XCWorkspace(path: workspaceStubPath)
            let projectFileRef = updatedWorkspace.data.children.first { child in
                guard case .file(let fileRef) = child else { return false }
                return Path(fileRef.location.path).extension == "xcodeproj"
            }

            let path = try #require(projectFileRef?.location.path)
            #expect(path.contains(newProjectName))
        }
    }

    @Test("updateProjectReference() - with invalid path - throws error")
    func updateProjectReference_withInvalidPath_throwsError() async throws {
        try await withDependencies {
            $0.xcodeProjClient = .liveValue
        } operation: {
            // Given
            @Dependency(\.xcodeProjClient) var sut
            let invalidPath = Path("/fake/path/invalid.xcworkspace")
            let newProjectName = "NewProjectName"

            let error = await #expect(throws: XcodeProjClient.Error.self) {
                // When
                try await sut.updateProjectReference(inWorkspace: invalidPath, newProjectName: newProjectName)
            }

            // Then
            let errorDescription = try #require(error?.localizedDescription)
            #expect(errorDescription.contains("Workspace configuration failed"))
        }
    }

    @Test("updateProjectReference() - when workspace write fails - throws error")
    func updateProjectReference_whenProjectWriteFails_throwsError() async throws {
        try await withDependencies {
            $0.xcodeProjClient = .liveValue
        } operation: {
            // Given
            let tempPath = try Path.uniqueTemporary()
            defer { try? tempPath.delete() }

            let workspaceStubPath = try copyFixtureToTempPath(
                resourceName: "ValidWorkspace",
                resourceExtension: "xcworkspace",
                tempPath: tempPath
            )

            // Set read-only permission to prevent Workspace update write
            try FileManager.default.setAttributes([.posixPermissions: 0o555], ofItemAtPath: workspaceStubPath.string)

            @Dependency(\.xcodeProjClient) var sut

            let error = await #expect(throws: XcodeProjClient.Error.self) {
                // When
                try await sut.updateProjectReference(inWorkspace: workspaceStubPath, newProjectName: "NewName")
            }

            // Then
            let errorDescription = try #require(error?.localizedDescription)
            #expect(errorDescription.contains("Workspace configuration failed"))
        }
    }

    @Test("configureProject() - with multi-platform targets - configures selected targets and links root module")
    func configureProject_withMultiPlatformTargets_configuresSelectedTargetsAndLinksRootModule() async throws {
        try await withDependencies {
            $0.xcodeProjClient = .liveValue
        } operation: {
            // Given
            let tempPath = try Path.uniqueTemporary()
            defer { try? tempPath.delete() }

            let stubPath = try copyFixtureToTempPath(resourceName: "ValidProject", tempPath: tempPath)

            @Dependency(\.xcodeProjClient) var sut

            let projectDirectory = ProjectDirectory.app(.root(.file("App", fileExtension: .xcodeproj)))
            let projectPath = stubPath + projectDirectory.pathString
            let projectRootPath = stubPath + ProjectDirectory.app().pathString
            let templateProj = try XcodeProj(path: projectPath)

            let configuration = ProjectConfiguration(
                projectPath: projectPath,
                projectRootPath: projectRootPath,
                newProjectName: "TestProject",
                selectedPlatforms: [IOSVersion.v18, VisionOSVersion.v26],
                bundleIdentifier: "com.testTeam.TestProject",
                rootModuleName: "TestRootFeature"
            )

            // When
            try await sut.configureProject(configuration)

            // Then
            let updatedXcodeProj = try XcodeProj(path: projectPath)

            let configuredTargets = templateProj.targets(includeding: ["iOS", "visionOS"])
            let deletedTargets = templateProj.targets(excluding: ["iOS", "visionOS"])

            let configuredSchemes = templateProj.schemes(includeding: ["iOS", "visionOS"])
            let deletedSchemes = templateProj.schemes(excluding: ["iOS", "visionOS"])

            let deletedTargetItems = deletedTargets.map { $0.propertyIdentifiers() }.flatMap { $0 }

            let deletedTargetDirectories = deletedTargets.directories(with: projectRootPath)
            let configuredTargetDirectories = configuredTargets.directories(with: projectRootPath)

            // Remove unwanted targets
            updatedXcodeProj.pbxproj.forEach { projectObject in
                #expect(!deletedTargetItems.contains(projectObject.uuid))
            }

            updatedXcodeProj.pbxproj.rootObject?.targets.forEach { projectTarget in
                #expect(!deletedTargets.contains(where: { $0.uuid == projectTarget.uuid }))
                #expect(configuredTargets.contains(where: { $0.uuid == projectTarget.uuid }))
            }

            updatedXcodeProj.sharedData?.schemes.forEach { projectScheme in
                #expect(!deletedSchemes.contains(where: { $0.name == projectScheme.name }))
                #expect(configuredSchemes.contains(where: { $0.name == projectScheme.name }))
            }

            // Remove unwanted directories
            try projectRootPath.children().forEach { projectPath in
                guard projectPath.extension != "xcodeproj", !projectPath.lastComponent.hasPrefix(".") else {
                    return
                }

                #expect(!deletedTargetDirectories.contains(projectPath))
                #expect(configuredTargetDirectories.contains(projectPath))
            }

            // Configure selected targets
            try updatedXcodeProj.pbxproj.rootObject?.targets.forEach { target in
                let buildPhaseFiles = try target.frameworksBuildPhase()?.files
                let buildPhaseFilesProdNames = buildPhaseFiles?.compactMap { $0.product?.productName }
                #expect(buildPhaseFilesProdNames?.contains("TestRootFeature") ?? false)

                switch target.name {
                    case "iOS":
                        let targetSettingKey = IOSVersion.v18.platform.deploymentTargetSettingKey
                        let displayNameKey = IOSVersion.v18.platform.displayNameSettingKey
                        let bundleIDKey = IOSVersion.v18.platform.bundleIdentifierSettingKey
                        target.buildConfigurationList?.buildConfigurations.forEach { configuration in
                            #expect(configuration.buildSettings[targetSettingKey] == .string("18.0"))
                            #expect(configuration.buildSettings[displayNameKey] == .string("TestProject"))
                            #expect(configuration.buildSettings[bundleIDKey] == .string("com.testTeam.TestProject"))
                        }
                    case "visionOS":
                        let targetSettingKey = VisionOSVersion.v26.platform.deploymentTargetSettingKey
                        let displayNameKey = VisionOSVersion.v26.platform.displayNameSettingKey
                        let bundleIDKey = VisionOSVersion.v26.platform.bundleIdentifierSettingKey
                        target.buildConfigurationList?.buildConfigurations.forEach { configuration in
                            #expect(configuration.buildSettings[targetSettingKey] == .string("26.0"))
                            #expect(configuration.buildSettings[displayNameKey] == .string("TestProject"))
                            #expect(configuration.buildSettings[bundleIDKey] == .string("com.testTeam.TestProject"))
                        }
                    default:
                        Issue.record("Unexpected target found: \(target.name)")
                }
            }

            updatedXcodeProj.sharedData?.schemes.forEach { scheme in
                scheme.buildAction?.buildActionEntries.forEach { buildAction in
                    let buildActionRef = buildAction.buildableReference.referencedContainer
                    #expect(buildActionRef == "container:TestProject.xcodeproj")
                }

                let launchActionRef = scheme.launchAction?.runnable?.buildableReference?.referencedContainer
                let profileActionRef = scheme.profileAction?.runnable?.buildableReference?.referencedContainer
                #expect(launchActionRef == "container:TestProject.xcodeproj")
                #expect(profileActionRef == "container:TestProject.xcodeproj")
            }

            updatedXcodeProj.pbxproj.forEach { projectObject in
                if let package = projectObject as? XCSwiftPackageProductDependency {
                    let productName = package.productName
                    #expect(productName == "TestRootFeature")
                }
            }

            updatedXcodeProj.pbxproj.buildFiles.forEach { buildFile in
                let buildFileProductName = buildFile.product?.productName
                #expect(buildFileProductName == "TestRootFeature")
            }

            updatedXcodeProj.pbxproj.frameworksBuildPhases.flatMap { $0.files ?? [] }.forEach { frameworkBuildFile in
                let buildFileProductName = frameworkBuildFile.product?.productName
                #expect(buildFileProductName == "TestRootFeature")
            }
        }
    }

    @Test("configureProject() - with invalid project path - throws error")
    func configureProject_withInvalidProjectPath_throwsError() async throws {
        try await withDependencies {
            $0.xcodeProjClient = .liveValue
        } operation: {
            // Given
            @Dependency(\.xcodeProjClient) var sut

            let configuration = ProjectConfiguration(
                projectPath: Path("/fake/path/project/app/invalid.xcodeproj"),
                projectRootPath: Path("/fake/path/project/"),
                newProjectName: "TestProject",
                selectedPlatforms: [IOSVersion.v18],
                bundleIdentifier: "com.testTeam.TestProject",
                rootModuleName: "TestRootFeature"
            )

            let error = await #expect(throws: XcodeProjClient.Error.self) {
                // When
                try await sut.configureProject(configuration)
            }

            // Then
            let errorDescription = try #require(error?.localizedDescription)
            #expect(errorDescription.contains("Project configuration failed"))
        }
    }

    @Test("configureProject() - when target to delete not found - throws error")
    func configureProject_whenTargetToDeleteNotFound_throwsError() async throws {
        try await withDependencies {
            $0.xcodeProjClient = .liveValue
        } operation: {
            // Given
            let tempPath = try Path.uniqueTemporary()
            defer { try? tempPath.delete() }

            // InvalidProject does not contain a tvOS target.
            let projectStubPath = try copyFixtureToTempPath(resourceName: "InvalidProject", tempPath: tempPath)

            let projectDirectory = ProjectDirectory.app(.root(.file("App", fileExtension: .xcodeproj)))
            let projectPath = projectStubPath + projectDirectory.pathString
            let projectRootPath = projectStubPath + ProjectDirectory.app().pathString

            // Select a non-missing platform to simulate failure when deleting the missing tvOS target
            let configuration = ProjectConfiguration(
                projectPath: projectPath,
                projectRootPath: projectRootPath,
                newProjectName: "TestProject",
                selectedPlatforms: [MacOSVersion.v26],
                bundleIdentifier: "com.testTeam.TestProject",
                rootModuleName: "TestRootFeature"
            )

            @Dependency(\.xcodeProjClient) var sut

            let error = await #expect(throws: XcodeProjClient.Error.self) {
                // When
                try await sut.configureProject(configuration)
            }

            // Then
            let errorDescription = try #require(error?.localizedDescription)
            #expect(errorDescription.contains("Project configuration failed: Target to delete not found"))
        }
    }

    @Test("configureProject() - when target directory removal failed - throws error")
    func configureProject_whenTargetDirectoryRemovalFailed_throwsError() async throws {
        try await withDependencies {
            $0.xcodeProjClient = .liveValue
        } operation: {
            // Given
            let tempPath = try Path.uniqueTemporary()
            defer { try? tempPath.delete() }

            let projectStubPath = try copyFixtureToTempPath(resourceName: "ValidProject", tempPath: tempPath)

            let projectDirectory = ProjectDirectory.app(.root(.file("App", fileExtension: .xcodeproj)))
            let projectPath = projectStubPath + projectDirectory.pathString
            let projectRootPath = projectStubPath + ProjectDirectory.app().pathString

            let configuration = ProjectConfiguration(
                projectPath: projectPath,
                projectRootPath: projectRootPath,
                newProjectName: "TestProject",
                selectedPlatforms: [MacOSVersion.v26],
                bundleIdentifier: "com.testTeam.TestProject",
                rootModuleName: "TestRootFeature"
            )

            // Set read-only permission on targets parent directory to prevent target directory removal
            try FileManager.default.setAttributes([.posixPermissions: 0o555], ofItemAtPath: projectRootPath.string)

            @Dependency(\.xcodeProjClient) var sut

            let error = await #expect(throws: XcodeProjClient.Error.self) {
                // When
                try await sut.configureProject(configuration)
            }

            // Then
            let errorDescription = try #require(error?.localizedDescription)
            #expect(errorDescription.contains("Project configuration failed: Application targets removal failed"))
        }
    }

    @Test("configureProject() - when project write fails - throws error")
    func configureProject_whenProjectWriteFails_throwsError() async throws {
        try await withDependencies {
            $0.xcodeProjClient = .liveValue
        } operation: {
            // Given
            let tempPath = try Path.uniqueTemporary()
            defer { try? tempPath.delete() }

            let projectStubPath = try copyFixtureToTempPath(resourceName: "ValidProject", tempPath: tempPath)

            let projectDirectory = ProjectDirectory.app(.root(.file("App", fileExtension: .xcodeproj)))
            let projectPath = projectStubPath + projectDirectory.pathString
            let projectRootPath = projectStubPath + ProjectDirectory.app().pathString

            let configuration = ProjectConfiguration(
                projectPath: projectPath,
                projectRootPath: projectRootPath,
                newProjectName: "TestProject",
                selectedPlatforms: [MacOSVersion.v26],
                bundleIdentifier: "com.testTeam.TestProject",
                rootModuleName: "TestRootFeature"
            )

            // Set read-only permission on project directory path to prevent XcodeProj write
            try FileManager.default.setAttributes([.posixPermissions: 0o555], ofItemAtPath: projectPath.string)

            @Dependency(\.xcodeProjClient) var sut

            let error = await #expect(throws: XcodeProjClient.Error.self) {
                // When
                try await sut.configureProject(configuration)
            }

            // Then
            let errorDescription = try #require(error?.localizedDescription)
            #expect(errorDescription.contains("Project configuration failed"))
        }
    }

    @Test("configureProject() - when target to configure not found - throws error")
    func configureProject_whenTargetToConfigureNotFound_throwsError() async throws {
        try await withDependencies {
            $0.xcodeProjClient = .liveValue
        } operation: {
            // Given
            let tempPath = try Path.uniqueTemporary()
            defer { try? tempPath.delete() }

            // InvalidProject does not contain a tvOS target.
            let projectStubPath = try copyFixtureToTempPath(resourceName: "InvalidProject", tempPath: tempPath)

            let projectDirectory = ProjectDirectory.app(.root(.file("App", fileExtension: .xcodeproj)))
            let projectPath = projectStubPath + projectDirectory.pathString
            let projectRootPath = projectStubPath + ProjectDirectory.app().pathString

            // Select a missing platform to simulate failure when configuring the missing tvOS target
            let configuration = ProjectConfiguration(
                projectPath: projectPath,
                projectRootPath: projectRootPath,
                newProjectName: "TestProject",
                selectedPlatforms: [TVOSVersion.v26],
                bundleIdentifier: "com.testTeam.TestProject",
                rootModuleName: "TestRootFeature"
            )

            @Dependency(\.xcodeProjClient) var sut

            let error = await #expect(throws: XcodeProjClient.Error.self) {
                // When
                try await sut.configureProject(configuration)
            }

            // Then
            let errorDescription = try #require(error?.localizedDescription)
            #expect(errorDescription.contains("Project configuration failed: Selected target not found"))
        }
    }
}

@Suite("XcodeProjClient.Error Tests", .tags(.unit))
struct XcodeProjClientErrorTests {
    @Test("errorDescription - with workspace updated failed - returns correct message")
    func errorDescription_withWorkspaceUpdateFailed_returnsCorrectMessage() {
        // Given
        let errorMessage = "Stub error"
        let error = XcodeProjClient.Error.workspaceUpdateFailed(underlyingError: errorMessage)

        // When
        let sut = error.errorDescription

        // Then
        #expect(sut == "Workspace configuration failed: " + errorMessage)
    }

    @Test("errorDescription - with app targets removal failed - returns correct message")
    func errorDescription_withAppTargetsRemovalFailed_returnsCorrectMessage() {
        // Given
        let errorMessage = "Stub error"
        let error = XcodeProjClient.Error.appTargetsRemovalFailed(underlyingError: errorMessage)

        // When
        let sut = error.errorDescription

        // Then
        #expect(sut == "Application targets removal failed: " + errorMessage)
    }

    @Test("errorDescription - with build phase configuration failed - returns correct message")
    func errorDescription_withBuildPhaseConfigurationFailed_returnsCorrectMessage() {
        // Given
        let errorMessage = "Stub error"
        let error = XcodeProjClient.Error.buildPhaseConfigurationFailed(underlyingError: errorMessage)

        // When
        let sut = error.errorDescription

        // Then
        #expect(sut == "Frameworks build phase configuration failed: " + errorMessage)
    }

    @Test("errorDescription - with project configuration failed - returns correct message")
    func errorDescription_withProjectConfigurationFailed_returnsCorrectMessage() {
        // Given
        let errorMessage = "Stub error"
        let error = XcodeProjClient.Error.projectConfigurationFailed(underlyingError: errorMessage)

        // When
        let sut = error.errorDescription

        // Then
        #expect(sut == "Project configuration failed: " + errorMessage)
    }

    @Test("errorDescription - with target to delete not found - returns correct message")
    func errorDescription_withTargetToDeleteNotFound_returnsCorrectMessage() {
        // Given
        let targetName = "StubTarget"
        let error = XcodeProjClient.Error.targetToDeleteNotFound(targetName: targetName)

        // When
        let sut = error.errorDescription

        // Then
        #expect(sut == "Target to delete not found: " + targetName)
    }

    @Test("errorDescription - with selected target not found - returns correct message")
    func errorDescription_withSelectedTargetNotFound_returnsCorrectMessage() {
        // Given
        let targetName = "StubTarget"
        let error = XcodeProjClient.Error.selectedTargetNotFound(targetName: targetName)

        // When
        let sut = error.errorDescription

        // Then
        #expect(sut == "Selected target not found: " + targetName)
    }
}

private extension XcodeProjClientTests {
    func copyFixtureToTempPath(resourceName: String, resourceExtension: String? = nil, tempPath: Path) throws -> Path {
        let url = try #require(
            Bundle.module.url(
                forResource: resourceName,
                withExtension: resourceExtension,
                subdirectory: "_Fixtures/XcodeProjClientTests"
            )
        )

        let resourcePath = Path(url.path)
        let destinationPath = tempPath + resourcePath.lastComponent
        try resourcePath.copy(destinationPath)
        return destinationPath
    }
}

private extension XcodeProj {
    func targets(includeding targetNames: [String]) -> [PBXTarget] {
        pbxproj.nativeTargets.filter { targetNames.contains($0.name) }
    }

    func targets(excluding targetNames: [String]) -> [PBXTarget] {
        pbxproj.nativeTargets.filter { !targetNames.contains($0.name) }
    }

    func schemes(includeding targetNames: [String]) -> [XCScheme] {
        sharedData?.schemes.filter { targetNames.contains($0.name) } ?? []
    }

    func schemes(excluding targetNames: [String]) -> [XCScheme] {
        sharedData?.schemes.filter { !targetNames.contains($0.name) } ?? []
    }
}

private extension Array where Element == PBXTarget {
    func directories(with projectRootPath: Path) -> Set<Path> {
        let directories = map { projectRootPath + $0.name }
        return Set(directories)
    }
}
// swiftlint:enable function_body_length type_body_length
