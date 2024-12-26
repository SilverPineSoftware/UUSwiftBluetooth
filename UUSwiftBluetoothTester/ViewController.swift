//
//  ViewController.swift
//  UUSwiftBluetoothTester
//
//  Created by Ryan DeVore on 8/13/21.
//

import UIKit
import SwiftUI
import CoreBluetooth
import UUSwiftCore
import UUSwiftBluetooth

fileprivate let LOG_TAG = "UUSwiftBluetoothTester"

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource
{
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var rightNavBarItem: UIBarButtonItem!
    @IBOutlet weak var leftNavBarItem: UIBarButtonItem!
    
    private var tableData: [UUPeripheral] = []
    
    private var scanner = UUCoreBluetooth.defaultScanner
    
    private var lastTableUpdate: TimeInterval = 0
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
    }

    func numberOfSections(in tableView: UITableView) -> Int
    {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return tableData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "PeripheralTableRow", for: indexPath) as? PeripheralTableRow else
        {
            return UITableViewCell()
        }
        
        
        
        let rowData = tableData[indexPath.row]
        cell.update(peripheral: rowData)
        return cell
    }
   
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        let rowData = tableData[indexPath.row]
        showPeripheralOptions(rowData)
    }
    
    private var readInfoOperation: ReadDeviceInfoOperation? = nil
    
    private func showPeripheralOptions(_ peripheral: UUPeripheral)
    {
        let alert = UIAlertController(title: "\(peripheral.friendlyName)", message: "Choose an action", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Read Info", style: .default, handler:
        { action in
            
            self.readInfoOperation = ReadDeviceInfoOperation(peripheral)
            self.readInfoOperation?.start()
            { _, error in
                
                if let e = error
                {
                    self.showAlert("Read Device Info", "Error: \(e)")
                }
                else
                {
                    self.showAlert("Read Device Info", "SystemId: \(self.readInfoOperation?.systemId ?? "")\nMfg: \(self.readInfoOperation?.manufacturerName ?? "")")
                }
                
                self.readInfoOperation = nil
            }
        }))
        
        alert.addAction(UIAlertAction(title: "View Services", style: .default, handler:
        { action in
            
            let viewModel = PeripheralViewModel(peripheral)
            viewModel.serviceTapHandler = self.handleServiceTapped
            
            let view = PeripheralView(viewModel: viewModel)
            let host = UIHostingController(rootView: view)
            self.navigationController?.pushViewController(host, animated: true)
        }))
        
        alert.addAction(UIAlertAction(title: "Start L2Cap Client", style: .default, handler:
        { action in
            
            let vc = L2CapClientController()
            vc.peripheral = peripheral
            self.navigationController?.pushViewController(vc, animated: true)
            
            
        }))
        
        alert.addAction(UIAlertAction(title: "Connect", style: .default, handler:
        { action in
            
            //let vc = L2CapClientController()
            //vc.peripheral = peripheral
            //self.navigationController?.pushViewController(vc, animated: true)
            peripheral.connect(timeout: 30) {
                UULog.debug(tag: LOG_TAG, message: "Connected to \(peripheral.friendlyName)")
            } disconnected: { error in
                UULog.debug(tag: LOG_TAG, message: "Disconnected from \(peripheral.friendlyName)")
            }

            
            
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler:
        { action in
            alert.dismiss(animated: true, completion: nil)
        }))
        
        alert.addAction(UIAlertAction(title: "Export Peripheral", style: .default, handler:
        { action in
            let op = UUExportPeripheralOperation(peripheral)
            op.start
            { exportResult, err in
                //UULog.debug(tag: LOG_TAG, message: "op is done")
                
                if let result = exportResult
                {
                    UULog.debug(tag: LOG_TAG, message: "Export: \(result.uuToJsonString(true))")
                    self.saveExportedFile(peripheral, result)
                }
                else
                {
                    UULog.debug(tag: LOG_TAG, message: "Export failed: \(err?.localizedDescription ?? "")")
                }
            }
            
        }))
        
        present(alert, animated: true, completion: nil)
    }
    
    private func showAlert(_ title: String, _ message: String)
    {
        DispatchQueue.main.async
        {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler:
            { action in
                alert.dismiss(animated: true, completion: nil)
            }))
            
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    private func handleServiceTapped(_ peripheral: UUPeripheral, _ service: CBService)
    {
        let viewModel = ServiceViewModel(peripheral, service)
        let view = ServiceView(viewModel: viewModel)
        let host = UIHostingController(rootView: view)
        navigationController?.pushViewController(host, animated: true)
    }
    
    private func handleNearbyPeripheralsChanged(_ list: [UUPeripheral])
    {
        
        let logLine = list.compactMap { p in
            "\(p.friendlyName), \(p.rssi ?? -200), \(p.firstDiscoveryTime)"
        }.joined(separator: "\n")
        
        UULog.debug(tag: LOG_TAG, message: "Scan Results:\n\n\(logLine)\n\n")
        
        let now = Date().timeIntervalSinceReferenceDate
        let diff = now - lastTableUpdate
        if (diff > 1.0)
        {
            lastTableUpdate = now
            
            self.tableData.removeAll()
            self.tableData.append(contentsOf: list)
            
            DispatchQueue.main.async
            {
                self.tableView.reloadData()
            }
        }
    }
    
    
    
    @IBAction func onRightNavBarButtonTapped(_ sender: Any)
    {
        toggleScanning()
    }
    
    @IBAction func onLeftNavBarButtonTapped(_ sender: Any)
    {
       self.navigationController?.pushViewController(L2CapServerController(), animated: true)
        
//        let connected = UUCentralManager.shared.retrieveConnectedPeripherals(withServices: [])
//        UUDebugLog("Connected Peripherals: \(connected.count)")
//        for p in connected
//        {
//            UUDebugLog("Connected Peripheral: \(p.identifier) - \(p.name ?? "No Name")")
//        }
        
//        performSegue(withIdentifier: "showSettings", sender: nil)
    }
    
    private func toggleScanning()
    {
        if (scanner.isScanning)
        {
            scanner.stopScan()
            rightNavBarItem.title = "Scan"
        }
        else
        {
            let filters = [PeripheralFilter()]
            self.tableData.removeAll()
            self.tableView.reloadData()
            
            var settings = UUBluetoothScanSettings()
            settings.discoveryFilters = filters
            settings.allowDuplicates = true
            settings.peripheralSorting = UUPeripheralRssiSortComparator(order: .reverse)
            //settings.peripheralSorting = UUPeripheralFirstDiscoveryTimeComparator(order: .reverse)
            //settings.peripheralSorting = UUPeripheralFriendlyNameComparator(order: .reverse)
        
            
            UULog.debug(tag: LOG_TAG, message: "Starting scan")
            scanner.startScan(settings, callback: self.handleNearbyPeripheralsChanged)
            rightNavBarItem.title = "Stop"
        }
    }
    
    /*
    func exportService()
    {
        guard let p = model else { return }
        
        self.exportingPripheralProgressText = "Exporting\nPeripheral"
        self.isExportingPeripheral = true
        let op = UUExportPeripheralOperation(p)
        op.start
        { exportResult, exportError in
            
            if let result = exportResult
            {
                UULog.debug(tag: LOG_TAG, message: "Export: \(result.uuToJsonString(true))")
                self.saveExportedFile(p, result)
            }
            else
            {
                DispatchQueue.main.async
                {
                    self.isExportingPeripheral = false
                    self.exportError = exportError
                    self.exportErrorVisible = true
                }
            }
        }
    }*/
    
    private func saveExportedFile(_ peripheral: UUPeripheral, _ result: UUPeripheralModel)
    {
        let fileContents = result.uuToJsonString(true).data(using: .utf8)
        
        if let data = fileContents
        {
            let tempDir = FileManager.default.temporaryDirectory
            let timestamp = Date().uuFormat("yyyy_MM_dd_HH_mm_ss")
            let file = tempDir.appendingPathComponent("peripheral_export_\(timestamp).json")
            
            do
            {
                try data.write(to: file)
                
                DispatchQueue.main.async
                {
                    let vc = UIActivityViewController(activityItems: [file], applicationActivities: nil)
                    self.present(vc, animated: true)
                    
//                    self.isExportingPeripheral = false
//                    self.exportedFileUrl = file
//                    self.exportShareSheetVisible = true
                }
            }
            catch (let err)
            {
                UULog.debug(tag: LOG_TAG, message: "Error saving export to temporary file: \(String(describing: err))")
            }
        }
    }
}

//class CustomPeripheralFactory: UUPeripheralFactory<CustomPeripheral>
//{
//    public override init()
//    {
//        super.init()
//    }
//    
//    override func create(_ dispatchQueue: DispatchQueue, _ centralManager: UUCentralManager, _ peripheral: CBPeripheral) -> CustomPeripheral
//    {
//        return CustomPeripheral(dispatchQueue: dispatchQueue, centralManager: centralManager, peripheral: peripheral)
//    }
//}

class PeripheralFilter: UUPeripheralFilter
{
    func shouldDiscover(_ peripheral: UUPeripheral) -> Bool
    {
        if (peripheral.friendlyName.isEmpty)
        {
            return false
        }
        
        return true
    }
}
