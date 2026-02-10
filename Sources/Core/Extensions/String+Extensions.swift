//
//  String+Extensions.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2025-08-17.
//

import Foundation
import PathKit

package extension String {
    /// The string represented as a `PathKit.Path`.
    var path: Path {
        Path(self)
    }
}
