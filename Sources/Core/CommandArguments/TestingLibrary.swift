//
//  TestingLibrary.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2025-07-20.
//

import ArgumentParser

/// The testing library to use when generating test targets.
package enum TestingLibrary: String, CaseIterable, CustomStringConvertible, ExpressibleByArgument {
    /// The Swift Testing library.
    case swiftTesting = "swift-testing"
    /// The XCTest testing library.
    case xctest
    /// Do not generate a test target.
    case none

    /// CustomStringConvertible
    package var description: String { rawValue }
}
