//
//  File.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2026-06-13.
//

import Core
import Foundation

struct SubprocessClientStubs {
    let packageDump: Data
    let showDependencies: Data

    init(
        packageDump: String = SubprocessClientStubs.packageJSON,
        showDependencies: String = SubprocessClientStubs.dependenciesGraph
    ) {
        self.packageDump = Data(packageDump.utf8)
        self.showDependencies = Data(showDependencies.utf8)
    }

    // TODO: Find a better way to handle stubs for reusable client methods
    func result(for command: ShellCommand) -> Data {
        switch command {
            case .swift(.package(.dumpPackage, _)):
                return packageDump
            case .swift(.package(.showDependencies(.json), _)):
                return showDependencies
            default:
                preconditionFailure("Invalid command stub.")
        }
    }
}

extension SubprocessClientStubs {
    static var packageJSON: String {
        """
        {
          "name": "StubPackage",
          "products": [
            {
              "name": "ProductA",
              "type": { "library": ["automatic"] },
              "targets": ["TargetA"]
            },
            {
              "name": "ProductB",
              "type": { "library": ["automatic"] },
              "targets": ["TargetB"]
            }
          ],
          "targets": [
            {
              "name": "TargetA",
              "type": "regular"
            },
            {
              "name": "TargetB",
              "type": "regular"
            },
            {
              "name": "TargetC",
              "type": "test"
            }
          ]
        }
        """
    }

    static var dependenciesGraph: String {
        """
        {
          "dependencies": [
            {
              "path": "/path/to/DependencyA"
            }
          ]
        }
        """
    }
}
