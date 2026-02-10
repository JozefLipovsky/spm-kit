//
//  TemplateTypeTests.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2025-11-22.
//

import Core
import TestHelpers
import Testing

@Suite("TemplateType Tests", .tags(.unit))
struct TemplateTypeTests {
    @Test("resource - for rootModuleView - returns correct resource name")
    func resource_forRootModuleView_returnsCorrectResourceName() {
        // Given, When
        let sut = TemplateType.rootModuleView

        // Then
        #expect(sut.resource == "RootModuleView")
    }

    @Test("resource - for xcodeProject - returns correct resource name")
    func resource_forXcodeProject_returnsCorrectResourceName() {
        // Given, When
        let sut = TemplateType.xcodeProject

        // Then
        #expect(sut.resource == "XcodeProject")
    }

    @Test("resource - for spmKitConfig - returns correct resource name")
    func resource_forSpmKitConfig_returnsCorrectResourceName() {
        // Given, When
        let sut = TemplateType.spmKitConfig

        // Then
        #expect(sut.resource == "spm-kit-config")
    }

    @Test("resource - for swiftFormatConfig - returns correct resource name")
    func resource_forSwiftFormatConfig_returnsCorrectResourceName() {
        // Given, When
        let sut = TemplateType.swiftFormatConfig

        // Then
        #expect(sut.resource == ".swift-format")
    }

    @Test("resourceExtension - for rootModuleView - returns correct file extension")
    func resourceExtension_forRootModuleView_returnsCorrectFileExtension() {
        // Given, When
        let sut = TemplateType.rootModuleView

        // Then
        #expect(sut.resourceExtension == "swift")
    }

    @Test("resourceExtension - for spmKitConfig - returns correct file extension")
    func resourceExtension_forSpmKitConfig_returnsCorrectFileExtension() {
        // Given, When
        let sut = TemplateType.spmKitConfig

        // Then
        #expect(sut.resourceExtension == "yaml")
    }

    @Test("resourceExtension - for xcodeProject - returns nil as extension")
    func resourceExtension_forXcodeProject_returnsNilAsExtension() {
        // Given, When
        let sut = TemplateType.xcodeProject

        // Then
        #expect(sut.resourceExtension == nil)
    }

    @Test("resourceExtension - for swiftFormatConfig - returns nil as extension")
    func resourceExtension_forSwiftFormatConfig_returnsNilAsExtension() {
        // Given, When
        let sut = TemplateType.swiftFormatConfig

        // Then
        #expect(sut.resourceExtension == nil)
    }

    @Test("subdirectory - for rootModuleView - returns correct subdirectory")
    func subdirectory_forRootModuleView_returnsCorrectSubdirectory() {
        // Given, When
        let sut = TemplateType.rootModuleView

        // Then
        #expect(sut.subdirectory == "_Templates/Bootstrap")
    }

    @Test("subdirectory - for xcodeProject - returns correct subdirectory")
    func subdirectory_forXcodeProject_returnsCorrectSubdirectory() {
        // Given, When
        let sut = TemplateType.xcodeProject

        // Then
        #expect(sut.subdirectory == "_Templates/Bootstrap")
    }

    @Test("subdirectory - for spmKitConfig - returns correct subdirectory")
    func subdirectory_forSpmKitConfig_returnsCorrectSubdirectory() {
        // Given, When
        let sut = TemplateType.spmKitConfig

        // Then
        #expect(sut.subdirectory == "_Templates/Bootstrap")
    }

    @Test("subdirectory - for swiftFormatConfig - returns correct subdirectory")
    func subdirectory_forSwiftFormatConfig_returnsCorrectSubdirectory() {
        // Given, When
        let sut = TemplateType.swiftFormatConfig

        // Then
        #expect(sut.subdirectory == "_Templates/Bootstrap")
    }
}
