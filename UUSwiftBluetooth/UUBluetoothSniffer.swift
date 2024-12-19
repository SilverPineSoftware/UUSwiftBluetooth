//
//  UUBluetoothSniffer.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 6/22/24.
//

import Foundation
import CoreBluetooth
import UUSwiftCore

class UUSnifferResult
{
    private let peripheral: CBPeripheral
    private let advertisementData: [String : Any]
    private let rssi: NSNumber
    
    var identifier: String
    {
        get
        {
            return peripheral.identifier.uuidString
        }
    }
    
    var name: String
    {
        get
        {
            return advertisementData.uuSafeGetString(CBAdvertisementDataLocalNameKey, "")
        }
    }
    
    var timestamp: TimeInterval
    {
        get
        {
            return advertisementData.uuSafeGetDouble("kCBAdvDataTimestamp", 0.0)
        }
    }
    
//    
//    /*!
//     *  @constant CBAdvertisementDataLocalNameKey
//     *
//     *  @discussion A <code>NSString</code> containing the local name of a peripheral.
//     *
//     */
//    CB_EXTERN NSString * const CBAdvertisementDataLocalNameKey;
//
//
//    /*!
//     *  @constant CBAdvertisementDataTxPowerLevelKey
//     *
//     *  @discussion A <code>NSNumber</code> containing the transmit power of a peripheral.
//     *
//     */
//    CB_EXTERN NSString * const CBAdvertisementDataTxPowerLevelKey;
//
//
//    /*!
//     *  @constant CBAdvertisementDataServiceUUIDsKey
//     *
//     *  @discussion A list of one or more <code>CBUUID</code> objects, representing <code>CBService</code> UUIDs.
//     *
//     */
//    CB_EXTERN NSString * const CBAdvertisementDataServiceUUIDsKey;
//
//
//    /*!
//     *  @constant CBAdvertisementDataServiceDataKey
//     *
//     *  @discussion A dictionary containing service-specific advertisement data. Keys are <code>CBUUID</code> objects, representing
//     *              <code>CBService</code> UUIDs. Values are <code>NSData</code> objects.
//     *
//     */
//    CB_EXTERN NSString * const CBAdvertisementDataServiceDataKey;
//
//
//    /*!
//     *  @constant CBAdvertisementDataManufacturerDataKey
//     *
//     *  @discussion A <code>NSData</code> object containing the manufacturer data of a peripheral.
//     *
//     */
//    CB_EXTERN NSString * const CBAdvertisementDataManufacturerDataKey;
//
//
//    /*!
//     *  @constant CBAdvertisementDataOverflowServiceUUIDsKey
//     *
//     *  @discussion A list of one or more <code>CBUUID</code> objects, representing <code>CBService</code> UUIDs that were
//     *              found in the "overflow" area of the advertising data. Due to the nature of the data stored in this area,
//     *              UUIDs listed here are "best effort" and may not always be accurate.
//     *
//     *  @see        startAdvertising:
//     *
//     */
//    CB_EXTERN NSString * const CBAdvertisementDataOverflowServiceUUIDsKey NS_AVAILABLE(10_9, 6_0);
//
//
//    /*!
//     *  @constant CBAdvertisementDataIsConnectable
//     *
//     *  @discussion An NSNumber (Boolean) indicating whether or not the advertising event type was connectable. This can be used to determine
//     *                whether or not a peripheral is connectable in that instant.
//     *
//     */
//    CB_EXTERN NSString * const CBAdvertisementDataIsConnectable NS_AVAILABLE(10_9, 7_0);
//
//
//    /*!
//     *  @constant CBAdvertisementDataSolicitedServiceUUIDsKey
//     *
//     *  @discussion A list of one or more <code>CBUUID</code> objects, representing <code>CBService</code> UUIDs.
//     *
//     */
//    CB_EXTERN NSString * const CBAdvertisementDataSolicitedServiceUUIDsKey NS_AVAILABLE(10_9, 7_0);

    
    var timestampDelta: Int64 = 0
    
    init(_ peripheral: CBPeripheral, _ advertisementData: [String : Any], _ rssi: NSNumber)
    {
        self.peripheral = peripheral
        self.advertisementData = advertisementData
        self.rssi = rssi
    }
    
    func csvLine() -> [String]
    {
        return [
            identifier,
            name,
            "\(rssi)",
            "\(advertisementData.count)",
            "\(Date(timeIntervalSinceReferenceDate: timestamp).uuFormat(UUDate.Formats.rfc3339WithMillis))",
            "\(timestampDelta)"
        ]
    }

