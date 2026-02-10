//
//  ProductTypeTests.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2025-07-20.
//

import Core
import TestHelpers
import Testing

@Suite("ProductType Tests", .tags(.unit))
struct ProductTypeTests {
    @Test("CaseIterable - allCases = excludes plugin type")
    func caseIterable_allCases_excludesPluginType() {
        // Given, When
        let sut = ProductType.allCases

        // Then
        #expect(sut.count == 4)
        #expect(sut.contains(.library))
        #expect(sut.contains(.executable))
        #expect(sut.contains(.staticLibrary))
        #expect(sut.contains(.dynamicLibrary))
    }

    @Test(
        "ExpressibleByArgument - defaultValueDescription - returns product type description",
        arguments: ProductType.allCases
    )
    func expressibleByArgument_defaultValueDescription_returnsProductTypeDescription(type: ProductType) {
        // Given, When
        let sut = type

        // Then
        switch type {
            case .executable:
                #expect(sut.defaultValueDescription == "executable")
            case .library:
                #expect(sut.defaultValueDescription == "library")
            case .staticLibrary:
                #expect(sut.defaultValueDescription == "static-library")
            case .dynamicLibrary:
                #expect(sut.defaultValueDescription == "dynamic-library")
            case .plugin:
                #expect(sut.defaultValueDescription == "plugin")
        }
    }

    @Test("ExpressibleByArgument - allValueStrings - excludes plugin type")
    func expressibleByArgument_allValueStrings_excludesPluginType() {
        // Given, When
        let allValueStrings = ProductType.allValueStrings

        // Then
        #expect(allValueStrings.count == 4)
        #expect(allValueStrings.contains("executable"))
        #expect(allValueStrings.contains("library"))
        #expect(allValueStrings.contains("static-library"))
        #expect(allValueStrings.contains("dynamic-library"))
        #expect(!allValueStrings.contains("plugin"))
    }
}
