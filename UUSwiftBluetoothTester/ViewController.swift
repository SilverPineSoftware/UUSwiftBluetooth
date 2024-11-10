//
//  ViewController.swift
//  UUSwiftBluetoothTester
//
//  Created by Ryan DeVore on 8/13/21.
//

import UIKit
import SwiftUI
import CoreBluetooth
import UUSwiftBluetooth

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource
{
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var rightNavBarItem: UIBarButtonItem!
    @IBOutlet weak var leftNavBarItem: UIBarButtonItem!
    
    private var tableData: [any UUPeripheral] = []
    
    private var scanner = UUBluetoothScanner()
    
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
    
    private func showPeripheralOptions(_ peripheral: any UUPeripheral)
    {
        let alert = UIAlertController(title: "\(peripheral.friendlyName)", message: "Choose an action", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Read Info", style: .default, handler:
        { action in
            
            self.readInfoOperation = ReadDeviceInfoOperation(peripheral)
            self.readInfoOperation?.start()
            { error in
                
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
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler:
        { action in
            alert.dismiss(animated: true, completion: nil)
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
    
    private func handleServiceTapped(_ peripheral: any UUPeripheral, _ service: CBService)
    {
        let viewModel = ServiceViewModel(peripheral, service)
        let view = ServiceView(viewModel: viewModel)
        let host = UIHostingController(rootView: view)
        navigationController?.pushViewController(host, animated: true)
    }
    
    private func handleNearbyPeripheralsChanged(_ list: [any UUPeripheral])
    {
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
            let outOfRangeFilters = [OutOfRangePeripheralFilter()]
            self.tableData.removeAll()
            self.tableView.reloadData()
            
            let settings = UUBluetoothScanSettings(
                filters: filters,
                outOfRangeFilters: outOfRangeFilters)
            
            scanner.startScan(settings, callback: self.handleNearbyPeripheralsChanged)
            rightNavBarItem.title = "Stop"
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
    func shouldDiscover(_ peripheral: any UUPeripheral) -> Bool
    {
        if (peripheral.friendlyName.isEmpty)
        {
            return false
        }
        
        return true
    }
}

class OutOfRangePeripheralFilter: UUOutOfRangePeripheralFilter
{
    func checkPeripheralRange(_ peripheral: any UUPeripheral) -> UUOutOfRangePeripheralFilterResult
    {
        if (peripheral.timeSinceLastUpdate > 0.5)
        {
            return .outOfRange
        }
        else
        {
            return .inRange
        }
    }
}
