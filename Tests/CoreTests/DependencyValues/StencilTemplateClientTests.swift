//
//  StencilTemplateClientTests.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2025-09-06.
//

import Core
import Dependencies
import PathKit
import TestHelpers
import Testing

@Suite("StencilTemplateClient Tests", .tags(.integration))
struct StencilTemplateClientTests {

    @Test("processRootModuleTemplate - with valid template - updates file content")
    func processRootModuleTemplate_withValidTemplate_updatesFileContent() async throws {
        try await withDependencies {
            $0.stencilTemplateClient = .liveValue
        } operation: {
            // Given
            let tempPath = try Path.uniqueTemporary()
            let pathStub = tempPath + "Test.swift"
            try pathStub.write(
                #"{{ moduleName }}View { String("{{ projectName }} {{ moduleName }}") }"#,
                encoding: .utf8
            )

            defer {
                try? pathStub.delete()
                try? tempPath.delete()
            }

            @Dependency(\.stencilTemplateClient) var sut

            // When
            try await sut.processRootModuleTemplate(
                atPath: pathStub,
                projectName: "MyAwesomeProject",
                moduleName: "RootModule"
            )

            // Then
            let updatedTemplate = try pathStub.read(.utf8)
            let expectedTemplate = #"RootModuleView { String("MyAwesomeProject RootModule") }"#
            #expect(updatedTemplate == expectedTemplate)
        }
    }

