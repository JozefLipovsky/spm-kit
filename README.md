# spm-kit

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FJozefLipovsky%2Fspm-kit%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/JozefLipovsky/spm-kit)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FJozefLipovsky%2Fspm-kit%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/JozefLipovsky/spm-kit)
[![](https://github.com/JozefLipovsky/spm-kit/actions/workflows/test.yml/badge.svg)](https://github.com/JozefLipovsky/spm-kit/actions/workflows/test.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

spm-kit is a simple command-line tool built with Swift. It helps you create and maintain modular Xcode projects where most of the code lives in Swift Package Manager (SPM) modules.

## Table of Contents

- [Motivation](#motivation)
- [Features](#features)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Dependencies](#dependencies)

## Motivation

The tool was created to quickly bootstrap minimal projects for prototypes or projects. It was inspired by modular architectures shown in [Point-Free](https://www.pointfree.co) and [SwiftyStack](https://www.swiftystack.com) tutorials.

The goal is to provide a guided TUI experience. You don't need to remember specific arguments or look at help documentation. The tool uses interactive prompts to ask you simple questions and helps you set up your modular project or add a new module to the project with specific configuration.

Finally, I wanted to use this project as a playground to learn more about using Swift to build CLI tools. And to explore the latest tools and libraries like [Swift Dependencies](https://github.com/pointfreeco/swift-dependencies), [Noora](https://github.com/tuist/noora), [Swift Testing](https://github.com/swiftlang/swift-testing) etc..

## Features

```
spm-kit -h
OVERVIEW: A Swift command-line tool to manage SPM modular projects.

USAGE: spm-kit <subcommand>

OPTIONS:
  --version               Show the version.
  -h, --help              Show help information.

SUBCOMMANDS:
  bootstrap-project       Initializes a new, modular Swift Package Manager (SPM) based project.
  add-module              Adds a module to the current SPM project.

  See 'spm-kit help <subcommand>' for detailed help.
```

### Bootstrap Project

Creates a new modular project from scratch. It sets up:
- A minimal Xcode workspace with separate targets for each selected platform.
- A modular structure where all your code lives in a "Modules" folder managed by a single Swift Package.
- A root module that serves as the main entry point feature for all selected platforms.

Bootsraped project structure:
```text
.
├── MyProject.xcworkspace
├── App/
│   ├── MyProject.xcodeproj
│   ├── iOS/
│   │   ├── Assets.xcassets
│   │   └── iOSApp.swift
│   └── tvOS/
│       ├── Assets.xcassets
│       └── tvOSApp.swift
├── Modules/
│   ├── Package.swift
│   ├── Sources/
│   │   └── RootFeature/
│   │       └── RootFeatureView.swift
│   └── Tests/
│       └── RootFeatureTests/
│           └── RootFeatureTests.swift
├── .swift-format
└── spm-kit-config.yaml
```

> [!IMPORTANT]
> You will need to manually configure code signing for each platform target in Xcode after the project is created.

![00-code-signing](https://github.com/user-attachments/assets/e90122ff-e1c4-4af8-b8cd-d6a273879504)



```
spm-kit bootstrap-project -h
OVERVIEW: Initializes a new, modular Swift Package Manager (SPM) based project.

Initializes a new SPM project with maximum flexibility in configuration. Any of the project configuration and options values can
be provided via command-line arguments; missing values will be prompted for interactively.

USAGE: spm-kit bootstrap-project [<name>] [--company-domain <company-domain>] [--iOS <iOS>] [--macOS <macOS>] [--tvOS <tvOS>] [--visionOS <visionOS>] [--watchOS <watchOS>] [--root-module <root-module>] [--testing-library <testing-library>]

ARGUMENTS:
  <name>                  The name of the new project.

PROJECT PLATFORM(S) CONFIGURATION:
  --iOS <iOS>             Specify the iOS version. (e.g., v26) (values: v17, v18, v26)
  --macOS <macOS>         Specify the macOS version. (e.g., v26) (values: v14, v15, v26)
  --tvOS <tvOS>           Specify the tvOS version. (e.g., v26) (values: v17, v18, v26)
  --visionOS <visionOS>   Specify the visionOS version. (e.g., v26) (values: v1, v2, v26)
  --watchOS <watchOS>     Specify the watchOS version. (e.g., v26) (values: v10, v11, v26)

OPTIONS:
  --company-domain <company-domain>
                          The company domain or unique namespace that will be reversed and combined with the project name. For
                          example, 'example.com' becomes 'com.example' which is then combined with the project name to create the
                          bundle identifier in reverse DNS format 'com.example.projectName'.
  --root-module <root-module>
                          The name for the initial 'root' module of the project.
  --testing-library <testing-library>
                          The testing framework to use for the 'root' module tests. (values: swift-testing, xctest, none)
  --version               Show the version.
  -h, --help              Show help information.
```

### Add Module

Adds a new module to your existing project. It handles:
- Creating the folder structure and initial source files.
- Adding the module targets and products to the Swift Package manifest.
- Configuring internal or external dependencies for the new module.

```
spm-kit add-module -h
OVERVIEW: Adds a module to the current SPM project.

Creates and configures a new module, including its source files, targets, and products. Any of the module configuration and
options values can be provided via command-line arguments; missing values will be prompted for interactively.

USAGE: spm-kit add-module [<name>] [--product-type <product-type>] [--skip-dependencies] [--testing-library <testing-library>]

ARGUMENTS:
  <name>                  The name of the module to add.

OPTIONS:
  --product-type <product-type>
                          The product type to create for the module. (values: library, static-library, dynamic-library, executable)
  --skip-dependencies     Skip adding dependencies to the module.
  --testing-library <testing-library>
                          The testing library to use for the module. (values: swift-testing, xctest, none)
  --version               Show the version.
  -h, --help              Show help information.
```

## Installation

### Homebrew
```
brew install JozefLipovsky/tap/spm-kit
```

## Quick Start

You can use spm-kit in ~three~ four ways.

### Interactive Mode
Just run a command, and the tool will guide you through the configuration step-by-step.

```
spm-kit bootstrap-project
```
<video src="https://github.com/user-attachments/assets/12d982e9-5bff-41f1-add2-95d36e36563e" width="100%" autoplay muted playsinline></video>

```
spm-kit add-module
```
<video src="https://github.com/user-attachments/assets/255ce41a-163e-4331-84d0-a00d183e4e00" width="100%" playsinline></video>

### Hybrid Mode
Provide only the arguments you remember, and the tool will prompt you for the missing ones.

```
spm-kit bootstrap-project MyProject --iOS v26
```
<video src="https://github.com/user-attachments/assets/7da346d8-acfb-4034-aa80-6ffcf248cde6" width="100%" playsinline></video>

### Argument Mode
You can provide all required arguments using flags to skip interactive prompts entirely.

```
spm-kit add-module ThirdFeature --product-type library --testing-library xctest --skip-dependencies
```
<video src="https://github.com/user-attachments/assets/37447812-6021-4ef7-b273-99b8c05db075" width="100%" playsinline></video>

### LLM
An LLM of your choice should also be able to execute spm-kit commands.
<video src="https://github.com/user-attachments/assets/2d9669e4-d01f-4cfc-9a0e-f913dc1711c7" width="100%" playsinline></video>

## Configuration

spm-kit uses a `spm-kit-config.yaml` file to locate your project modules and configuration files.

```yaml
modules-path: Modules
swift-format-config-path: .swift-format
```

- `modules-path`: The relative path to your Swift Package directory.
- `swift-format-config-path`: The relative path to your `.swift-format` configuration.

## Dependencies

spm-kit is built using these open-source libraries:
- [ArgumentParser](https://github.com/apple/swift-argument-parser)
- [Noora](https://github.com/tuist/noora)
- [PathKit](https://github.com/kylef/PathKit)
- [Stencil](https://github.com/stencilproject/Stencil)
- [Swift Configuration](https://github.com/apple/swift-configuration)
- [Swift Dependencies](https://github.com/pointfreeco/swift-dependencies)
- [Swift Subprocess](https://github.com/swiftlang/swift-subprocess)
- [Swift Syntax](https://github.com/swiftlang/swift-syntax)
- [XcodeProj](https://github.com/tuist/xcodeproj)

And uses these tools behind the scenes:
- [swift package](https://www.swift.org/documentation/package-manager/)
- [swift-format](https://github.com/swiftlang/swift-format)
- [cp](https://www.gnu.org/software/coreutils/manual/coreutils.html#cp_003a-Copy-files-and-directories)
- [mv](https://www.gnu.org/software/coreutils/manual/coreutils.html#mv_003a-Move-_0028rename_0029-files)
