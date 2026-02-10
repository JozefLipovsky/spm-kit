//
//  PathClient.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2025-08-10.
//

import Dependencies
import DependenciesMacros
import IssueReporting
import PathKit

/// A client for interacting with file paths.
@DependencyClient
package struct PathClient: Sendable {
    /// Returns the current working directory.
    package var current: @Sendable () throws -> Path
}

extension PathClient: DependencyKey {
    /// The live implementation of `PathClient`.
    package static var liveValue: Self {
        Self(current: { Path.current })
    }
}

package extension DependencyValues {
    /// A client for interacting with file paths.
    var pathClient: PathClient {
        get { self[PathClient.self] }
        set { self[PathClient.self] = newValue }
    }
}
