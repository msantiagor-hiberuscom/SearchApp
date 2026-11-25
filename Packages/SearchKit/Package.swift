// swift-tools-version: 6.0
import PackageDescription

// Layer dependencies:
//
//   Presentation ──▶ Domain ◀── Data
//
// Domain depends on nothing. The app target is the only one
// that knows all three layers and wires them together.
let package = Package(
    name: "SearchKit",
    platforms: [
        .iOS(.v18),
        .macOS(.v15), // lets `swift test` run without a simulator
    ],
    products: [
        .library(name: "Domain", targets: ["Domain"]),
        .library(name: "Data", targets: ["Data"]),
        .library(name: "Presentation", targets: ["Presentation"]),
    ],
    targets: [
        .target(name: "Domain"),
        .target(name: "Data", dependencies: ["Domain"]),
        .target(name: "Presentation", dependencies: ["Domain"]),

        .testTarget(name: "DomainTests", dependencies: ["Domain"]),
        .testTarget(name: "DataTests", dependencies: ["Data", "Domain"]),
        .testTarget(name: "PresentationTests", dependencies: ["Presentation", "Domain"]),
    ]
)
