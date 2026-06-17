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
            $0.currentPath(currentPathStub)
            $0.targetSelection(executionContext: executionContext, targetStub: nooraClientStubs.target)
            $0.dependenciesSelection(
                executionContext: executionContext,
                dependenciesStub: nooraClientStubs.dependencies
            )
            $0.progress(executionContext: executionContext)
            $0.runCommand(executionContext: executionContext, clientErrorStub: clientErrorStub)
            $0.runAndCaptureCommand(
                executionContext: executionContext,
                subprocessClientStubs: subprocessClientStubs,
                clientErrorStub: clientErrorStub
            )
            $0.modulesPath(
                executionContext: executionContext,
                configClientStubs: configClientStubs,
                clientErrorStub: clientErrorStub
            )
            $0.swiftFormatConfigPath(
                executionContext: executionContext,
                configClientStubs: configClientStubs,
                clientErrorStub: clientErrorStub
            )
        } operation: { [executionContext, pathStub] in
            try await AddTargetDependenciesExecutionContext.$current.withValue(executionContext) {
                try await function()
                try pathStub.cleanup()
            }
        }
    }
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
            targetName: String = "TargetStub",
            targetType: PackageJSON.Target.TargetType = .regular,
            dependencies: [String] = []
        ) {
            do {
                self.target = try .targetStub(name: targetName, type: targetType)
                self.dependencies = try dependencies.map { try .targetStub(name: $0) }
            } catch {
                preconditionFailure("Invalid NooraClient stub: \(error)")
            }
        }
    }
}

private extension DependencyValues {
    mutating func currentPath(_ currentPath: String) {
        pathClient.current = { currentPath.path }
    }

    mutating func targetSelection(
        executionContext: AddTargetDependenciesExecutionContext,
        targetStub: PackageDependency
    ) {
        nooraClient.targetSelection = { configuration, options in
            await executionContext.nooraClientSpy.recordTargetSelection(configuration: configuration, options: options)
            return targetStub
        }
    }

    mutating func dependenciesSelection(
        executionContext: AddTargetDependenciesExecutionContext,
        dependenciesStub: [PackageDependency]
    ) {
        nooraClient.dependenciesSelection = { configuration, options in
            await executionContext.nooraClientSpy.recordDependenciesSelection(
                configuration: configuration,
                options: options
            )

            return dependenciesStub
        }
    }

    mutating func progress(executionContext: AddTargetDependenciesExecutionContext) {
        nooraClient.progress = { message, successMessage, errorMessage, operation in
            await executionContext.nooraClientSpy.recordOperationProgress(
                message: message,
                successMessage: successMessage,
                errorMessage: errorMessage
            )

            return try await operation { _ in }
        }
    }

    mutating func runCommand(
        executionContext: AddTargetDependenciesExecutionContext,
        clientErrorStub: AddTargetDependenciesTrait.ClientErrorStub?
    ) {
        subprocessClient.run = { command, workingDirectory in
            if let clientErrorStub, case .subprocessClient = clientErrorStub { throw clientErrorStub }
            await executionContext.subprocessClientSpy.recordRun(
                command: command,
                workingDirectory: workingDirectory
            )
        }
    }

    mutating func runAndCaptureCommand(
        executionContext: AddTargetDependenciesExecutionContext,
        subprocessClientStubs: SubprocessClientStubs,
        clientErrorStub: AddTargetDependenciesTrait.ClientErrorStub?
    ) {
        subprocessClient.runAndCapture = { command, workingDirectory in
            if let clientErrorStub, case .subprocessClient = clientErrorStub { throw clientErrorStub }
            await executionContext.subprocessClientSpy.recordRunAndCapture(
                command: command,
                workingDirectory: workingDirectory
            )

            return subprocessClientStubs.result(for: command)
        }
    }

    mutating func modulesPath(
        executionContext: AddTargetDependenciesExecutionContext,
        configClientStubs: ConfigFileStub,
        clientErrorStub: AddTargetDependenciesTrait.ClientErrorStub?
    ) {
        configClient.modulesPath = { configPath in
            if let clientErrorStub, case .configClient = clientErrorStub { throw clientErrorStub }
            await executionContext.configClientSpy.recordModulesPath(atConfigPath: configPath.string)
            return configClientStubs.modulesPath.path
        }
    }

    mutating func swiftFormatConfigPath(
        executionContext: AddTargetDependenciesExecutionContext,
        configClientStubs: ConfigFileStub,
        clientErrorStub: AddTargetDependenciesTrait.ClientErrorStub?
    ) {
        configClient.swiftFormatConfigPath = { configPath in
            if let clientErrorStub, case .configClient = clientErrorStub { throw clientErrorStub }
            await executionContext.configClientSpy.recordSwiftFormatConfigPath(atConfigPath: configPath.string)
            return configClientStubs.swiftFormatConfigPath.path
        }
    }
}
