// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "BCLVPNManager",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "BCLVPNManager",
            targets: ["BCLVPNManager"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/BrainCraftGIT/tunnelkit.git", branch: "expose-tunnelkitmanager")
    ],
    targets: [
        .target(
            name: "BCLVPNManager",
            dependencies: [
                .product(name: "TunnelKitManager", package: "TunnelKit"),
                .product(name: "TunnelKitOpenVPN", package: "TunnelKit"),
                .product(name: "TunnelKitOpenVPNAppExtension", package: "TunnelKit"),
                .product(name: "TunnelKitWireGuard", package: "TunnelKit"),
                .product(name: "TunnelKitWireGuardAppExtension", package: "TunnelKit")
            ],
            path: "Sources/BCLVPNManager",
            exclude: [],
            sources: [
                "OpenVPNConnectionManager.swift",
                "WireGuardConnectionManager.swift",
                "IKEv2ConnectionManager.swift"
            ],
            resources: []
        )
    ]
)
