//
//  ResourcesClientSpy.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2026-01-19.
//

import Core
import Dependencies

actor ResourcesClientSpy {
    private(set) var templateItemCalls: [TemplateType]?

    func recordTemplateItem(type: TemplateType) {
        if templateItemCalls == nil {
            templateItemCalls = [type]
        } else {
            templateItemCalls?.append(type)
        }
    }
}
