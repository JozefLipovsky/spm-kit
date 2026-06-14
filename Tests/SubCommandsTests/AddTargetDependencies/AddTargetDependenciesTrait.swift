//
//  AddTargetDependenciesTrait.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2026-06-06.
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
import TestHelpers

struct AddTargetDependenciesTrait: TestTrait, TestScoping {
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

        let executionContext = AddTargetDependenciesExecutionContext(
            nooraClientSpy: NooraClientSpy(),
            subprocessClientSpy: SubprocessClientSpy(),
            configClientSpy: ConfigClientSpy()
        )

        try configClientStubs.generateConfig(at: pathStub.currentPath)

        try await withDependencies {
            $0.pathClient.current = {
                currentPathStub.path
            }
            $0.nooraClient.targetSelection = { configuration, options in
                await executionContext.nooraClientSpy.recordTargetSelection(
                    configuration: configuration,
                    options: options
                )

                return nooraClientStubs.target
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
            try await AddTargetDependenciesExecutionContext.$current.withValue(executionContext) {
                try await function()
                try pathStub.cleanup()
            }
        }
    }
    // swiftlint:enable function_body_length
}

extension Trait where Self == AddTargetDependenciesTrait {
    static func addTargetDependenciesEnvironmentMock(
        pathClientStub: PathStub.Configuration = .defaultTemporary,
        nooraClientStubs: AddTargetDependenciesTrait.NooraClientStubs = .init(),
        subprocessClientStubs: SubprocessClientStubs = .init(),
        configClientStubs: ConfigFileStub = .init(),
        clientErrorStub: AddTargetDependenciesTrait.ClientErrorStub? = nil
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

extension AddTargetDependenciesTrait {
    enum ClientErrorStub: Error, Equatable {
        case subprocessClient
        case configClient
    }

    struct NooraClientStubs {
        let target: PackageDependency
        let dependencies: [PackageDependency]

        init(
            targeName: String = "TargetStub",
            targetType: PackageJSON.Target.TargetType = .regular,
            dependencies: [PackageDependency] = []
        ) {
            do {
                self.target = try .targetStub(name: targeName, type: targetType)
                self.dependencies = dependencies
            } catch {
                preconditionFailure("Invalid target stub: \(error)")
            }
        }
    }
}
