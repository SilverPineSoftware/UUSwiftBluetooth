//
//  ViewController.swift
//  UUSwiftBluetoothTester
//
//  Created by Ryan DeVore on 8/13/21.
//

import UIKit
import UUSwiftBluetooth

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource
{
    @IBOutlet weak var tableView: UITableView!

    private var tableData: [UUPeripheral] = []
    
    //private var scanner = UUBluetoothScanner()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        let filters = [PeripheralFilter()]
        //scanner.startScanning(services: nil, allowDuplicates: false, peripheralClass: nil, filters: filters, callback: self.handleNearbyPeripheralsChanged)
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
    
    
    private func handleNearbyPeripheralsChanged(_ list: [UUPeripheral])
    {
        self.tableData.removeAll()
        self.tableData.append(contentsOf: list)
        
        DispatchQueue.main.async
        {
            self.tableView.reloadData()
        }
    }
    
    
}

class PeripheralFilter: NSObject, UUPeripheralFilter
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

