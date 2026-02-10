//
//  PathStub.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2025-08-16.
//

import Foundation
import PathKit

struct PathStub {
    private let rootPath: Path
    let currentPath: Path

    init(configuration: Configuration) throws {
        self.rootPath = try Path.uniqueTemporary()

        switch configuration {
            case .defaultTemporary:
                self.currentPath = self.rootPath
            case .temporaryWithBase(let projectName, let includeProjectTemplate):
                self.currentPath = self.rootPath + projectName
                try self.currentPath.mkdir()
                if includeProjectTemplate {
                    try (self.currentPath + "App").mkdir()
                    try (self.currentPath + "Modules").mkdir()
                }
        }
    }

    func cleanup() throws {
        try rootPath.delete()
    }
}

extension PathStub {
    enum Configuration: Equatable {
        case defaultTemporary
        case temporaryWithBase(named: String, includeProjectTemplate: Bool = false)
    }
}
