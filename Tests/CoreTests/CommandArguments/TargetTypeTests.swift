//
//  TargetTypeTests.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2025-07-20.
//

import Core
import TestHelpers
import Testing

@Suite("TargetType Tests", .tags(.unit))
struct TargetTypeTests {
    @Test("CaseIterable - contains all expected types")
    func caseIterable_containsAllExpectedTypes() {
        // Given, When
        let sut = TargetType.allCases

        // Then
        #expect(sut.count == 4)
        #expect(sut.contains(.library))
        #expect(sut.contains(.executable))
        #expect(sut.contains(.test))
        #expect(sut.contains(.macro))
    }

    @Test(
        "ExpressibleByArgument - defaultValueDescription - returns target type description",
        arguments: TargetType.allCases
    )
    func expressibleByArgument_defaultValueDescription_returnsTargetTypeDescription(type: TargetType) {
        // Given, When
        let sut = type

        // Then
        switch type {
            case .library:
                #expect(sut == .library)
            case .executable:
                #expect(sut == .executable)
            case .test:
                #expect(sut == .test)
            case .macro:
                #expect(sut == .macro)
        }
    }
}
