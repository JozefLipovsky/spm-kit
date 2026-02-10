//
//  TemplateType.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2025-11-22.
//

import Foundation

/// Represents the type of template used in the project.
package enum TemplateType: Equatable {
    /// A template for a root module view file.
    case rootModuleView
    /// A template for an Xcode project.
    case xcodeProject
    /// A template for the SPM Kit configuration.
    case spmKitConfig
    /// A template for the Swift format configuration.
    case swiftFormatConfig

    /// The resource name for the template type.
    package var resource: String {
        switch self {
            case .rootModuleView:
                return "RootModuleView"
            case .xcodeProject:
                return "XcodeProject"
            case .spmKitConfig:
                return "spm-kit-config"
            case .swiftFormatConfig:
                return ".swift-format"
        }
    }

    /// The file extension for the template type.
    package var resourceExtension: String? {
        switch self {
            case .rootModuleView:
                return "swift"
            case .xcodeProject:
                return nil
            case .spmKitConfig:
                return "yaml"
            case .swiftFormatConfig:
                return nil
        }
    }

    /// The subdirectory where the template is located.
    package var subdirectory: String {
        "_Templates/Bootstrap"
    }
}
