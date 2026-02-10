//
//  PathSegmentConvertibleTests.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2025-09-20.
//

import Core
import TestHelpers
import Testing

@Suite("PathSegmentConvertible default implementation tests", .tags(.unit))
struct PathSegmentConvertibleTests {
    @Test("pathString - returns joined segments string")
    func pathString_returnsJoinedSegmentsString() {
        // Given
        let mock = PathSegmentConvertibleTests.Mock(pathSegments: ["path", "to", "file.swift"])

        // When
        let sut = mock.pathString

        // Then
        #expect(sut == "path/to/file.swift")
    }

    @Test("pathStringRenamingLastSegment - returns string with replaced last segment")
    func pathStringRenamingLastSegment_returnsStringWithReplacedLastSegment() {
        // Given
        let mock = PathSegmentConvertibleTests.Mock(pathSegments: ["path", "to", "file.swift"])

        // When
        let sut = mock.pathStringRenamingLastSegment(with: "newName.swift")

        // Then
        #expect(sut == "path/to/newName.swift")
    }
}

private extension PathSegmentConvertibleTests {
    struct Mock: PathSegmentConvertible {
        let pathSegments: [String]
    }
}
