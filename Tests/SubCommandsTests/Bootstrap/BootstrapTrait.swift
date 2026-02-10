//
//  BootstrapTrait.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2025-08-17.
//

import Core
import Dependencies
import DependenciesTestSupport
import IssueReportingTestSupport
import Noora
import PathKit
import System
import Testing

struct BootstrapTrait: TestTrait, TestScoping {
    private let pathStub: PathStub.Configuration
    private let configClientStubs: ConfigFileStub
    private let nooraClientStubs: NooraClientStubs
    private let resourcesClientStubs: ResourcesClientStubs
    private let clientErrorStub: ClientErrorStub?

    init(
        pathStub: PathStub.Configuration,
        configClientStubs: ConfigFileStub,
        nooraClientStubs: NooraClientStubs,
        resourcesClientStubs: ResourcesClientStubs,
        clientErrorStub: ClientErrorStub?
    ) {
        self.pathStub = pathStub
        self.configClientStubs = configClientStubs
        self.nooraClientStubs = nooraClientStubs
        self.resourcesClientStubs = resourcesClientStubs
        self.clientErrorStub = clientErrorStub
    }

    // swiftlint:disable function_body_length
    func provideScope(
        for test: Test,
        testCase: Test.Case?,
        performing function: @Sendable () async throws -> Void
    ) async throws {
        let pathStub = try PathStub(configuration: pathStub)
        let workingDirectoryStub = pathStub.currentPath.string

        let executionContext = BootstrapExecutionContext(
            workingDirectory: workingDirectoryStub,
            nooraClientSpy: NooraClientSpy(),
            subprocessClientSpy: SubprocessClientSpy(),
            resourcesClientSpy: ResourcesClientSpy(),
            packageEditorClientSpy: PackageEditorClientSpy(),
            stencilTemplateClientSpy: StencilTemplateClientSpy(),
            xcodeProjClientSpy: XcodeProjClientSpy(),
            configClientSpy: ConfigClientSpy()
        )

        try configClientStubs.generateConfig(at: pathStub.currentPath)

        try await withDependencies {
            $0.pathClient.current = {
                workingDirectoryStub.path
            }
            $0.nooraClient.textInput = { configuration, argument in
                await executionContext.nooraClientSpy.recordTextInput(configuration: configuration, argument: argument)
                return nooraClientStubs.textInput(for: configuration)
            }
            $0.nooraClient.testingLibrarySelection = { configuration, argument in
                await executionContext.nooraClientSpy.recordTestingLibrarySelection(
                    configuration: configuration,
                    testingLibrary: argument
                )
                return nooraClientStubs.testingLibrary
            }
            $0.nooraClient.platformsSelection = { configuration, argument in
                await executionContext.nooraClientSpy.recordPlatformsSelection(
                    configuration: configuration,
                    platforms: argument
                )
                return nooraClientStubs.platforms
            }
            $0.subprocessClient.run = { command, workingDirectory in
                if let clientErrorStub, case .subprocessClient = clientErrorStub { throw clientErrorStub }
                await executionContext.subprocessClientSpy.recordRun(
                    command: command,
                    workingDirectory: workingDirectory
                )
            }
            $0.resourcesClient.templateItem = { type in
                if let clientErrorStub, case .resourcesClient = clientErrorStub { throw clientErrorStub }
                await executionContext.resourcesClientSpy.recordTemplateItem(type: type)
                return resourcesClientStubs.templateItem(for: type)
            }
            $0.packageEditorClient.add = { platforms, path in
                if let clientErrorStub, case .packageEditorClient = clientErrorStub { throw clientErrorStub }
                await executionContext.packageEditorClientSpy.recordAdd(platforms: platforms, toManifestAt: path.string)
            }
            $0.stencilTemplateClient.processRootModuleTemplate = { path, projectName, moduleName in
                if let clientErrorStub, case .stencilTemplateClient = clientErrorStub { throw clientErrorStub }
                await executionContext.stencilTemplateClientSpy.recordProcessRootModuleTemplate(
                    atPath: path.string,
                    projectName: projectName,
                    moduleName: moduleName
                )
            }
            $0.stencilTemplateClient.processSelectedTargetsAppTemplates = { targetAppTemplates, moduleName in
                if let clientErrorStub, case .stencilTemplateClient = clientErrorStub { throw clientErrorStub }
                await executionContext.stencilTemplateClientSpy.recordProcessSelectedTargetsAppTemplates(
                    paths: targetAppTemplates.map(\.string),
                    moduleName: moduleName
                )
            }
            $0.xcodeProjClient.updateProjectReference = { workspace, newProjectName in
                if let clientErrorStub, case .xcodeProjClient = clientErrorStub { throw clientErrorStub }
                await executionContext.xcodeProjClientSpy.recordUpdateProjectReference(
                    inWorkspace: workspace.string,
                    newProjectName: newProjectName
                )
            }
            $0.xcodeProjClient.configureProject = { configuration in
                if let clientErrorStub, case .xcodeProjClient = clientErrorStub { throw clientErrorStub }
                await executionContext.xcodeProjClientSpy.recordConfigureProject(
                    projectPath: configuration.projectPath.string,
                    projectRootPath: configuration.projectRootPath.string,
                    newProjectName: configuration.newProjectName,
                    selectedPlatforms: configuration.selectedPlatforms,
                    bundleIdentifier: configuration.bundleIdentifier,
                    rootModuleName: configuration.rootModuleName
                )
            }
            $0.configClient.swiftFormatConfigPath = { configPath in
                if let clientErrorStub, case .configClient = clientErrorStub { throw clientErrorStub }
                await executionContext.configClientSpy.recordSwiftFormatConfigPath(atConfigPath: configPath.string)
                return configClientStubs.swiftFormatConfigPath.path
            }
        } operation: { [executionContext, pathStub] in
            try await BootstrapExecutionContext.$current.withValue(executionContext) {
                try await function()
                try pathStub.cleanup()
            }
        }
    }
    // swiftlint:enable function_body_length
}

