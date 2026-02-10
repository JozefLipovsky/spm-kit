//
//  PackageEditorClientTests.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2025-09-06.
//

import Core
import Dependencies
import PathKit
import TestHelpers
import Testing

@Suite("PackageEditorClient Tests", .tags(.integration))
struct PackageEditorClientTests {
    @Test("add - with valid manifest - inserts platforms argument")
    func add_withValidManifest_insertsPlatformsArgument() async throws {
        try await withDependencies {
            $0.packageEditorClient = .liveValue
        } operation: {
            // Given
            let tempPath = try Path.uniqueTemporary()
            defer { try? tempPath.delete() }

            let packagePath = tempPath + "Package.swift"
            try packagePath.write(#"let package = Package(name: "MyTestPackage")"#)

            @Dependency(\.packageEditorClient) var sut

            // When
            try await sut.add(platforms: [IOSVersion.v18, MacOSVersion.v15], toManifestAt: packagePath)

            // Then
            let updatedContent = try packagePath.read(.utf8)
            #expect(updatedContent.contains("platforms:"))
            #expect(updatedContent.contains(".iOS(.v18)"))
            #expect(updatedContent.contains(".macOS(.v15)"))
        }
    }

    @Test("add - when manifest does not exist - throws addPlatformsFailed error")
    func add_whenManifestDoesNotExist_throwsAddPlatformsFailedError() async throws {
        try await withDependencies {
            $0.packageEditorClient = .liveValue
        } operation: {
            // Given
            let tempPath = try Path.uniqueTemporary()
            defer { try? tempPath.delete() }

            let packagePath = tempPath + "Package.swift"

            @Dependency(\.packageEditorClient) var sut

            let error = await #expect(throws: PackageEditorClient.Error.self) {
                // When
                try await sut.add(platforms: [IOSVersion.v18], toManifestAt: packagePath)
            }

            // Then
            let errorDescription = try #require(error?.localizedDescription)
            #expect(errorDescription.contains("Adding package platforms failed"))
        }
    }
}

@Suite("PackageEditorClient.Error Tests", .tags(.unit))
struct PackageEditorClientErrorTests {
    @Test("errorDescription - with addPlatformsFailed - returns correctly formatted message")
    func errorDescription_withAddPlatformsFailed_returnsCorrectlyFormattedMessage() {
        // Given, When
        let sut = PackageEditorClient.Error.addPlatformsFailed(underlyingError: "File not found")

        // Then
        #expect(sut.errorDescription == "Adding package platforms failed: File not found")
    }
}
