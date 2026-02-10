//
//  ProjectDirectoryTests.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2025-09-20.
//

import Core
import TestHelpers
import Testing

@Suite("ProjectDirectory Tests", .tags(.unit))
struct ProjectDirectoryTests {
    @Test("pathSegments - with root - returns empty segments")
    func pathSegments_withRoot_returnsEmptySegments() {
        // Given
        let directory = ProjectDirectory.root()

        // When
        let sut = directory.pathSegments

        // Then
        #expect(sut.isEmpty)
    }

    @Test("pathSegments - with root containing a file - returns file segments")
    func pathSegments_withRootContainingFile_returnsFileSegments() {
        // Given
        let directory = ProjectDirectory.root(.file("App", fileExtension: .xcworkspace))

        // When
        let sut = directory.pathSegments

        // Then
        #expect(sut == ["App.xcworkspace"])
    }

    @Test("pathSegments - with app directory - returns app segment")
    func pathSegments_withAppDirectory_returnsAppSegment() {
        // Given
        let directory = ProjectDirectory.app()

        // When
        let sut = directory.pathSegments

        // Then
        #expect(sut == ["App"])
    }

    @Test("pathSegments - appTarget with file - returns correct segments")
    func pathSegments_appTargetWithFile_returnsCorrectSegments() {
        // Given
        let directory = ProjectDirectory.app(.iOS(.file("iOSApp", fileExtension: .swift)))

        // When
        let sut = directory.pathSegments

        // Then
        #expect(sut == ["App", "iOS", "iOSApp.swift"])
    }

    @Test("pathSegments - appTarget with nil file - returns correct segments")
    func pathSegments_appTargetWithNilFile_returnsCorrectSegments() {
        // Given
        let directory = ProjectDirectory.app(.tvOS(nil))

        // When
        let sut = directory.pathSegments

        // Then
        #expect(sut == ["App", "tvOS"])
    }

    @Test("pathSegments - with modules directory - returns modules segment")
    func pathSegments_withModulesDirectory_returnsModulesSegment() {
        // Given
        let directory = ProjectDirectory.modules()

        // When
        let sut = directory.pathSegments

        // Then
        #expect(sut == ["Modules"])
    }

    @Test("pathSegments - with modules package manifest - returns manifest segment")
    func pathSegments_withModulesPackageManifest_returnsManifestSegments() {
        // Given
        let directory = ProjectDirectory.modules(.packageManifest)

        // When
        let sut = directory.pathSegments

        // Then
        #expect(sut == ["Modules", "Package.swift"])
    }

    @Test("pathSegments - with modules sources - returns source segments")
    func pathSegments_withModulesSources_returnsSourceSegments() {
        // Given
        let directory = ProjectDirectory.modules(
            .sources(.module("MyFeature", file: .file("MyFeature", fileExtension: .swift)))
        )

        // When
        let sut = directory.pathSegments

        // Then
        #expect(sut == ["Modules", "Sources", "MyFeature", "MyFeature.swift"])
    }

    @Test("pathSegments - with modules tests - returns test segments")
    func pathSegments_withModulesTests_returnsTestSegments() {
        // Given
        let directory = ProjectDirectory.modules(
            .tests(.module("MyFeatureTests", file: .file("MyFeatureTests", fileExtension: .swift)))
        )

        // When
        let sut = directory.pathSegments

        // Then
        #expect(sut == ["Modules", "Tests", "MyFeatureTests", "MyFeatureTests.swift"])
    }

    @Test("renamingBase() - when renaming file - returns correct project directory")
    func renamingBase_whenRenamingFile_returnsCorrectProjectDirectory() {
        // Given
        let directory = ProjectDirectory.modules(
            .sources(.module("TestFeature", file: .file("TestFeatureView", fileExtension: .swift)))
        )

        // When
        let sut = directory.renamingBase(to: "CustomView")

        // Then
        #expect(sut == .modules(.sources(.module("TestFeature", file: .file("CustomView", fileExtension: .swift)))))
    }

    @Test("renamingBase() - when renaming directory - returns correct project directory")
    func renamingBase_whenRenamingDirectory_returnsCorrectProjectDirectory() {
        // Given, When
        let directory = ProjectDirectory.modules(.sources(.module("TestFeature")))

        // When
        let sut = directory.renamingBase(to: "TestService")

        // Then
        #expect(sut == .modules(.sources(.module("TestService"))))
    }
}
