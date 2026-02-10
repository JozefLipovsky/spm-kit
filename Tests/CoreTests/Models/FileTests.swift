//
//  FileTests.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2025-09-20.
//

import Core
import TestHelpers
import Testing

@Suite("File Tests", .tags(.unit))
struct FileTests {
    @Test("File - pathSegments - returns expected segments")
    func file_pathSegments_returnsExpectedSegments() {
        // Given, When
        let sut = File.file("TestFile", fileExtension: .xcodeproj)

        // Then
        #expect(sut.pathSegments == ["TestFile.xcodeproj"])
    }

    @Test("File - renamingBase - returns new base")
    func file_renamingBase_returnsNewBase() {
        // Givem
        let sut = File.file("TestFile", fileExtension: .xcworkspace)

        // When
        let renamedBase = sut.renamingBase(to: "NewName")

        // Then
        #expect(renamedBase.pathSegments == ["NewName.xcworkspace"])
    }

    @Test("FileExtension - pathSegments -  returns expected segment", arguments: File.FileExtension.allCases)
    func fileExtension_pathSegments_returnsExpectedSegment(fileExtension: File.FileExtension) {
        // Given, When
        let sut = fileExtension.pathSegments

        // Then
        switch fileExtension {
            case .swift:
                #expect(sut == [".swift"])
            case .xcworkspace:
                #expect(sut == [".xcworkspace"])
            case .xcodeproj:
                #expect(sut == [".xcodeproj"])
        }
    }
}
