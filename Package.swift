// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "tile-control-for-obs",
    platforms: [
        .macOS(.v13)
    ],
    products: [
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/didactek/deft-log.git", from: "1.0.0"),
        .package(url: "https://github.com/didactek/deft-midi-control.git", from: "1.0.0"),
        .package(url: "https://github.com/didactek/obs-websocket-client.git", from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .executableTarget(
            name: "OBSurface",
            dependencies: [
                .product(name: "OBSAsyncAPI", package: "obs-websocket-client"),
                .product(name: "MCSurface", package: "deft-midi-control"),
                .product(name: "DeftLog", package: "deft-log"),
            ]
        ),
    ]
)
