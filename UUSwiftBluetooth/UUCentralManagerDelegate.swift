//
//  UUCentralManagerDelegate.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 8/13/21.
//

import UIKit
import CoreBluetooth
import UUSwiftCore

fileprivate let LOG_TAG = "UUCentralManagerDelegate"

class UUCentralManagerDelegate: NSObject, CBCentralManagerDelegate
{
    var centralStateChangedBlock: UUCentralStateChangedBlock? = nil
    var didDiscoverPeripheralBlock: UUBluetoothAdvertisementBlock? = nil
    var connectBlocks: [UUID: UUCBPeripheralBlock] = [:]
    var disconnectBlocks: [UUID: UUCBPeripheralErrorBlock] = [:]
    
    // MARK:- CBCentralManagerDelegate
    
    
    /**
     *  @method centralManagerDidUpdateState:
     *
     *  @param central  The central manager whose state has changed.
     *
     *  @discussion     Invoked whenever the central manager's state has been updated. Commands should only be issued when the state is
     *                  <code>CBCentralManagerStatePoweredOn</code>. A state below <code>CBCentralManagerStatePoweredOn</code>
     *                  implies that scanning has stopped and any connected peripherals have been disconnected. If the state moves below
     *                  <code>CBCentralManagerStatePoweredOff</code>, all <code>CBPeripheral</code> objects obtained from this central
     *                  manager become invalid and must be retrieved or discovered again.
     *
     *  @see            state
     *
     */
//    @available(iOS 5.0, *)
//    func centralManagerDidUpdateState(_ central: CBCentralManager)

    
    func centralManagerDidUpdateState(_ central: CBCentralManager)
    {
        UULog.info(tag: LOG_TAG, message: "Central state changed to \(UUCBManagerStateToString(central.state)) (\(central.state))")
        centralStateChangedBlock?(central.state)
    }
    
    /**
     *  @method centralManager:didDiscoverPeripheral:advertisementData:RSSI:
     *
     *  @param central              The central manager providing this update.
     *  @param peripheral           A <code>CBPeripheral</code> object.
     *  @param advertisementData    A dictionary containing any advertisement and scan response data.
     *  @param RSSI                 The current RSSI of <i>peripheral</i>, in dBm. A value of <code>127</code> is reserved and indicates the RSSI
     *                                was not available.
     *
     *  @discussion                 This method is invoked while scanning, upon the discovery of <i>peripheral</i> by <i>central</i>. A discovered peripheral must
     *                              be retained in order to use it; otherwise, it is assumed to not be of interest and will be cleaned up by the central manager. For
     *                              a list of <i>advertisementData</i> keys, see {@link CBAdvertisementDataLocalNameKey} and other similar constants.
     *
     *  @seealso                    CBAdvertisementData.h
     *
     */
//    @available(iOS 5.0, *)
//    optional func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber)

    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber)
    {
        guard let block = didDiscoverPeripheralBlock else
        {
            UULog.debug(tag: LOG_TAG, message: "No callback defined, Skipping peripheral: \(peripheral), RSSI: \(RSSI), advertisement: \(advertisementData)")
            return
        }
        
        UULog.debug(tag: LOG_TAG, message: "peripheral: \(peripheral), RSSI: \(RSSI), advertisement: \(advertisementData)")
        block(UUBluetoothAdvertisement(peripheral, advertisementData, RSSI.intValue))
        //peripheralFoundBlock?(peripheral, advertisementData, RSSI.intValue)
    }
    
    /**
     *  @method centralManager:didConnectPeripheral:
     *
     *  @param central      The central manager providing this information.
     *  @param peripheral   The <code>CBPeripheral</code> that has connected.
     *
     *  @discussion         This method is invoked when a connection initiated by {@link connectPeripheral:options:} has succeeded.
     *
     */
//    @available(iOS 5.0, *)
//    optional func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral)
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral)
    {
        UULog.debug(tag: LOG_TAG, message: "didConnect, peripheral: \(peripheral)")
        
        let key = peripheral.identifier
        let block = connectBlocks[key]
        connectBlocks.removeValue(forKey: key)
        block?(peripheral)
    }
    
    /**
     *  @method centralManager:didFailToConnectPeripheral:error:
     *
     *  @param central      The central manager providing this information.
     *  @param peripheral   The <code>CBPeripheral</code> that has failed to connect.
     *  @param error        The cause of the failure.
     *
     *  @discussion         This method is invoked when a connection initiated by {@link connectPeripheral:options:} has failed to complete. As connection attempts do not
     *                      timeout, the failure of a connection is atypical and usually indicative of a transient issue.
     *
     */
//    @available(iOS 5.0, *)
//    optional func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: (any Error)?)

    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?)
    {
        UULog.debug(tag: LOG_TAG, message: "didFailToConnect, peripheral: \(peripheral), error: \(String(describing: error?.localizedDescription))")
              
        let key = peripheral.identifier
        let block = disconnectBlocks[key]
        disconnectBlocks.removeValue(forKey: key)
        connectBlocks.removeValue(forKey: key)
        block?(peripheral, NSError.uuConnectionFailedError(error as NSError?))
    }
    
    /**
     *  @method centralManager:didDisconnectPeripheral:error:
     *
     *  @param central      The central manager providing this information.
     *  @param peripheral   The <code>CBPeripheral</code> that has disconnected.
     *  @param error        If an error occurred, the cause of the failure.
     *
     *  @discussion         This method is invoked upon the disconnection of a peripheral that was connected by {@link connectPeripheral:options:}. If the disconnection
     *                      was not initiated by {@link cancelPeripheralConnection}, the cause will be detailed in the <i>error</i> parameter. Once this method has been
     *                      called, no more methods will be invoked on <i>peripheral</i>'s <code>CBPeripheralDelegate</code>.
     *
     */
