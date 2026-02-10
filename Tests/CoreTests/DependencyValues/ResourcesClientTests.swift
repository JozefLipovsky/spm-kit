//
//  ResourcesClientTests.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2025-09-06.
//

import Core
import Dependencies
import Foundation
import PathKit
import TestHelpers
import Testing

@Suite("ResourcesClient Tests", .tags(.integration))
struct ResourcesClientTests {
    @Test("templateItem - for rootModuleView - returns rootModuleView template")
    func templateItem_forRootModuleView_returnsRootModuleViewTemplate() async throws {
        try await withDependencies {
            $0.resourcesClient = .liveValue
        } operation: {
            // Given
            @Dependency(\.resourcesClient) var sut

            // When
            let templateItem = try await sut.templateItem(type: .rootModuleView)

            // Then
            #expect(templateItem.copyFlags.isEmpty)

            let path = Path(templateItem.pathString)
            #expect(path.exists)
            #expect(path.isFile)
            #expect(path.lastComponent == "RootModuleView.swift")
        }
    }

    @Test("templateItem - for xcodeProject - returns xcodeProject template")
    func templateItem_forXcodeProject_returnsXcodeProjectTemplate() async throws {
        try await withDependencies {
            $0.resourcesClient = .liveValue
        } operation: {
            // Given
            @Dependency(\.resourcesClient) var sut

            // When
            let templateItem = try await sut.templateItem(type: .xcodeProject)

            // Then
            #expect(templateItem.copyFlags == ["-R"])

            let path = Path(templateItem.pathString)
            #expect(path.exists)
            #expect(path.isDirectory)
            #expect(path.lastComponent == "XcodeProject")
        }
    }

    @Test("templateItem - for spmKitConfig - returns spmKitConfig template")
    func templateItem_forSpmKitConfig_returnsSpmKitConfigTemplate() async throws {
        try await withDependencies {
            $0.resourcesClient = .liveValue
        } operation: {
            // Given
            @Dependency(\.resourcesClient) var sut

            // When
            let templateItem = try await sut.templateItem(type: .spmKitConfig)

            // Then
            #expect(templateItem.copyFlags.isEmpty)

            let path = Path(templateItem.pathString)
            #expect(path.exists)
            #expect(path.isFile)
            #expect(path.lastComponent == "spm-kit-config.yaml")
        }
    }

    @Test("templateItem - for swiftFormatConfig - returns swiftFormatConfig template")
    func templateItem_forSwiftFormatConfig_returnsSwiftFormatConfigTemplate() async throws {
        try await withDependencies {
            $0.resourcesClient = .liveValue
        } operation: {
            // Given
            @Dependency(\.resourcesClient) var sut

            // When
            let templateItem = try await sut.templateItem(type: .swiftFormatConfig)

            // Then
            #expect(templateItem.copyFlags.isEmpty)

            let path = Path(templateItem.pathString)
            #expect(path.exists)
            #expect(path.isFile)
            #expect(path.lastComponent == ".swift-format")
        }
    }

    @Test("templateItem - when resource is not found - throws ResourcesError")
    func templateItem_whenResourceIsNotFound_throwsResourcesError() async throws {
        await withDependencies {
            $0.resourcesClient = .liveValue
            $0.bundle = Bundle(for: Bundle.self)    // Simulate bundle lookup failure
        } operation: {
            // Given
            @Dependency(\.resourcesClient) var sut

            let error = await #expect(throws: ResourcesClient.Error.self) {
                // When
                _ = try await sut.templateItem(type: .xcodeProject)
            }

            // Then
            #expect(error == ResourcesClient.Error.projectTemplateNotFound)
        }
    }
}

@Suite("ResourcesClient.Error Tests", .tags(.unit))
struct ResourcesClientErrorTests {
    @Test("errorDescription - with projectTemplateNotFound - returns correct message")
    func errorDescription_withProjectTemplateNotFound_returnsCorrectMessage() {
        // Given, When
        let sut = ResourcesClient.Error.projectTemplateNotFound

        // Then
        #expect(sut.errorDescription == "The Xcode project template could not be found in the application's bundle.")
    }

    @Test("errorDescription - with rootModuleTemplateNotFound - returns correct message")
    func errorDescription_withRootModuleTemplateNotFound_returnsCorrectMessage() {
        // Given, When
        let sut = ResourcesClient.Error.rootModuleTemplateNotFound

        // Then
        #expect(sut.errorDescription == "The root module template could not be found in the application's bundle.")
    }

    @Test("errorDescription - with spmKitConfigTemplateNotFound - returns correct message")
    func errorDescription_withSpmKitConfigTemplateNotFound_returnsCorrectMessage() {
        // Given, When
        let sut = ResourcesClient.Error.spmKitConfigTemplateNotFound

        // Then
        #expect(sut.errorDescription == "The SPM Kit config template could not be found in the application's bundle.")
    }

    @Test("errorDescription - with swiftFormatConfigNotFound - returns correct message")
    func errorDescription_withSwiftFormatConfigNotFound_returnsCorrectMessage() {
        // Given, When
        let sut = ResourcesClient.Error.swiftFormatConfigNotFound

        // Then
        #expect(
            sut.errorDescription == "The Swift format config template could not be found in the application's bundle."
        )
    }
}
