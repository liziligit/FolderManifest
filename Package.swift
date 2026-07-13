// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FolderManifest",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "FolderManifest", targets: ["FolderManifest"])
    ],
    targets: [
        .executableTarget(
            name: "FolderManifest",
            path: "Sources/FolderManifest"
        ),
        .testTarget(
            name: "FolderManifestTests",
            dependencies: ["FolderManifest"],
            path: "Tests/FolderManifestTests"
        )
    ]
)