    class func csvHeader() -> [String]
    {
        return [
            "mac",
            "name",
            "rssi",
            "scan_record_count",
            "timestamp",
            "timestamp_delta"
        ]
    } 
}

public class UUSnifferSessionSummary
{
    public let startTime = Date.timeIntervalSinceReferenceDate
    private(set) public var endTime: TimeInterval = 0
    private(set) var results: [UUSnifferResult] = []
    private var resultsLock = NSRecursiveLock()

    func end()
    {
        endTime = Date.timeIntervalSinceReferenceDate
    }

    func addResult(_ peripheral: CBPeripheral, _ advertisementData: [String : Any], _ rssi: NSNumber)
    {
        defer { resultsLock.unlock() }
        resultsLock.lock()
        
        results.append(UUSnifferResult(peripheral, advertisementData, rssi))
    }

    func calculateTimestampDeltas()
    {
        var times: [String:TimeInterval] = [:]

        results.forEach
        { result in
            
            if let lastTime = times[result.identifier]
            {
                result.timestampDelta = Int64((result.timestamp - lastTime) * UUDate.Constants.millisInOneSecond)
            }
            else
            {
                result.timestampDelta = 0
            }

            times[result.identifier] = result.timestamp
        }
    }

    public func print()
    {
        calculateTimestampDeltas()
        
        let header = UUSnifferResult.csvHeader()
        let lines = results.map { $0.csvLine() }
        
        UUDebugLog(header.joined(separator: ","))
        lines.forEach { parts in
            UUDebugLog(parts.joined(separator: ","))
        }
    }
    
    public func toCsvBytes() -> Data?
    {
        calculateTimestampDeltas()

        let header = UUSnifferResult.csvHeader()
        let lines = results.map { $0.csvLine() }

        var sb = header.joined(separator: ",")
        sb.append("\n")

        lines.forEach({ parts in
            sb.append(parts.joined(separator: ","))
            sb.append("\n")
        })
        
        return sb.data(using: .utf8)
    }
}

fileprivate class UUBluetoothSnifferDelegate: NSObject, CBCentralManagerDelegate
{
    var handleAdvertisement: ((CBPeripheral, [String : Any], NSNumber)->()) = { _,_,_ in }
    var handleStateChanged: ((CBManagerState)->()) = { _ in }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager)
    {
        handleStateChanged(central.state)
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber)
    {
        handleAdvertisement(peripheral, advertisementData, RSSI)
    }
}


public class UUBluetoothSniffer
{
    private let dispatchQueue: DispatchQueue
    private let delegate: UUBluetoothSnifferDelegate
    private let centralManager: CBCentralManager
    private var workingSummary = UUSnifferSessionSummary()
    private var startOnPowerOn = false
    private var services: [CBUUID]? = nil
    
    public init()
    {
        dispatchQueue = DispatchQueue(label: "UUBluetoothSnifferQueue", qos: .userInitiated, attributes: [], autoreleaseFrequency: .inherit, target: nil)
        delegate = UUBluetoothSnifferDelegate()
        centralManager = CBCentralManager(delegate: delegate, queue: dispatchQueue, options: nil)
        delegate.handleAdvertisement = handleAdvertisement
        delegate.handleStateChanged = handleStateChanged
    }
    
    private func handleStateChanged(_ state: CBManagerState)
    {
        if (state == CBManagerState.poweredOn)
        {
            if (startOnPowerOn)
            {
                start(services: services)
            }
        }
    }
    
    private func handleAdvertisement(_ peripheral: CBPeripheral, _ advertisementData: [String : Any], _ rssi: NSNumber)
    {
        //NSLog("\n\n\(advertisementData)\n\n")
        
        workingSummary.addResult(peripheral, advertisementData, rssi)
    }

    public func start(services: [CBUUID]? = nil)
    {
        if (centralManager.state != CBManagerState.poweredOn)
        {
            self.services = services
            startOnPowerOn = true
            return
        }
        
        startOnPowerOn = false
        workingSummary = UUSnifferSessionSummary()
        
        let opts: [String:Any] = [CBCentralManagerScanOptionAllowDuplicatesKey:true]
        centralManager.scanForPeripherals(withServices: services, options: opts)
    }

    public func stop() -> UUSnifferSessionSummary
    {
        centralManager.stopScan()
        workingSummary.end()
        return workingSummary
    }
}
