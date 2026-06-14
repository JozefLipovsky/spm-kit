//
//  AddModuleTrait.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2026-01-06.
//

import Core
import Dependencies
import DependenciesTestSupport
import Foundation
import IssueReportingTestSupport
import Noora
import PathKit
import System
import Testing

struct AddModuleTrait: TestTrait, TestScoping {
    private let pathClientStub: PathStub.Configuration
    private let nooraClientStubs: NooraClientStubs
    private let subprocessClientStubs: SubprocessClientStubs
    private let configClientStubs: ConfigFileStub
    private let clientErrorStub: ClientErrorStub?

    init(
        pathClientStub: PathStub.Configuration,
        nooraClientStubs: NooraClientStubs,
        subprocessClientStubs: SubprocessClientStubs,
        configClientStubs: ConfigFileStub,
        clientErrorStub: ClientErrorStub?
    ) {
        self.pathClientStub = pathClientStub
        self.nooraClientStubs = nooraClientStubs
        self.subprocessClientStubs = subprocessClientStubs
        self.configClientStubs = configClientStubs
        self.clientErrorStub = clientErrorStub
    }

    // swiftlint:disable function_body_length
    func provideScope(
        for test: Test,
        testCase: Test.Case?,
        performing function: @Sendable () async throws -> Void
    ) async throws {
        let pathStub = try PathStub(configuration: pathClientStub)
        let currentPathStub = pathStub.currentPath.string

        let executionContext = AddModuleExecutionContext(
            nooraClientSpy: NooraClientSpy(),
            subprocessClientSpy: SubprocessClientSpy(),
            configClientSpy: ConfigClientSpy()
        )

        try configClientStubs.generateConfig(at: pathStub.currentPath)

        try await withDependencies {
            $0.pathClient.current = {
                currentPathStub.path
            }
            $0.nooraClient.textInput = { configuration, argument in
                await executionContext.nooraClientSpy.recordTextInput(configuration: configuration, argument: argument)
                return nooraClientStubs.moduleName
            }
            $0.nooraClient.productTypeSelection = { configuration, argument in
                await executionContext.nooraClientSpy.recordProductTypeSelection(
                    configuration: configuration,
                    productType: argument
                )
                return nooraClientStubs.productType
            }
            $0.nooraClient.testingLibrarySelection = { configuration, argument in
                await executionContext.nooraClientSpy.recordTestingLibrarySelection(
                    configuration: configuration,
                    testingLibrary: argument
                )
                return nooraClientStubs.testingLibrary
            }
            $0.nooraClient.yesOrNoConfirmation = { configuration, shouldSkip in
                await executionContext.nooraClientSpy.recordYesOrNoConfirmation(
                    configuration: configuration,
                    shouldSkip: shouldSkip
                )
                return nooraClientStubs.selectDependencies
            }
            $0.nooraClient.dependenciesSelection = { configuration, options in
                await executionContext.nooraClientSpy.recordDependenciesSelection(
                    configuration: configuration,
                    options: options
                )
                return nooraClientStubs.dependencies
            }
            $0.nooraClient.progress = { message, successMessage, errorMessage, operation in
                await executionContext.nooraClientSpy.recordOperationProgress(
                    message: message,
                    successMessage: successMessage,
                    errorMessage: errorMessage
                )
                return try await operation { _ in }
            }
            $0.subprocessClient.run = { command, workingDirectory in
                if let clientErrorStub, case .subprocessClient = clientErrorStub { throw clientErrorStub }
                await executionContext.subprocessClientSpy.recordRun(
                    command: command,
                    workingDirectory: workingDirectory
                )
            }
            $0.subprocessClient.runAndCapture = { command, workingDirectory in
                if let clientErrorStub, case .subprocessClient = clientErrorStub { throw clientErrorStub }
                await executionContext.subprocessClientSpy.recordRunAndCapture(
                    command: command,
                    workingDirectory: workingDirectory
                )
                return subprocessClientStubs.result(for: command)
            }
            $0.configClient.modulesPath = { configPath in
                if let clientErrorStub, case .configClient = clientErrorStub { throw clientErrorStub }
                await executionContext.configClientSpy.recordModulesPath(atConfigPath: configPath.string)
                return configClientStubs.modulesPath.path
            }
            $0.configClient.swiftFormatConfigPath = { configPath in
                if let clientErrorStub, case .configClient = clientErrorStub { throw clientErrorStub }
                await executionContext.configClientSpy.recordSwiftFormatConfigPath(atConfigPath: configPath.string)
                return configClientStubs.swiftFormatConfigPath.path
            }
        } operation: { [executionContext, pathStub] in
            try await AddModuleExecutionContext.$current.withValue(executionContext) {
                try await function()
                try pathStub.cleanup()
            }
        }
    }
    // swiftlint:enable function_body_length
}

extension Trait where Self == AddModuleTrait {
    static func addModuleEnvironmentMock(
        pathClientStub: PathStub.Configuration = .defaultTemporary,
        nooraClientStubs: AddModuleTrait.NooraClientStubs = .init(),
        subprocessClientStubs: SubprocessClientStubs = .init(),
        configClientStubs: ConfigFileStub = .init(),
        clientErrorStub: AddModuleTrait.ClientErrorStub? = nil
    ) -> Self {
        .init(
            pathClientStub: pathClientStub,
            nooraClientStubs: nooraClientStubs,
            subprocessClientStubs: subprocessClientStubs,
            configClientStubs: configClientStubs,
            clientErrorStub: clientErrorStub
        )
    }
}

extension AddModuleTrait {
    enum ClientErrorStub: Error, Equatable {
        case subprocessClient
        case configClient
    }

    struct NooraClientStubs {
        let moduleName: String
        let productType: ProductType
        let testingLibrary: TestingLibrary
        let selectDependencies: Bool
        let dependencies: [PackageDependency]

        init(
            moduleName: String = "ModuleStub",
            productType: ProductType = .library,
            testingLibrary: TestingLibrary = .swiftTesting,
            selectDependencies: Bool = false,
            dependencies: [PackageDependency] = []
        ) {
            self.moduleName = moduleName
            self.productType = productType
            self.testingLibrary = testingLibrary
            self.selectDependencies = selectDependencies
            self.dependencies = dependencies
        }
    }
}
