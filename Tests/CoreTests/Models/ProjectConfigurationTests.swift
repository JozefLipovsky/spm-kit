//
//  ProjectConfigurationTests.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2025-11-02.
//

import Core
import PathKit
import TestHelpers
import Testing

@Suite("ProjectConfiguration Tests", .tags(.unit))
struct ProjectConfigurationTests {
    @Test("Initialization - with single platform - creates configuration correctly")
    func testInitialization_withSinglePlatform_createsConfigurationCorrectly() {
        // Given, When
        let sut = ProjectConfiguration(
            projectPath: Path("/fake/path/to/project/Project.xcodeproj"),
            projectRootPath: Path("/fake/path/to/project"),
            newProjectName: "TestProject",
            selectedPlatforms: [IOSVersion.v26],
            bundleIdentifier: "com.example.TestProject",
            rootModuleName: "RootModule"
        )

        // Then
        #expect(sut.projectPath == Path("/fake/path/to/project/Project.xcodeproj"))
        #expect(sut.projectRootPath == Path("/fake/path/to/project"))
        #expect(sut.newProjectName == "TestProject")
        #expect(sut.selectedPlatforms.count == 1)
        #expect(sut.bundleIdentifier == "com.example.TestProject")
        #expect(sut.rootModuleName == "RootModule")
    }

    @Test("Initialization - with multiple platforms - creates configuration correctly")
    func testInitialization_withMultiplePlatforms_createsConfigurationCorrectly() {
        // Given, When
        let sut = ProjectConfiguration(
            projectPath: Path("/fake/path/to/project/Project.xcodeproj"),
            projectRootPath: Path("/fake/path/to/project"),
            newProjectName: "TestProject",
            selectedPlatforms: [IOSVersion.v26, MacOSVersion.v15, TVOSVersion.v18],
            bundleIdentifier: "com.example.TestProject",
            rootModuleName: "RootModule"
        )

        // Then
        #expect(sut.projectPath == Path("/fake/path/to/project/Project.xcodeproj"))
        #expect(sut.projectRootPath == Path("/fake/path/to/project"))
        #expect(sut.newProjectName == "TestProject")
        #expect(sut.selectedPlatforms.count == 3)
        #expect(sut.bundleIdentifier == "com.example.TestProject")
        #expect(sut.rootModuleName == "RootModule")
    }

    @Test("Initialization - with all platforms - creates configuration correctly")
    func testInitialization_withAllPlatforms_createsConfigurationCorrectly() {
        // Given, When
        let sut = ProjectConfiguration(
            projectPath: Path("/fake/path/to/project/Project.xcodeproj"),
            projectRootPath: Path("/fake/path/to/project"),
            newProjectName: "TestProject",
            selectedPlatforms: [
                IOSVersion.v26,
                MacOSVersion.v15,
                TVOSVersion.v18,
                WatchOSVersion.v11,
                VisionOSVersion.v2
            ],
            bundleIdentifier: "com.example.TestProject",
            rootModuleName: "RootModule"
        )

        // Then
        #expect(sut.projectPath == Path("/fake/path/to/project/Project.xcodeproj"))
        #expect(sut.projectRootPath == Path("/fake/path/to/project"))
        #expect(sut.newProjectName == "TestProject")
        #expect(sut.selectedPlatforms.count == 5)
        #expect(sut.bundleIdentifier == "com.example.TestProject")
        #expect(sut.rootModuleName == "RootModule")
    }

    @Test("selectedTargets - with single platform - returns single platform target")
    func testSelectedTargets_withSinglePlatform_returnsSinglePlatformTarget() {
        // Given
        let sut = ProjectConfiguration(
            projectPath: Path("/fake/path/to/project/Project.xcodeproj"),
            projectRootPath: Path("/fake/path/to/project"),
            newProjectName: "TestProject",
            selectedPlatforms: [IOSVersion.v26],
            bundleIdentifier: "com.example.TestProject",
            rootModuleName: "RootModule"
        )

        // When
        let selectedTargets = sut.selectedTargets

        // Then
        #expect(selectedTargets.count == 1)
        #expect(selectedTargets == [.app(.iOS())])
    }

