//
//  TargetType.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2025-07-20.
//

import ArgumentParser
import Foundation

/// The type of target to add.
package enum TargetType: String, CaseIterable, ExpressibleByArgument {
    /// A library target.
    case library
    /// An executable target.
    case executable
    /// A test target.
    case test
    /// A macro target.
    case macro
}
