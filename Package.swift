// swift-tools-version: 5.5

import PackageDescription

let platforms: [SupportedPlatform] = [
	.macOS(.v10_13),
	.iOS(.v14),
	.tvOS(.v14),
	.watchOS(.v7),
	.macCatalyst(.v14)
]

let package = Package(
	name: "Bookmark",
	platforms: platforms,
	products: [
		.library(name: "Bookmark", targets: ["Bookmark"]),
	],
	targets: [
		.target(
			name: "Bookmark",
			dependencies: []),
		.testTarget(
			name: "BookmarkTests",
			dependencies: ["Bookmark"]),
	]
)
