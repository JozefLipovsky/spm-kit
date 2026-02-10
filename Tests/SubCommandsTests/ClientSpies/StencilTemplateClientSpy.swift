//
//  StencilTemplateClientSpy.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2026-01-19.
//

import Core
import Dependencies
import Foundation

actor StencilTemplateClientSpy {
    private(set) var processedRootModuleTemplates: [RootModuleTemplate]?
    private(set) var processedAppTargetsTemplates: [AppTargetsTemplate]?

    func recordProcessRootModuleTemplate(atPath path: String, projectName: String, moduleName: String) {
        let recording = RootModuleTemplate(path: path, projectName: projectName, moduleName: moduleName)
        if processedRootModuleTemplates == nil {
            processedRootModuleTemplates = [recording]
        } else {
            processedRootModuleTemplates?.append(recording)
        }
    }

    func recordProcessSelectedTargetsAppTemplates(paths: [String], moduleName: String) {
        let recording = AppTargetsTemplate(paths: paths, moduleName: moduleName)
        if processedAppTargetsTemplates == nil {
            processedAppTargetsTemplates = [recording]
        } else {
            processedAppTargetsTemplates?.append(recording)
        }
    }
}

extension StencilTemplateClientSpy {
    struct RootModuleTemplate {
        let path: String
        let projectName: String
        let moduleName: String
    }

    struct AppTargetsTemplate {
        let paths: [String]
        let moduleName: String
    }
}
