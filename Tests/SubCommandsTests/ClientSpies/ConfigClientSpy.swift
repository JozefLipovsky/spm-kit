//
//  ConfigClientSpy.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2026-01-18.
//

import Core
import Dependencies
import Foundation

actor ConfigClientSpy {
    private(set) var modulesPathConfigPaths: [String]?
    private(set) var swiftFormatConfigPathConfigPaths: [String]?

    func recordModulesPath(atConfigPath path: String) {
        if modulesPathConfigPaths == nil {
            modulesPathConfigPaths = [path]
        } else {
            modulesPathConfigPaths?.append(path)
        }
    }

    func recordSwiftFormatConfigPath(atConfigPath path: String) {
        if swiftFormatConfigPathConfigPaths == nil {
            swiftFormatConfigPathConfigPaths = [path]
        } else {
            swiftFormatConfigPathConfigPaths?.append(path)
        }
    }
}
