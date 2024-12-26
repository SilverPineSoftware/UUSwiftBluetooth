//
//  UUAttributeProtocol.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 12/25/24.
//

import Foundation
import CoreBluetooth

public protocol UUAttributeProtocol: Codable
{
    var uuid: String? { get set }
    var name: String? { get set }
}
