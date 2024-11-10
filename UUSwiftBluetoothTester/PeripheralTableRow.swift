//
//  PeripheralTableRow.swift
//  UUSwiftBluetoothTester
//
//  Created by Ryan DeVore on 8/13/21.
//

import UIKit
import UUSwiftBluetooth

class PeripheralTableRow: UITableViewCell
{
    @IBOutlet weak var friendlyNameLabel: UILabel!
    @IBOutlet weak var idLabel: UILabel!
    @IBOutlet weak var rssiLabel: UILabel!
    @IBOutlet weak var connectionStateLabel: UILabel!
    @IBOutlet weak var timeSinceLastUpdateLabel: UILabel!
    
    func update(peripheral: any UUPeripheral)
    {
        friendlyNameLabel.text = peripheral.friendlyName
        idLabel.text = "\(peripheral.identifier)\nConnectable: \(peripheral.isConnectable)"
        rssiLabel.text = "\(peripheral.rssi)"
        connectionStateLabel.text = UUCBPeripheralStateToString(peripheral.peripheralState);
        timeSinceLastUpdateLabel.text = String(format: "%.3f", Date().timeIntervalSince(peripheral.lastAdvertisementTime))

    }
}
