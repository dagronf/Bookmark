// swift-tools-version: 5.4

import PackageDescription

let package = Package(
	name: "Bookmark",
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
