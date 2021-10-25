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
    
    private var tableData: [UUPeripheral] = []
    
    private var scanner = UUBluetoothScanner(peripheralFactory:  CustomPeripheralFactory())
    
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
        
        let viewModel = PeripheralViewModel(rowData)
        viewModel.serviceTapHandler = handleServiceTapped
        
        let view = PeripheralView(viewModel: viewModel)
        let host = UIHostingController(rootView: view)
        navigationController?.pushViewController(host, animated: true)
    }
    
    private func handleServiceTapped(_ peripheral: UUPeripheral, _ service: CBService)
    {
        let viewModel = ServiceViewModel(peripheral, service)
        let view = ServiceView(viewModel: viewModel)
        let host = UIHostingController(rootView: view)
        navigationController?.pushViewController(host, animated: true)
    }
    
    private func handleNearbyPeripheralsChanged(_ list: [CustomPeripheral])
    {
        self.tableData.removeAll()
        self.tableData.append(contentsOf: list)
        
        DispatchQueue.main.async
        {
            self.tableView.reloadData()
        }
    }
    
    
    
    @IBAction func onRightNavBarButtonTapped(_ sender: Any)
    {
        toggleScanning()
    }
    
    @IBAction func onLeftNavBarButtonTapped(_ sender: Any)
    {
        performSegue(withIdentifier: "showSettings", sender: nil)
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
            scanner.startScan(services: nil, allowDuplicates: false, filters: filters, callback: self.handleNearbyPeripheralsChanged)
            rightNavBarItem.title = "Stop"
        }
    }
}

class CustomPeripheralFactory: UUPeripheralFactory<CustomPeripheral>
{
    public override init()
    {
        super.init()
    }
    
    override func create(_ dispatchQueue: DispatchQueue, _ centralManager: UUCentralManager, _ peripheral: CBPeripheral) -> CustomPeripheral
    {
        return CustomPeripheral(dispatchQueue, centralManager, peripheral)
    }
}

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

