// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
  name: "Orcam",
  platforms: [.macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6), .macCatalyst(.v13)],
  products: [
    .library(
      name: "Orcam",
      targets: ["Orcam"]
    ),
    .executable(
      name: "OrcamClient",
      targets: ["OrcamClient"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0"),
    .package(url: "https://github.com/stackotter/swift-macro-toolkit.git", from: "0.3.1"),
  ],
  targets: [
    .macro(
      name: "OrcamImpl",
      dependencies: [
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
        .product(name: "MacroToolkit", package: "swift-macro-toolkit"),
      ]
    ),

    .target(name: "Orcam", dependencies: ["OrcamImpl"]),
    .executableTarget(name: "OrcamClient", dependencies: ["Orcam"]),
    .testTarget(
      name: "OrcamTests",
      dependencies: [
        "OrcamImpl",
        .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
      ]
    ),
  ]
)
