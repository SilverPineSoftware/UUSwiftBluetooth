//
//  UUCentralManagerOptions.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 9/30/26.
//

import CoreBluetooth

public struct UUCentralManagerOptions: Codable
{
    public var showPowerAlert: Bool?
    public var stateRestorationIdentifier: String?

    public init(
        showPowerAlert: Bool? = nil,
        stateRestorationIdentifier: String? = nil
    )
    {
        self.showPowerAlert = showPowerAlert
        self.stateRestorationIdentifier = stateRestorationIdentifier
    }

    var coreBluetoothOptions: [String: Any]?
    {
        var result: [String: Any] = [:]

        if let showPowerAlert = showPowerAlert
        {
            result[CBCentralManagerOptionShowPowerAlertKey] = showPowerAlert
        }
        
        if let identifier = stateRestorationIdentifier
        {
            result[CBCentralManagerOptionRestoreIdentifierKey] = identifier
        }

        return result.isEmpty ? nil : result
    }
    
    var usesStateRestoration: Bool
    {
        guard let identifier = stateRestorationIdentifier else
        {
            return false
        }
        
        return !identifier.isEmpty
    }
}
