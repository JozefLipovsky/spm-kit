//
//  Stubs.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2026-03-21.
//

import Core
import Foundation

package extension PackageJSON {
    static var stub: Data {
        Data(
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
    }
}
