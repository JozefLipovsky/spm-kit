//
//  Bundle.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2025-11-22.
//

import Dependencies
import Foundation

package extension DependencyValues {
    /// The bundle dependency used for accessing resources in a module.
    var bundle: Bundle {
        get { self[BundleKey.self] }
        set { self[BundleKey.self] = newValue }
    }

    private enum BundleKey: DependencyKey {
        static let liveValue = Bundle.module
        static let testValue = Bundle.module
    }
}
