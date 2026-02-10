//
//  ShellCommandTests.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2025-07-19.
//

import Core
import Subprocess
import TestHelpers
import Testing

@Suite("ShellCommand Tests", .tags(.unit))
struct ShellCommandTests {
    // MARK: - Executable
    @Test("executable - for swift case - returns 'swift' executable")
    func executable_forSwiftCase_returnsSwiftExecutable() {
        // Given
        let sut = ShellCommand.swift(.package(.setToolsVersion(version: "5.9")))

        // When
        let executable = sut.executable

        // Then
        #expect(executable == .name("swift"))
    }

    @Test("executable - for update case - returns 'cp' executable")
    func executable_forUpdateCase_returnsCpExecutable() {
        // Given
        let sut = ShellCommand.update(.replace(.root(), with: TemplateItem(path: "/fake/project")))

        // When
        let executable = sut.executable

        // Then
        #expect(executable == .name("cp"))
    }

    @Test("executable - for rename case - returns 'mv' executable")
    func executable_forRenameCase_returnsMvExecutable() {
        // Given
        let sut = ShellCommand.rename(.projectItem(.root(), to: "New"))

        // When
        let executable = sut.executable

        // Then
        #expect(executable == .name("mv"))
    }

    // MARK: - Arguments
    @Test("arguments - for swift package addTarget - returns addTarget arguments")
    func arguments_forSwiftPackageAddTarget_returnsAddTargetArguments() {
        // Given
        let sut = ShellCommand.swift(.package(.addTarget(name: "MyTarget", dependencies: ["Dep1"])))

        // When
        let arguments = sut.arguments

        // Then
        let expected = ["package", "add-target", "MyTarget", "--type", "library", "--dependencies", "Dep1"]
        #expect(arguments == Subprocess.Arguments(expected))
    }

    @Test("arguments - for swift package addProduct - returns addProduct arguments")
    func arguments_forSwiftPackageAddProduct_returnsAddProductArguments() {
        // Given
        let sut = ShellCommand.swift(.package(.addProduct(name: "MyProduct", targets: ["Target1"])))

        // When
        let arguments = sut.arguments

        // Then
        let expected = ["package", "add-product", "MyProduct", "--type", "library", "--targets", "Target1"]
        #expect(arguments == Subprocess.Arguments(expected))
    }

    @Test("arguments - for swift package setToolsVersion - returns setToolsVersion arguments")
    func arguments_forSwiftPackageSetToolsVersion_returnsSetToolsVersionArguments() {
        // Given
        let sut = ShellCommand.swift(.package(.setToolsVersion(version: "5.9")))

        // When
        let arguments = sut.arguments

        // Then
        #expect(arguments == Subprocess.Arguments(["package", "tools-version", "--set", "5.9"]))
    }

    @Test("arguments - for swift package dumpPackage - returns dumpPackage arguments")
    func arguments_forSwiftPackageDumpPackage_returnsDumpPackageArguments() {
        // Given
        let sut = ShellCommand.swift(.package(.dumpPackage))

        // When
        let arguments = sut.arguments

        // Then
        #expect(arguments == Subprocess.Arguments(["package", "dump-package"]))
    }

    @Test(
        "arguments - for swift package showDependencies - returns showDependencies arguments",
        arguments: DependencyGraphFormat.allCases
    )
    func arguments_forSwiftPackageShowDependencies_returnsShowDependenciesArguments(format: DependencyGraphFormat) {
        // Given
        let sut = ShellCommand.swift(.package(.showDependencies(format: format)))

        // When
        let arguments = sut.arguments

        // Then
        switch format {
            case .text:
                #expect(arguments == Subprocess.Arguments(["package", "show-dependencies", "--format", "text"]))
            case .json:
                #expect(arguments == Subprocess.Arguments(["package", "show-dependencies", "--format", "json"]))
        }
    }

    @Test("arguments - for swift package addTargetDependency - returns addTargetDependency arguments")
    func arguments_forSwiftPackageAddTargetDependency_returnsAddTargetDependencyArguments() {
        // Given
        let sut = ShellCommand.swift(
            .package(.addTargetDependency(dependencyName: "MyDependency", targetName: "MyTarget"))
        )

        // When
        let arguments = sut.arguments

        // Then
        let expected = ["package", "add-target-dependency", "MyDependency", "MyTarget"]
        #expect(arguments == Subprocess.Arguments(expected))
    }