    @Test("processRootModuleTemplate - when path is not a file - throws notAFile error")
    func processRootModuleTemplate_whenPathIsNotAFile_throwsNotAFileError() async throws {
        try await withDependencies {
            $0.stencilTemplateClient = .liveValue
        } operation: {
            // Given
            let pathStub = try Path.uniqueTemporary()
            defer { try? pathStub.delete() }

            @Dependency(\.stencilTemplateClient) var sut

            let error = await #expect(throws: StencilTemplateClient.Error.self) {
                // When
                try await sut.processRootModuleTemplate(atPath: pathStub, projectName: "Test", moduleName: "Test")
            }

            // Then
            let underlyingError = StencilTemplateClient.Error.notAFile(path: pathStub.string).localizedDescription
            #expect(error == .rootModuleProcessingFailed(underlyingError: underlyingError))
        }
    }

    @Test("processRootModuleTemplate - with invalid template encoding - throws updatingTemplateFailed error")
    func processRootModuleTemplate_withInvalidSyntax_throwsUpdatingTemplateFailedError() async throws {
        try await withDependencies {
            $0.stencilTemplateClient = .liveValue
        } operation: {
            // Given
            let tempPath = try Path.uniqueTemporary()

            let pathStub = tempPath + "Test.swift"
            // Use .utf16 encoding to simulate error
            try pathStub.write("{{ invalid syntax }}", encoding: .utf16)

            defer {
                try? pathStub.delete()
                try? tempPath.delete()
            }

            @Dependency(\.stencilTemplateClient) var sut

            let error = await #expect(throws: StencilTemplateClient.Error.self) {
                // When
                try await sut.processRootModuleTemplate(atPath: pathStub, projectName: "Test", moduleName: "Test")
            }

            // Then
            let errorDescription = try #require(error?.localizedDescription)
            #expect(errorDescription.contains("Failed to update root module stencil template"))
        }
    }

    @Test("processSelectedTargetsAppTemplates - with valid templates - updates file contents")
    func processSelectedTargetsAppTemplates_withValidTemplates_updatesFileContents() async throws {
        try await withDependencies {
            $0.stencilTemplateClient = .liveValue
        } operation: {
            // Given
            let tempPath = try Path.uniqueTemporary()
            let iOSAppStubPath = tempPath + "iOSApp.swift"
            let tvOSAppStubPath = tempPath + "tvOSApp.swift"

            try iOSAppStubPath.write(
                #"import {{ rootModule }} struct iOSApp: App { WindowGroup { {{ rootModule }}View() }}"#,
                encoding: .utf8
            )
            try tvOSAppStubPath.write(
                #"import {{ rootModule }} struct tvOSApp: App { WindowGroup { {{ rootModule }}View() }}"#,
                encoding: .utf8
            )

            defer {
                try? iOSAppStubPath.delete()
                try? tvOSAppStubPath.delete()
                try? tempPath.delete()
            }

            @Dependency(\.stencilTemplateClient) var sut

            // When
            try await sut.processSelectedTargetsAppTemplates(
                targetAppTemplates: [iOSAppStubPath, tvOSAppStubPath],
                moduleName: "RootModule"
            )

            // Then
            let updatedIosTemplate = try iOSAppStubPath.read(.utf8)
            let expectedIosTemplate = #"import RootModule struct iOSApp: App { WindowGroup { RootModuleView() }}"#
            #expect(updatedIosTemplate == expectedIosTemplate)

            let updatedTvosTemplate = try tvOSAppStubPath.read(.utf8)
            let expectedTvosTemplate = #"import RootModule struct tvOSApp: App { WindowGroup { RootModuleView() }}"#
            #expect(updatedTvosTemplate == expectedTvosTemplate)
        }
    }

    @Test("processSelectedTargetsAppTemplates - when one path is not a file - throws notAFile error")
    func processSelectedTargetsAppTemplates_whenOnePathIsNotAFile_throwsNotAFileError() async throws {
        try await withDependencies {
            $0.stencilTemplateClient = .liveValue
        } operation: {
            // Given
            let tempPath = try Path.uniqueTemporary()
            let validTemplatePath = tempPath + "ValidTemplate.swift"
            let invalidTemplatePath = tempPath

            try validTemplatePath.write(#"import {{ rootModule }}"#, encoding: .utf8)

            defer {
                try? validTemplatePath.delete()
                try? invalidTemplatePath.delete()
                try? tempPath.delete()
            }

            @Dependency(\.stencilTemplateClient) var sut

            let error = await #expect(throws: StencilTemplateClient.Error.self) {
                // When
                try await sut.processSelectedTargetsAppTemplates(
                    targetAppTemplates: [validTemplatePath, invalidTemplatePath],
                    moduleName: "RootModule"
                )
            }

            // Then
            let underlyingError = StencilTemplateClient.Error.notAFile(path: invalidTemplatePath.string)
            #expect(error == .appTargetsProcessingFailed(underlyingError: underlyingError.localizedDescription))
        }
    }

    @Test("processSelectedTargetsAppTemplates - when template has invalid syntax - throws templateProcessing error")
    func processSelectedTargetsAppTemplates_whenTemplateHasInvalidSyntax_throwsTemplateProcessingError() async throws {
        try await withDependencies {
            $0.stencilTemplateClient = .liveValue
        } operation: {
            // Given
            let tempPath = try Path.uniqueTemporary()
            let validTemplatePath = tempPath + "ValidTemplate.swift"
            let invalidSyntaxTemplatePath = tempPath + "InvalidSyntaxTemplate.swift"

            try validTemplatePath.write(#"import {{ rootModule }}"#, encoding: .utf8)
            try invalidSyntaxTemplatePath.write(#"{{ invalid syntax }}"#, encoding: .utf16)

            defer {
                try? validTemplatePath.delete()
                try? invalidSyntaxTemplatePath.delete()
                try? tempPath.delete()
            }

            @Dependency(\.stencilTemplateClient) var sut

            let error = await #expect(throws: StencilTemplateClient.Error.self) {
                // When
                try await sut.processSelectedTargetsAppTemplates(
                    targetAppTemplates: [validTemplatePath, invalidSyntaxTemplatePath],
                    moduleName: "RootModule"
                )
            }

            // Then
            let errorDescription = try #require(error?.localizedDescription)
            #expect(errorDescription.contains("Failed to update app target stencil template"))
        }
    }
}

@Suite("StencilTemplateClient.Error Tests", .tags(.unit))
struct StencilTemplateClientErrorTests {
    @Test("errorDescription - with notAFile - returns correctly formatted message")
    func errorDescription_withNotAFile_returnsCorrectlyFormattedMessage() {
        // Given, When
        let sut = StencilTemplateClient.Error.notAFile(path: "/path/to/template.swift")

        // Then
        #expect(sut.errorDescription == "The template at /path/to/template.swift is not a file.")
    }

    @Test("errorDescription - with rootModuleProcessingFailed - returns correctly formatted message")
    func errorDescription_withRootModuleProcessingFailed_returnsCorrectlyFormattedMessage() {
        // Given, When
        let sut = StencilTemplateClient.Error.rootModuleProcessingFailed(underlyingError: "stub error")

        // Then
        #expect(sut.errorDescription == "Failed to update root module stencil template: stub error")
    }

    @Test("errorDescription - with appTargetsProcessingFailed - returns correctly formatted message")
    func errorDescription_withAppTargetsProcessingFailed_returnsCorrectlyFormattedMessage() {
        // Given, When
        let sut = StencilTemplateClient.Error.appTargetsProcessingFailed(underlyingError: "stub error")

        // Then
        #expect(sut.errorDescription == "Failed to update app target stencil template: stub error")
    }
}
