//
//  PackageJSON+Extensions.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2026-06-07.
//

import Core
import Foundation

package extension PackageJSON.Product {
    static func stub(name: String = "ProductStub", type: ProductType = .library) throws -> PackageJSON.Product {
        let data = Data(
            """
            {
                "name": "\(name)",
                "type": { "\(type.rawValue)": {} }
            }
            """.utf8
        )

        return try JSONDecoder().decode(PackageJSON.Product.self, from: data)
    }
}

package extension PackageJSON.Target {
    static func stub(name: String = "TargetStub", type: TargetType = .regular) throws -> PackageJSON.Target {
        let data = Data(
            """
            {
                "name": "\(name)",
                "type": "\(type.rawValue)"
            }
            """.utf8
        )

        return try JSONDecoder().decode(PackageJSON.Target.self, from: data)
    }
}

package extension PackageJSON {
    static func stub() throws -> PackageJSON {
        let data = Data(
            """
            {
              "cLanguageStandard": null,
              "dependencies": [],
              "name" : "StubPackage",
              "products": [
                {
                  "name": "Library",
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
                  "name": "ExecutableTarget",
                  "type": "executable",
                  "checksum": "12345"
                },
                {
                  "name": "OtherTarget",
                  "type": "unknown"
                }
              ],
              "toolsVersion": { "_version": "6.2.0" }
            }
            """.utf8
        )

        return try JSONDecoder().decode(PackageJSON.self, from: data)
    }
}
