//
//  ConfigFileStub.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2026-01-07.
//

import PathKit

struct ConfigFileStub {
    let modulesPath: String
    let swiftFormatConfigPath: String
    let generateConfig: Bool

    init(
        modulesPath: String = "/fake/path/to/ModulesStub",
        swiftFormatConfigPath: String = "/fake/path/to/.swift-format-stub",
        generateConfig: Bool = true
    ) {
        self.modulesPath = modulesPath
        self.swiftFormatConfigPath = swiftFormatConfigPath
        self.generateConfig = generateConfig
    }

    func generateConfig(at path: Path) throws {
        guard generateConfig else { return }
        try (path + "spm-kit-config.yaml").write(
            """
            modules-path: \(modulesPath)
            swift-format-config-path: \(swiftFormatConfigPath)
            """
        )
    }
}
