//
//  PathExtensionsTests.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2025-08-31.
//

import Core
import PathKit
import TestHelpers
import Testing

@Suite("PathExtensions Tests", .tags(.integration))
struct PathExtensionsTests {
    @Test("isRootPath(of:) - when last component matches - returns true")
    func isRootPath_whenLastComponentMatches_returnsTrue() {
        // Given, When
        let path = Path("/some/path/to/MyProject")
        let projectName = "MyProject"

        // Then
        #expect(path.isRootPath(of: projectName))
    }

    @Test("isRootPath(of:) - when last component does not match - returns false")
    func isRootPath_whenLastComponentDoesNotMatch_returnsFalse() {
        // Given, When
        let path = Path("/some/path/to/AnotherProject")
        let projectName = "MyProject"

        // Then
        #expect(!path.isRootPath(of: projectName))
    }

    @Test("containsBootstrappedProject - when App directory exists - returns true")
    func containsBootstrappedProject_whenAppDirectoryExists_returnsTrue() throws {
        // Given, When
        let tempPath = try Path.uniqueTemporary()
        try (tempPath + "App").mkdir()
        defer { try? tempPath.delete() }

        // Then
        #expect(tempPath.containsBootstrappedProject)
    }

    @Test("containsBootstrappedProject - when Modules directory exists - returns true")
    func containsBootstrappedProject_whenModulesDirectoryExists_returnsTrue() throws {
        // Given, When
        let tempPath = try Path.uniqueTemporary()
        try (tempPath + "Modules").mkdir()
        defer { try? tempPath.delete() }

        // Then
        #expect(tempPath.containsBootstrappedProject)
    }

    @Test("containsBootstrappedProject - when both directories exist - returns true")
    func containsBootstrappedProject_whenBothDirectoriesExist_returnsTrue() throws {
        // Given, When
        let tempPath = try Path.uniqueTemporary()
        try (tempPath + "App").mkdir()
        try (tempPath + "Modules").mkdir()
        defer { try? tempPath.delete() }

        // Then
        #expect(tempPath.containsBootstrappedProject)
    }

    @Test("containsBootstrappedProject - when no relevant directories exist - returns false")
    func containsBootstrappedProject_whenNoRelevantDirectoriesExist_returnsFalse() throws {
        // Given, When
        let tempPath = try Path.uniqueTemporary()
        try (tempPath + "OtherFolder").mkdir()
        defer { try? tempPath.delete() }

        // Then
        #expect(!tempPath.containsBootstrappedProject)
    }

    @Test("containsBootstrappedProject - when path is empty - returns false")
    func containsBootstrappedProject_whenPathIsEmpty_returnsFalse() throws {
        // Given, When
        let tempPath = try Path.uniqueTemporary()
        defer { try? tempPath.delete() }

        // Then
        #expect(!tempPath.containsBootstrappedProject)
    }

    @Test("pathByRenaming(to:) - returns new path with replaced filename")
    func pathByRenaming_returnsNewPathWithReplacedFilename() {
        // Given
        let path = Path("/some/path/to/oldFile.swift")
        let newFileName = "newFile.swift"

        // When
        let sut = path.pathByRenaming(to: newFileName)

        // Then
        let expectedPath = Path("/some/path/to/newFile.swift")
        #expect(sut == expectedPath)
    }

    @Test("ancestor(containing:) - when file exists in current directory - returns path to file")
    func ancestor_whenFileExistsInCurrentDirectory_returnsPathToFile() throws {
        // Given
        let tempPath = try Path.uniqueTemporary()
        let fileName = "test.txt"
        let filePath = tempPath + fileName
        try filePath.write("")
        defer { try? tempPath.delete() }

        // When
        let sut = tempPath.ancestor(containing: fileName)

        // Then
        #expect(sut == filePath.absolute())
    }

    @Test("ancestor(containing:) - when file exists in parent directory - returns path to file")
    func ancestor_whenFileExistsInParentDirectory_returnsPathToFile() throws {
        // Given
        let rootPath = try Path.uniqueTemporary()
        let subPath = rootPath + "sub"
        try subPath.mkdir()

        let fileName = "test.txt"
        let filePath = rootPath + fileName
        try filePath.write("")
        defer { try? rootPath.delete() }

        // When
        let sut = subPath.ancestor(containing: fileName)

        // Then
        #expect(sut == filePath.absolute())
    }

    @Test("ancestor(containing:) - when file exists in ancestor directory - returns path to file")
    func ancestor_whenFileExistsInAncestorDirectory_returnsPathToFile() throws {
        // Given
        let rootPath = try Path.uniqueTemporary()
        let deepPath = rootPath + "sub1" + "sub2"
        try deepPath.mkpath()

        let fileName = "test.txt"
        let filePath = rootPath + fileName
        try filePath.write("")
        defer { try? rootPath.delete() }

        // When
        let sut = deepPath.ancestor(containing: fileName)

        // Then
        #expect(sut == filePath.absolute())
    }

    @Test("ancestor(containing:) - when file does not exist in any parent - returns nil")
    func ancestor_whenFileDoesNotExistInAnyParent_returnsNil() throws {
        // Given
        let tempPath = try Path.uniqueTemporary()
        defer { try? tempPath.delete() }

        // When
        let sut = tempPath.ancestor(containing: "nonexistent.txt")

        // Then
        #expect(sut == nil)
    }
}