    @Test("selectedTargets - with multiple platforms - returns only selected platform targets")
    func testSelectedTargets_withMultiplePlatforms_returnsOnlySelectedPlatformTargets() {
        // Given
        let sut = ProjectConfiguration(
            projectPath: Path("/fake/path/to/project/Project.xcodeproj"),
            projectRootPath: Path("/fake/path/to/project"),
            newProjectName: "TestProject",
            selectedPlatforms: [IOSVersion.v26, MacOSVersion.v15, TVOSVersion.v18],
            bundleIdentifier: "com.example.TestProject",
            rootModuleName: "RootModule"
        )

        // When
        let selectedTargets = sut.selectedTargets

        // Then
        #expect(selectedTargets.count == 3)
        #expect(selectedTargets == [.app(.iOS()), .app(.macOS()), .app(.tvOS())])
    }

    @Test("selectedTargets - with all platforms - returns all platform targets")
    func testSelectedTargets_withAllPlatforms_returnsAllPlatformTargets() {
        // Given
        let sut = ProjectConfiguration(
            projectPath: Path("/fake/path/to/project/Project.xcodeproj"),
            projectRootPath: Path("/fake/path/to/project"),
            newProjectName: "TestProject",
            selectedPlatforms: [
                IOSVersion.v26,
                MacOSVersion.v15,
                TVOSVersion.v18,
                WatchOSVersion.v11,
                VisionOSVersion.v2
            ],
            bundleIdentifier: "com.example.TestProject",
            rootModuleName: "RootModule"
        )

        // When
        let selectedTargets = sut.selectedTargets

        // Then
        #expect(selectedTargets.count == 5)
        #expect(selectedTargets == [.app(.iOS()), .app(.macOS()), .app(.tvOS()), .app(.visionOS()), .app(.watchOS())])
    }

    @Test("targetsToDelete - with single platform - returns all unselected platform targets")
    func testTargetsToDelete_withSinglePlatform_returnsAllUnselectedPlatformTargets() {
        // Given
        let sut = ProjectConfiguration(
            projectPath: Path("/fake/path/to/project/Project.xcodeproj"),
            projectRootPath: Path("/fake/path/to/project"),
            newProjectName: "TestProject",
            selectedPlatforms: [MacOSVersion.v15],
            bundleIdentifier: "com.example.TestProject",
            rootModuleName: "RootModule"
        )

        // When
        let targetsToDelete = sut.targetsToDelete

        // Then
        #expect(targetsToDelete.count == 4)
        #expect(targetsToDelete == [.app(.iOS()), .app(.tvOS()), .app(.visionOS()), .app(.watchOS())])
    }

    @Test("targetsToDelete - with multiple platforms - returns all unselected platform targets")
    func testTargetsToDelete_withMultiplePlatforms_returnsAllUnselectedPlatformTargets() {
        // Given
        let sut = ProjectConfiguration(
            projectPath: Path("/fake/path/to/project/Project.xcodeproj"),
            projectRootPath: Path("/fake/path/to/project"),
            newProjectName: "TestProject",
            selectedPlatforms: [TVOSVersion.v18, MacOSVersion.v15],
            bundleIdentifier: "com.example.TestProject",
            rootModuleName: "RootModule"
        )

        // When
        let targetsToDelete = sut.targetsToDelete

        // Then
        #expect(targetsToDelete.count == 3)
        #expect(targetsToDelete == [.app(.iOS()), .app(.visionOS()), .app(.watchOS())])
    }

