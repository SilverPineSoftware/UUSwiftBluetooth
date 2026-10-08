//
//  UUCentralManagerOptions.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 9/30/26.
//

import CoreBluetooth

/// Startup options for a ``UUCentralManager``.
///
/// A ``UUBluetoothStack`` forwards these options to Core Bluetooth when it creates its central
/// manager. They do not take effect if changed after the manager has been created.
public struct UUCentralManagerOptions: Codable
{
    /// Whether Core Bluetooth shows an alert when Bluetooth service is unavailable.
    ///
    /// A value of `true` requests the alert; `false` suppresses it. `nil` omits the option and
    /// uses Core Bluetooth's default, which is `true`. This controls the power alert, not the
    /// Bluetooth authorization prompt.
    public var showPowerAlert: Bool?

    /// Stable identifier used by Core Bluetooth to restore this central manager's state.
    ///
    /// Provide a non-empty identifier to enable state restoration, and use the same identifier
    /// across app launches. Use a distinct identifier for each manager that needs independent
    /// restoration. `nil` leaves restoration disabled.
    public var stateRestorationIdentifier: String?

    /// Creates central manager options.
    /// - Parameters:
    ///   - showPowerAlert: Whether to show Core Bluetooth's alert when Bluetooth service is unavailable.
    ///     `nil` leaves the option unspecified and uses Core Bluetooth's default (`true`).
    ///   - stateRestorationIdentifier: A stable, non-empty identifier for Core Bluetooth state
    ///     restoration, or `nil` to leave restoration disabled.
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
