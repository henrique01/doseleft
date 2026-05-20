// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DoseCore",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10),
        .macOS(.v14),
    ],
    products: [
        .library(name: "DoseCore", targets: ["DoseCore"]),
    ],
    targets: [
        .target(
            name: "DoseCore",
            path: "Sources/DoseCore"
        ),
        .testTarget(
            name: "DoseCoreTests",
            dependencies: ["DoseCore"],
            path: "Tests/DoseCoreTests"
        ),
    ]
)
