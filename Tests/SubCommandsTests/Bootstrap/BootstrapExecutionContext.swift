//
//  BootstrapExecutionContext.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2025-08-17.
//

import Core
import Foundation
import PathKit
import System

actor BootstrapExecutionContext {
    let workingDirectory: String
    let nooraClientSpy: NooraClientSpy
    let subprocessClientSpy: SubprocessClientSpy
    let resourcesClientSpy: ResourcesClientSpy
    let packageEditorClientSpy: PackageEditorClientSpy
    let stencilTemplateClientSpy: StencilTemplateClientSpy
    let xcodeProjClientSpy: XcodeProjClientSpy
    let configClientSpy: ConfigClientSpy

    init(
        workingDirectory: String,
        nooraClientSpy: NooraClientSpy,
        subprocessClientSpy: SubprocessClientSpy,
        resourcesClientSpy: ResourcesClientSpy,
        packageEditorClientSpy: PackageEditorClientSpy,
        stencilTemplateClientSpy: StencilTemplateClientSpy,
        xcodeProjClientSpy: XcodeProjClientSpy,
        configClientSpy: ConfigClientSpy
    ) {
        self.workingDirectory = workingDirectory
        self.nooraClientSpy = nooraClientSpy
        self.subprocessClientSpy = subprocessClientSpy
        self.resourcesClientSpy = resourcesClientSpy
        self.packageEditorClientSpy = packageEditorClientSpy
        self.stencilTemplateClientSpy = stencilTemplateClientSpy
        self.xcodeProjClientSpy = xcodeProjClientSpy
        self.configClientSpy = configClientSpy
    }
}

extension BootstrapExecutionContext {
    @TaskLocal static var current: BootstrapExecutionContext?
}
