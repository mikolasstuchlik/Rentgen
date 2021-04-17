// swift-tools-version:5.3
import PackageDescription
let package = Package(
    name: "Rentgen",
    products: [
        .library(name: "Rentgen", targets: ["Rentgen"]),
    ],
    targets: [
        .target(name: "Rentgen", dependencies: ["SwiftCRuntime"]),
        .target(name: "SwiftCRuntime"),
        .testTarget(name: "RentgenTests", dependencies: ["Rentgen"]),
    ]
)
