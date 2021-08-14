// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "UUSwiftBluetooth",
	platforms: [
		.iOS(.v10),
		.macOS(.v10_15)
	],

	products: [
		// Products define the executables and libraries a package produces, and make them visible to other packages.
		.library(
			name: "UUSwiftBluetooth",
			targets: ["UUSwiftBluetooth"]),
	],

	dependencies: [
		// Here we define our package's external dependencies
		// and from where they can be fetched:
		.package(
			url: "https://github.com/SilverPineSoftware/UUSwiftCore.git",
			from: "1.0.3"
		)
	],

	targets: [
		.target(
            name: "UUSwiftBluetooth",
            dependencies: ["UUSwiftCore"],
            path: "UUSwiftBluetooth",
            exclude: ["Info.plist"])
	],
	swiftLanguageVersions: [
		.v4_2,
		.v5
	]
)
