// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NotesAudioDomain",
    platforms: [.iOS(.v17), .macOS(.v13)],
    products: [.library(name: "NotesAudioDomain", targets: ["NotesAudioDomain"])],
    targets: [
        .target(name: "NotesAudioDomain"),
        .testTarget(name: "NotesAudioDomainTests", dependencies: ["NotesAudioDomain"])
    ]
)