extension Trait where Self == BootstrapTrait {
    static func bootstrapEnvironmentMock(
        pathStub: PathStub.Configuration = .defaultTemporary,
        configClientStubs: ConfigFileStub = ConfigFileStub(),
        nooraClientStubs: BootstrapTrait.NooraClientStubs = .init(),
        resourcesClientStubs: BootstrapTrait.ResourcesClientStubs = .init(),
        clientErrorStub: BootstrapTrait.ClientErrorStub? = nil
    ) -> Self {
        .init(
            pathStub: pathStub,
            configClientStubs: configClientStubs,
            nooraClientStubs: nooraClientStubs,
            resourcesClientStubs: resourcesClientStubs,
            clientErrorStub: clientErrorStub,
        )
    }
}

extension BootstrapTrait {
    enum ClientErrorStub: Error, Equatable {
        case subprocessClient
        case resourcesClient
        case packageEditorClient
        case stencilTemplateClient
        case xcodeProjClient
        case configClient
    }

    struct NooraClientStubs {
        let projectName: String
        let companyDomain: String
        let platforms: [any PlatformVersion]
        let rootModule: String
        let testingLibrary: TestingLibrary

        init(
            projectName: String = "ProjectStub",
            companyDomain: String = "example.com",
            platforms: [any PlatformVersion] = [IOSVersion.v26],
            rootModule: String = "RootModuleStub",
            testingLibrary: TestingLibrary = .swiftTesting
        ) {
            self.projectName = projectName
            self.companyDomain = companyDomain
            self.platforms = platforms
            self.rootModule = rootModule
            self.testingLibrary = testingLibrary
        }

        // TODO: Find a better way to handle stubs for reusable client methods
        func textInput(for configuration: NooraPromptConfiguration) -> String {
            switch configuration.title.plain() {
                case "Project name":
                    return projectName
                case "Company domain":
                    return companyDomain
                case "Root module":
                    return rootModule
                default:
                    reportIssue("Invalid noora stub.")
                    return ""
            }
        }
    }

    struct ResourcesClientStubs {
        let rootModuleViewPath: String
        let xcodeProjectPath: String
        let spmKitConfigPath: String
        let swiftFormatConfigPath: String

        init(
            rootModuleViewPath: String = "/fake/path/to/RootModuleView.swift",
            xcodeProjectPath: String = "/fake/path/to/XcodeProject",
            spmKitConfigPath: String = "/fake/path/to/spm-kit-config.yaml",
            swiftFormatConfigPath: String = "/fake/path/to/.swift-format"
        ) {
            self.rootModuleViewPath = rootModuleViewPath
            self.xcodeProjectPath = xcodeProjectPath
            self.spmKitConfigPath = spmKitConfigPath
            self.swiftFormatConfigPath = swiftFormatConfigPath
        }

        // TODO: Find a better way to handle stubs for reusable client methods
        func templateItem(for type: TemplateType) -> TemplateItem {
            switch type {
                case .rootModuleView:
                    return TemplateItem(path: rootModuleViewPath)
                case .xcodeProject:
                    return TemplateItem(path: xcodeProjectPath, copyFlags: ["-R"])
                case .spmKitConfig:
                    return TemplateItem(path: spmKitConfigPath)
                case .swiftFormatConfig:
                    return TemplateItem(path: swiftFormatConfigPath)
            }
        }
    }
}
