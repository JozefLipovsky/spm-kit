//
//  PBXTarget+Extensions.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2025-11-13.
//

import Foundation
import XcodeProj

package extension PBXTarget {
    /// A set of UUIDs from the target and its related objects.
    /// - Returns: A set of UUID strings from the target and related objects.
    func propertyIdentifiers() -> Set<String> {
        var uuids: [String?] = []

        uuids.append(uuid)

        uuids.append(buildConfigurationList?.uuid)
        buildConfigurationList?.buildConfigurations.forEach { buildConfiguration in
            uuids.append(buildConfiguration.uuid)
            uuids.append(buildConfiguration.baseConfiguration?.uuid)
        }

        buildPhases.forEach { buildPhase in
            uuids.append(buildPhase.uuid)
            buildPhase.files?.forEach { buildPhaseFile in
                uuids.append(buildPhaseFile.uuid)
                uuids.append(buildPhaseFile.file?.uuid)
                uuids.append(buildPhaseFile.product?.uuid)
                uuids.append(buildPhaseFile.product?.package?.uuid)
            }
        }

        uuids.append(contentsOf: buildRules.compactMap(\.uuid))

        dependencies.forEach { dependency in
            uuids.append(dependency.uuid)
            uuids.append(dependency.product?.uuid)
            uuids.append(dependency.product?.package?.uuid)
            uuids.append(contentsOf: dependency.target?.propertyIdentifiers() ?? [])
            uuids.append(dependency.targetProxy?.uuid)
            switch dependency.targetProxy?.containerPortal {
                case .project(let project):
                    uuids.append(project.uuid)
                case .fileReference(let fileReference):
                    uuids.append(fileReference.uuid)
                case .unknownObject(let object):
                    uuids.append(object?.uuid)
                case .none:
                    break
            }
        }

        fileSystemSynchronizedGroups?.forEach { synchronizedGroup in
            uuids.append(synchronizedGroup.uuid)
            uuids.append(contentsOf: synchronizedGroup.exceptions?.map(\.uuid) ?? [])
        }

        packageProductDependencies?.forEach { productDependency in
            uuids.append(productDependency.uuid)
            uuids.append(productDependency.package?.uuid)
        }

        uuids.append(product?.uuid)

        return Set(uuids.compactMap { $0 })
    }

    /// A set of file paths associated with the target.
    /// - Returns: A set of file paths associated with the target.
    func filePaths() -> Set<String?> {
        var paths: Set<String?> = []
        paths.insert(product?.path)
        paths.formUnion(packageProductDependencies?.map(\.productName) ?? [])

        return paths
    }
}
