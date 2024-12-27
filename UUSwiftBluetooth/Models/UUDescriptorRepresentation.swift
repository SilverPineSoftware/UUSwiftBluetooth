//
//  UUDescriptorRepresentation.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 12/25/24.
//

import Foundation
import CoreBluetooth

/// A representation of a CoreBluetooth descriptor.
///
/// `UUDescriptorRepresentation` extends the `UUAttributeRepresentation` class to specifically model
/// Bluetooth descriptors (`CBDescriptor`) from the CoreBluetooth framework. It inherits properties
/// such as `uuid` and `name` to provide a lightweight representation of descriptors for serialization,
/// manipulation, or display.
///
public class UUDescriptorRepresentation: UUAttributeRepresentation
{
}
