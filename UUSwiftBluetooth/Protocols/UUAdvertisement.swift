//
//  UUAdvertisement.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 12/16/24.
//

import UIKit
import CoreBluetooth

public protocol UUAdvertisement
{
    var identifier: UUID { get }
    var advertisementData: [String:Any] { get }
    var rssi: Int { get }
    var localName: String { get }
    var isConnectable: Bool { get }
    var manufacturingData: Data? { get }
    var transmitPower: Int? { get }
    var primaryPhy: Int? { get }
    var secondaryPhy: Int? { get }
    var timestamp: Date { get }
    var services: [CBUUID]? { get }
    var serviceData: [CBUUID: Data]? { get }
    var overflowServices: [CBUUID]? { get }
    var solicitedServices: [CBUUID]? { get }
}
