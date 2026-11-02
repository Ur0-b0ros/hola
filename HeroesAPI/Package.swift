
 // swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "HeroesAPI",
    dependencies: [
        .package(
            url: "https://github.com/httpswift/swifter.git",
            from: "1.5.0"
        )
    ],
    targets: [
        .executableTarget(
            name: "HeroesAPI",
            dependencies: [
                .product(name: "Swifter", package: "swifter")
            ]
        )
    ]
)
