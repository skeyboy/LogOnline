// swift-tools-version:4.0
import PackageDescription
#if os(macOS)
// macOS
let package = Package(
    name: "LogOnline",
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "3.0.0"),
        .package(url: "https://github.com/vapor/fluent-mysql.git", from: "3.0.1"),
        .package(url: "https://github.com/vapor/auth.git", from: "2.0.0"),
        .package(url: "https://github.com/vapor/leaf.git", from: "3.0.1"),
.package(url: "https://github.com/Alamofire/Alamofire.git", from: "4.0.0"),
         // 🔵 Swift ORM (queries, models, relations, etc) built on SQLite 3.
        .package(url: "https://github.com/vapor/fluent-sqlite.git", from: "3.0.0"),
//                .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.2.0"),
        //git@github.com:skeyboy/SwiftVaporPB.git SwiftVaporPB
//        .package(url: "https://github.com/apple/swift-protobuf.git", from: "0.0.1")
                    .package(url: "git@github.com:skeyboy/SwiftVaporPB.git", from: "0.0.1")

    ],
    targets: [
        .target(name: "App", dependencies: ["Leaf","Authentication","FluentSQLite","FluentMySQL", "Vapor","SwiftVaporPB"]),
        .target(name: "Run", dependencies: ["App"]),
         .testTarget(name: "AppTests", dependencies: ["App","Alamofire"])
      ]
)
#else

// Linux

let package = Package(
    name: "LogOnline",
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "3.0.0"),
        .package(url: "https://github.com/vapor/fluent-mysql.git", from: "3.0.1"),
        .package(url: "https://github.com/vapor/auth.git", from: "2.0.0"),
        .package(url: "https://github.com/vapor/leaf.git", from: "3.0.1"),
         // 🔵 Swift ORM (queries, models, relations, etc) built on SQLite 3.
        .package(url: "https://github.com/vapor/fluent-sqlite.git", from: "3.0.0"),
            .package(url: "git@github.com:skeyboy/SwiftVaporPB.git", from: "0.0.1")

    ],
    targets: [
        .target(name: "App", dependencies: ["Leaf","Authentication","FluentSQLite","FluentMySQL", "Vapor","SwiftVaporPB"]),
        .target(name: "Run", dependencies: ["App"]),
        .testTarget(name: "AppTests", dependencies: ["App" ])
    ]
)
#endif
