//
//  UUBluetoothAdvertisement.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 8/22/21.
//

import UIKit
import CoreBluetooth
import UUSwiftCore

// UUBluetoothAdvertisement wraps the data returned from the CoreBluetooth Api during BLE scanning.  Namely
// the peripheral, the advertisement data dictionary, and the signal strength (RSSI).
//
open class UUBluetoothAdvertisement
{
    private(set) var peripheral: CBPeripheral
    private(set) var advertisementData: [String:Any]? = nil
    private(set) var rssi: Int? = nil
    
    required public init(_ peripheral: CBPeripheral, _ advertisementData: [String:Any]?, _ rssi: Int?)
    {
        self.peripheral = peripheral
        self.advertisementData = advertisementData
        self.rssi = rssi
    }
}