    @Test("arguments - swift package addTargetDependency with package - returns arguments with package arguments")
    func arguments_forSwiftPackageAddTargetDependencyWithPackage_returnsAddTargetDependencyWithPackageArguments() {
        // Given
        let sut = ShellCommand.swift(
            .package(.addTargetDependency(dependencyName: "MyDependency", targetName: "MyTarget", package: "MyPackage"))
        )

        // When
        let arguments = sut.arguments

        // Then
        let expected = ["package", "add-target-dependency", "MyDependency", "MyTarget", "--package", "MyPackage"]
        #expect(arguments == Subprocess.Arguments(expected))
    }

    @Test("arguments - for update copy - returns copy arguments")
    func arguments_forUpdateCopy_returnsCopyArguments() {
        // Given
        let template = TemplateItem(path: "/template/path", copyFlags: ["stub flag"])
        let destination = ProjectDirectory.modules(.sources(.module("MyModule")))
        let sut = ShellCommand.update(.copy(template, to: destination))

        // When
        let arguments = sut.arguments

        // Then
        let expected = ["stub flag", "/template/path", "Modules/Sources/MyModule"]
        #expect(arguments == Subprocess.Arguments(expected))
    }

    @Test("arguments - for update replace - returns replace arguments")
    func arguments_forUpdateReplace_returnsReplaceArguments() {
        // Given
        let template = TemplateItem(path: "/template/path", copyFlags: ["stub flag"])
        let destination = ProjectDirectory.modules(
            .sources(.module("MyModule", file: .file("OldFile", fileExtension: .swift)))
        )
        let sut = ShellCommand.update(.replace(destination, with: template))

        // When
        let arguments = sut.arguments

        // Then
        let expected = ["/template/path", "Modules/Sources/MyModule/OldFile.swift"]
        #expect(arguments == Subprocess.Arguments(expected))
    }

    @Test("arguments - for rename projectItem - returns rename arguments")
    func arguments_forRenameProjectItem_returnsRenameArguments() {
        // Given
        let item = ProjectDirectory.modules(
            .sources(.module("MyModule", file: .file("OldFile", fileExtension: .swift)))
        )
        let sut = ShellCommand.rename(.projectItem(item, to: "NewFile"))

        // When
        let arguments = sut.arguments

        // Then
        let expected = ["Modules/Sources/MyModule/OldFile.swift", "Modules/Sources/MyModule/NewFile.swift"]
        #expect(arguments == Subprocess.Arguments(expected))
    }

    @Test("arguments - for swift format recursive in place - returns format arguments with configuration")
    func arguments_forSwiftFormatRecursiveInPlace_returnsFormatArgumentsWithConfiguration() {
        // Given
        let sut = ShellCommand.swift(.format(.recursiveInPlace(configurationPath: "/path/to/config")))

        // When
        let arguments = sut.arguments

        // Then
        let expected = ["format", "--configuration", "/path/to/config", "--in-place", "--recursive", "."]
        #expect(arguments == Subprocess.Arguments(expected))
    }

    // MARK: - SwiftSubCommand useCustomScratchPath Arguments
    @Test("swift package arguments - with custom scratch path - includes --scratch-path")
    func swiftPackageArguments_withCustomScratchPath_includesScratchPath() {
        // Given
        let sut = ShellCommand.swift(.package(.addTarget(name: "Target"), useCustomScratchPath: true))

        // When
        let arguments = sut.arguments

        // Then
        let expected = ["package", "--scratch-path", ".build/add-target", "add-target", "Target", "--type", "library"]
        #expect(arguments == Subprocess.Arguments(expected))
    }

    @Test("swift package arguments - without custom scratch path - excludes --scratch-path")
    func swiftPackageArguments_withoutCustomScratchPath_excludesScratchPath() {
        // Given
        let sut = ShellCommand.swift(.package(.setToolsVersion(version: "5.9"), useCustomScratchPath: false))

        // When
        let arguments = sut.arguments

        // Then
        let expected = ["package", "tools-version", "--set", "5.9"]
        #expect(arguments == Subprocess.Arguments(expected))
    }
}
