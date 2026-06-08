//
//  PackageJSON+Extensions.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2026-06-07.
//

import Core
import Foundation

package extension PackageJSON.Product {
    static func stub(name: String = "ProductStub", type: ProductType = .library) throws -> PackageJSON.Product {
        let data = Data(
            """
            {
                "name": "\(name)",
                "type": { "\(type.rawValue)": {} }
            }
            """.utf8
        )

        return try JSONDecoder().decode(PackageJSON.Product.self, from: data)
    }
}

package extension PackageJSON.Target {
    static func stub(name: String = "TargetStub", type: TargetType = .regular) throws -> PackageJSON.Target {
        let data = Data(
            """
            {
                "name": "\(name)",
                "type": "\(type.rawValue)"
            }
            """.utf8
        )

        return try JSONDecoder().decode(PackageJSON.Target.self, from: data)
    }
}
