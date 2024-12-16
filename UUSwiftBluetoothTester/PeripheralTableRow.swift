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
    
    func update(peripheral: UUPeripheral)
    {
        friendlyNameLabel.text = peripheral.friendlyName
        idLabel.text = "\(peripheral.identifier)" //\nConnectable: \(peripheral.isConnectable)"
        rssiLabel.text = "\(peripheral.rssi ?? 0)"
        connectionStateLabel.text = UUCBPeripheralStateToString(peripheral.peripheralState)
        timeSinceLastUpdateLabel.text = String(format: "%.3f", peripheral.timeSinceLastUpdate)
        
        if let current = peripheral.advertisement?.timestamp
        {
            let fmt = "yyyy-MM-dd'T'HH:mm:ss.SSS"
            idLabel.text = "\(peripheral.firstDiscoveryTime.uuFormat(fmt, timeZone: .current))\n\(current.uuFormat(fmt, timeZone: .current))"
            
        }
        

    }
}
