// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let platforms: [SupportedPlatform] = [
	.macOS(.v10_12),
	.iOS(.v14),
	.tvOS(.v14)
	//.macCatalyst(.v14) // Needs swift-tools-version: 5.5 or later
]

let package = Package(
	name: "Bookmark",
	platforms: platforms,
	products: [
		// Products define the executables and libraries a package produces, and make them visible to other packages.
		.library(
			name: "Bookmark",
			targets: ["Bookmark"]),
	],
	dependencies: [
		// Dependencies declare other packages that this package depends on.
		// .package(url: /* package url */, from: "1.0.0"),
	],
	targets: [
		// Targets are the basic building blocks of a package. A target can define a module or a test suite.
		// Targets can depend on other targets in this package, and on products in packages this package depends on.
		.target(
			name: "Bookmark",
			dependencies: []),
		.testTarget(
			name: "BookmarkTests",
			dependencies: ["Bookmark"]),
	]
)