    @Test("targetsToDelete - with all platforms - returns empty array")
    func testTargetsToDelete_withAllPlatforms_returnsEmptyArray() {
        // Given
        let projectPath = Path("/fake/path/to/project/Project.xcodeproj")
        let projectRootPath = Path("/fake/path/to/project")
        let allPlatforms: [any PlatformVersion] = [
            IOSVersion.v26,
            MacOSVersion.v15,
            TVOSVersion.v18,
            WatchOSVersion.v11,
            VisionOSVersion.v2
        ]

        let sut = ProjectConfiguration(
            projectPath: projectPath,
            projectRootPath: projectRootPath,
            newProjectName: "TestProject",
            selectedPlatforms: allPlatforms,
            bundleIdentifier: "com.example.TestProject",
            rootModuleName: "RootModule"
        )

        // When
        let targetsToDelete = sut.targetsToDelete

        // Then
        #expect(targetsToDelete.isEmpty)
    }

    @Test("selectedTargetsAppTemplates - with single platform - returns only selected platform app template")
    func testSelectedTargetsAppTemplates_withSinglePlatform_returnsOnlySelectedPlatformAppTemplate() {
        // Given
        let sut = ProjectConfiguration(
            projectPath: Path("/fake/path/to/project/Project.xcodeproj"),
            projectRootPath: Path("/fake/path/to/project"),
            newProjectName: "TestProject",
            selectedPlatforms: [IOSVersion.v26],
            bundleIdentifier: "com.example.TestProject",
            rootModuleName: "RootModule"
        )

        // When
        let selectedAppTemplates = sut.selectedTargetsAppTemplates

        // Then
        #expect(selectedAppTemplates.count == 1)
        #expect(selectedAppTemplates == [Path("/fake/path/to/project/iOS/iOSApp.swift")])
    }

    @Test("selectedTargetsAppTemplates - with multiple platforms - returns selected platform app templates")
    func testSelectedTargetsAppTemplates_withMultiplePlatforms_returnsSelectedPlatformAppTemplates() {
        // Given
        let sut = ProjectConfiguration(
            projectPath: Path("/fake/path/to/project/Project.xcodeproj"),
            projectRootPath: Path("/fake/path/to/project"),
            newProjectName: "TestProject",
            selectedPlatforms: [IOSVersion.v26, MacOSVersion.v15, TVOSVersion.v18],
            bundleIdentifier: "com.example.TestProject",
            rootModuleName: "RootModule"
        )

        // When
        let selectedAppTemplates = sut.selectedTargetsAppTemplates

        // Then
        let expectedTemplates = [
            Path("/fake/path/to/project/iOS/iOSApp.swift"),
            Path("/fake/path/to/project/macOS/macOSApp.swift"),
            Path("/fake/path/to/project/tvOS/tvOSApp.swift")
        ]
        #expect(selectedAppTemplates.count == 3)
        #expect(selectedAppTemplates == expectedTemplates)
    }

    @Test("selectedTargetsAppTemplates - with all platforms - returns all selected platform app templates")
    func testSelectedTargetsAppTemplates_withAllPlatforms_returnsAllSelectedPlatformAppTemplates() {
        // Given
        let sut = ProjectConfiguration(
            projectPath: Path("/fake/path/to/project/Project.xcodeproj"),
            projectRootPath: Path("/fake/path/to/project"),
            newProjectName: "TestProject",
            selectedPlatforms: [
                IOSVersion.v26,
                MacOSVersion.v15,
                TVOSVersion.v18,
                WatchOSVersion.v11,
                VisionOSVersion.v2
            ],
            bundleIdentifier: "com.example.TestProject",
            rootModuleName: "RootModule"
        )

        // When
        let selectedAppTemplates = sut.selectedTargetsAppTemplates

        // Then
        let expectedTemplates = [
            Path("/fake/path/to/project/iOS/iOSApp.swift"),
            Path("/fake/path/to/project/macOS/macOSApp.swift"),
            Path("/fake/path/to/project/tvOS/tvOSApp.swift"),
            Path("/fake/path/to/project/visionOS/visionOSApp.swift"),
            Path("/fake/path/to/project/watchOS/watchOSApp.swift")
        ]
        #expect(selectedAppTemplates.count == 5)
        #expect(selectedAppTemplates == expectedTemplates)
    }
}
