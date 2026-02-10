//
//  TestingLibraryTests.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2025-07-20.
//

import Core
import TestHelpers
import Testing

@Suite("TestingLibrary Tests", .tags(.unit))
struct TestingLibraryTests {
    @Test("CaseIterable - contains all expected libraries")
    func caseIterable_containsAllExpectedLibraries() {
        // Given, When
        let sut = TestingLibrary.allCases

        // Then
        #expect(sut.count == 3)
        #expect(sut.contains(.swiftTesting))
        #expect(sut.contains(.xctest))
        #expect(sut.contains(.none))
    }

    @Test(
        "ExpressibleByArgument - defaultValueDescription - returns testing library description",
        arguments: TestingLibrary.allCases
    )
    func expressibleByArgument_defaultValueDescription_returnsDescription(library: TestingLibrary) {
        // Given, When
        let sut = library

        // Then
        switch library {
            case .swiftTesting:
                #expect(sut.defaultValueDescription == "swift-testing")
            case .xctest:
                #expect(sut.defaultValueDescription == "xctest")
            case .none:
                #expect(sut.defaultValueDescription == "none")
        }
    }

    @Test(
        "CustomStringConvertible - description - returns testing library description",
        arguments: TestingLibrary.allCases
    )
    func customStringConvertible_description_returnsDescription(library: TestingLibrary) {
        // Given, When
        let sut = library

        // Then
        switch library {
            case .swiftTesting:
                #expect(sut.description == "swift-testing")
            case .xctest:
                #expect(sut.description == "xctest")
            case .none:
                #expect(sut.description == "none")
        }
    }
}
