// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import class Foundation.ProcessInfo
import PackageDescription

func libraryType() -> PackageDescription.Product.Library.LibraryType?
{
    if let type = ProcessInfo.processInfo.environment["UU_LIBRARY_TYPE"]
    {
        if type == "static"
        {
            return .static
        }
        else if type == "dynamic"
        {
            return .dynamic
        }
    }

    return nil
}


let package = Package(
	name: "UUSwiftBluetooth",
	platforms: [
        .iOS(.v14),
        .macOS(.v13)
	],

	products: [
		// Products define the executables and libraries a package produces, and make them visible to other packages.
		.library(
			name: "UUSwiftBluetooth",
            type: libraryType(),
			targets: ["UUSwiftBluetooth"]),
	],

	dependencies: [
		// Here we define our package's external dependencies
		// and from where they can be fetched:
		.package(
            url: "https://github.com/SilverPineSoftware/UUSwiftCore.git",
            branch: "develop"
		)
	],

	targets: [
		.target(
            name: "UUSwiftBluetooth",
            dependencies: ["UUSwiftCore"],
            path: "UUSwiftBluetooth",
            exclude: ["Info.plist", "UnitTests"])
	],
    swiftLanguageModes: [
		.v4_2,
		.v5
	]
)