//    @available(iOS 5.0, *)
//    optional func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: (any Error)?)

    /*
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?)
    {
        UUDebugLog("didDisconnectPeripheral, peripheral: \(peripheral), error: \(String(describing: error))")
        
        let key = peripheral.identifier
        let block = disconnectBlocks[key]
        disconnectBlocks.removeValue(forKey: key)
        connectBlocks.removeValue(forKey: key)
        block?(peripheral, NSError.uuDisconnectedError(error as NSError?))
    }*/
    
    /**
     *  @method centralManager:didDisconnectPeripheral:timestamp:isReconnecting:error
     *
     *  @param central      The central manager providing this information.
     *  @param peripheral   The <code>CBPeripheral</code> that has disconnected.
     *  @param timestamp        Timestamp of the disconnection, it can be now or a few seconds ago.
     *  @param isReconnecting      If reconnect was triggered upon disconnection.
     *  @param error        If an error occurred, the cause of the failure.
     *
     *  @discussion         This method is invoked upon the disconnection of a peripheral that was connected by {@link connectPeripheral:options:}. If perihperal is
     *                      connected with connect option {@link CBConnectPeripheralOptionEnableAutoReconnect}, once this method has been called, the system
     *                      will automatically invoke connect to the peripheral. And if connection is established with the peripheral afterwards,
     *                      {@link centralManager:didConnectPeripheral:} can be invoked. If perihperal is connected without option
     *                      CBConnectPeripheralOptionEnableAutoReconnect, once this method has been called, no more methods will be invoked on
     *                       <i>peripheral</i>'s <code>CBPeripheralDelegate</code> .
     *
     */
//    @available(iOS 5.0, *)
//    optional func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, timestamp: CFAbsoluteTime, isReconnecting: Bool, error: (any Error)?)
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, timestamp: CFAbsoluteTime, isReconnecting: Bool, error: (any Error)?)
    {
        UULog.debug(tag: LOG_TAG, message: "didDisconnectPeripheral, peripheral: \(peripheral), timestamp: \(timestamp), isReconnecting: \(isReconnecting), error: \(String(describing: error))")
        
        if (isReconnecting)
        {
            UULog.debug(tag: LOG_TAG, message: "peripheral \(peripheral) is reconnecting, do not notify disconnect")
            return
        }
        
        let key = peripheral.identifier
        let block = disconnectBlocks[key]
        disconnectBlocks.removeValue(forKey: key)
        connectBlocks.removeValue(forKey: key)
        block?(peripheral, NSError.uuDisconnectedError(error as NSError?))
    }

    /**
     *  @method centralManager:connectionEventDidOccur:forPeripheral:
     *
     *  @param central      The central manager providing this information.
     *  @param event        The <code>CBConnectionEvent</code> that has occurred.
     *  @param peripheral   The <code>CBPeripheral</code> that caused the event.
     *
     *  @discussion         This method is invoked upon the connection or disconnection of a peripheral that matches any of the options provided in {@link registerForConnectionEventsWithOptions:}.
     *
     */
//    @available(iOS 13.0, *)
//    optional func centralManager(_ central: CBCentralManager, connectionEventDidOccur event: CBConnectionEvent, for peripheral: CBPeripheral)
    
    func centralManager(_ central: CBCentralManager, connectionEventDidOccur event: CBConnectionEvent, for peripheral: CBPeripheral)
    {
        UULog.debug(tag: LOG_TAG, message: "Connection event - peripheral: \(peripheral), event: \(event)")
    }

    /**
     *  @method centralManager:didUpdateANCSAuthorizationForPeripheral:
     *
     *  @param central      The central manager providing this information.
     *  @param peripheral   The <code>CBPeripheral</code> that caused the event.
     *
     *  @discussion         This method is invoked when the authorization status changes for a peripheral connected with {@link connectPeripheral:} option {@link CBConnectPeripheralOptionRequiresANCS}.
     *
     */
    //@available(iOS 13.0, *)
    //optional func centralManager(_ central: CBCentralManager, didUpdateANCSAuthorizationFor peripheral: CBPeripheral)
    
    func centralManager(_ central: CBCentralManager, didUpdateANCSAuthorizationFor peripheral: CBPeripheral)
    {
        UULog.debug(tag: LOG_TAG, message: "didUpdateANCSAuthorizationFor - peripheral: \(peripheral)")
    }
}

class UUCentralManagerRestoringDelegate: UUCentralManagerDelegate
{
    var willRestoreBlock: UUWillRestoreStateBlock? = nil
    
    /**
     *  @method centralManager:willRestoreState:
     *
     *  @param central      The central manager providing this information.
     *  @param dict            A dictionary containing information about <i>central</i> that was preserved by the system at the time the app was terminated.
     *
     *  @discussion            For apps that opt-in to state preservation and restoration, this is the first method invoked when your app is relaunched into
     *                        the background to complete some Bluetooth-related task. Use this method to synchronize your app's state with the state of the
     *                        Bluetooth system.
     *
     *  @seealso            CBCentralManagerRestoredStatePeripheralsKey;
     *  @seealso            CBCentralManagerRestoredStateScanServicesKey;
     *  @seealso            CBCentralManagerRestoredStateScanOptionsKey;
     *
     */
//    @available(iOS 5.0, *)
//    optional func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any])
    
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any])
    {
        UULog.debug(tag: LOG_TAG, message: "Restoring state, dict: \(dict)")
        willRestoreBlock?(dict)
    }
}

