//
//  PackageGraphDependenciesTests.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2025-12-25.
//

import Core
import Foundation
import TestHelpers
import Testing

@Suite("PackageGraphDependencies Tests", .tags(.unit))
struct PackageGraphDependenciesTests {
    @Test("Decodable - with valid JSON - decodes dependency paths")
    func decodable_withValidJSON_decodesDependencyPaths() throws {
        // Given
        let json = Data(
            """
            {
              "identity": "stub-pacakge",
              "name": "StubPackage",
              "url": "/path/to/StubPackage",
              "version": "unspecified",
              "path": "/path/to/StubPackage",
              "dependencies": [
                {
                  "identity": "swift-argument-parser",
                  "name": "swift-argument-parser",
                  "url": "https://github.com/apple/swift-argument-parser.git",
                  "version": "1.7.0",
                  "path": "/path/to/StubPackage/.build/checkouts/swift-argument-parser",
                  "dependencies": []
                },
                {
                  "identity": "swift-configuration",
                  "name": "swift-configuration",
                  "url": "https://github.com/apple/swift-configuration",
                  "version": "1.0.0",
                  "path": "/path/to/StubPackage/.build/checkouts/swift-configuration",
                  "dependencies": []
                }
              ]
            }
            """.utf8
        )

        // When
        let sut = try JSONDecoder().decode(PackageGraphDependencies.self, from: json)

        // Then
        #expect(sut.dependencies.count == 2)
        #expect(sut.dependencies[0].path == "/path/to/StubPackage/.build/checkouts/swift-argument-parser")
        #expect(sut.dependencies[1].path == "/path/to/StubPackage/.build/checkouts/swift-configuration")
    }
}
