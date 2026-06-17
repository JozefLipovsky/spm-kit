//
//  PackageDependency+Extensions.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2026-06-07.
//

import Core

package extension PackageDependency {
    static func targetStub(
        name: String = "TargetStub",
        type: PackageJSON.Target.TargetType = .regular
    ) throws -> PackageDependency {
        .target(try PackageJSON.Target.stub(name: name, type: type))
    }

    static func productStub(
        name: String = "ProductStub",
        type: PackageJSON.Product.ProductType = .library,
        packageName: String = "PackageStub"
    ) throws -> PackageDependency {
        .product(try PackageJSON.Product.stub(name: name, type: type), packageName: packageName)
    }
}
