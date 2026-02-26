// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "H3Swift",
    platforms: [
        .iOS(.v14),
        .macOS(.v11),
        .watchOS(.v7),
        .tvOS(.v14),
    ],
    products: [
        .library(
            name: "H3",
            targets: ["H3"]
        ),
        .executable(
            name: "basic-example",
            targets: ["BasicExample"]
        ),
        .executable(
            name: "advanced-example",
            targets: ["AdvancedExample"]
        ),
    ],
    targets: [
        // Vendored uber/h3 v4.4.1 C library
        .target(
            name: "Ch3",
            path: "Sources/Ch3",
            sources: [
                "algos.c",
                "baseCells.c",
                "bbox.c",
                "coordijk.c",
                "directedEdge.c",
                "faceijk.c",
                "h3Assert.c",
                "h3Index.c",
                "iterators.c",
                "latLng.c",
                "linkedGeo.c",
                "localij.c",
                "mathExtensions.c",
                "polyfill.c",
                "polygon.c",
                "vec2d.c",
                "vec3d.c",
                "vertex.c",
                "vertexGraph.c",
            ],
            publicHeadersPath: "include",
            cSettings: [
                // The C sources use #include "algos.h" etc. — these are internal headers
                .headerSearchPath("internal"),
                // Suppress warnings from vendored C code
                .unsafeFlags(["-w"]),
            ]
        ),
        .target(
            name: "H3",
            dependencies: ["Ch3"]
        ),
        .executableTarget(
            name: "BasicExample",
            dependencies: ["H3"],
            path: "Examples",
            sources: ["BasicExample.swift"]
        ),
        .executableTarget(
            name: "AdvancedExample",
            dependencies: ["H3"],
            path: "Examples",
            sources: ["AdvancedExample.swift"]
        ),
        .testTarget(
            name: "H3Tests",
            dependencies: ["H3"]
        ),
    ]
)
