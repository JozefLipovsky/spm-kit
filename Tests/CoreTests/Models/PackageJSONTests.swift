//
//  PackageJSONTests.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2025-12-22.
//

import Core
import Foundation
import TestHelpers
import Testing

@Suite("PackageJSON Tests", .tags(.unit))
struct PackageJSONTests {
    @Test("Decodable - with valid JSON - decodes targets and product types")
    func decodable_withValidJSON_decodesTargetsAndProductTypes() throws {
        // Given, When
        let sut = try JSONDecoder().decode(PackageJSON.self, from: jsonStub)

        // Then
        #expect(sut.name == "StubPackage")

        #expect(sut.products.count == 6)
        #expect(sut.products[0].name == "AutomaticLibrary")
        #expect(sut.products[0].type == .library)
        #expect(sut.products[1].name == "StaticLibrary")
        #expect(sut.products[1].type == .library)
        #expect(sut.products[2].name == "DynamicLibrary")
        #expect(sut.products[2].type == .library)
        #expect(sut.products[3].name == "Executable")
        #expect(sut.products[3].type == .executable)
        #expect(sut.products[4].name == "Plugin")
        #expect(sut.products[4].type == .plugin)
        #expect(sut.products[5].name == "Other")
        #expect(sut.products[5].type == .other)

        #expect(sut.targets.count == 4)
        #expect(sut.targets[0].name == "RegularTarget")
        #expect(sut.targets[0].type == .regular)
        #expect(sut.targets[1].name == "TestTarget")
        #expect(sut.targets[1].type == .test)
        #expect(sut.targets[2].name == "MacroTarget")
        #expect(sut.targets[2].type == .macro)
        #expect(sut.targets[3].name == "BinaryTarget")
        #expect(sut.targets[3].type == .other)
    }
}

private extension PackageJSONTests {
    var jsonStub: Data {
        Data(
            """
            {
              "cLanguageStandard": null,
              "dependencies": [],
              "name" : "StubPackage",
              "products": [
                {
                  "name": "AutomaticLibrary",
                  "settings": [],
                  "targets": [
                    "AutomaticLibraryTarget"
                  ],
                  "type": {
                    "library": [
                      "automatic"
                    ]
                  }
                },
                {
                  "name": "StaticLibrary",
                  "settings": [],
                  "targets": [
                    "StaticLibraryTarget"
                  ],
                  "type": {
                    "library": [
                      "static"
                    ]
                  }
                },
                {
                  "name": "DynamicLibrary",
                  "settings": [],
                  "targets": [
                    "DynamicLibraryTarget"
                  ],
                  "type": {
                    "library": [
                      "dynamic"
                    ]
                  }
                },
                {
                  "name": "Executable",
                  "settings": [],
                  "targets": [
                    "ExecutableTarget"
                  ],
                  "type": {
                    "executable": null
                  }
                },
                {
                  "name": "Plugin",
                  "settings": [],
                  "targets": [
                    "PluginTarget"
                  ],
                  "type": {
                    "plugin": null
                  }
                },
                {
                  "name": "Other",
                  "settings": [],
                  "targets": [
                    "Other"
                  ],
                  "type": {
                    "unknown": null
                  }
                }
              ],
              "targets": [
                {
                  "name": "RegularTarget",
                  "type": "regular",
                  "path": "Sources/RegularTarget"
                },
                {
                  "name": "TestTarget",
                  "type": "test",
                  "resources": []
                },
                {
                  "name": "MacroTarget",
                  "type": "macro"
                },
                {
                  "name": "BinaryTarget",
                  "type": "binary",
                  "checksum": "12345"
                }
              ],
              "toolsVersion": { "_version": "6.2.0" }
            }
            """.utf8
        )
    }
}
