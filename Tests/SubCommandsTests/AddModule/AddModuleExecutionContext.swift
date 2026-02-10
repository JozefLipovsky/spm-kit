//
//  AddModuleExecutionContext.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2026-01-06.
//

import Foundation
import PathKit
import System

actor AddModuleExecutionContext {
    let nooraClientSpy: NooraClientSpy
    let subprocessClientSpy: SubprocessClientSpy
    let configClientSpy: ConfigClientSpy

    init(
        nooraClientSpy: NooraClientSpy,
        subprocessClientSpy: SubprocessClientSpy,
        configClientSpy: ConfigClientSpy
    ) {
        self.nooraClientSpy = nooraClientSpy
        self.subprocessClientSpy = subprocessClientSpy
        self.configClientSpy = configClientSpy
    }
}

extension AddModuleExecutionContext {
    @TaskLocal static var current: AddModuleExecutionContext?
}
