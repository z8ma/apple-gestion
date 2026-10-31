// swift-tools-version: 6.2
// PeculeCore : logique métier pure (types valeur, Foundation uniquement).
// Testable sans simulateur ni SwiftData : `swift test` dans ce dossier.
import PackageDescription

let package = Package(
    name: "PeculeCore",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "PeculeCore", targets: ["PeculeCore"]),
    ],
    targets: [
        .target(name: "PeculeCore"),
        .testTarget(name: "PeculeCoreTests", dependencies: ["PeculeCore"]),
    ]
)
