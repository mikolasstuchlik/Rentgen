// swift-tools-version:5.3
import PackageDescription
let package = Package(
    name: "Rentgen",
    products: [
        .library(name: "Rentgen", targets: ["Rentgen"]),
        .executable(name: "RentgenPlayground", targets: ["RentgenPlayground"])
    ],
    targets: [
        .target(name: "Rentgen", dependencies: ["SwiftCRuntime"]),
        .target(name: "RentgenPlayground", dependencies: ["Rentgen"]),
        .target(name: "SwiftCRuntime"),
        .testTarget(name: "RentgenTests", dependencies: ["Rentgen"]),
    ]
)
