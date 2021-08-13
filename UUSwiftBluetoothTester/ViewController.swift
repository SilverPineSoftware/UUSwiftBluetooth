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
    private var nearbyDevices: [String:UUPeripheral] = [:]
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        UUCoreBluetooth.sharedInstance().startScan(forServices: nil, allowDuplicates: false, peripheralClass: UUPeripheral.classForCoder(), filters: nil)
        { peripheral in
            
            self.nearbyDevices[peripheral.identifier] = peripheral
            self.tableData.removeAll()
            
            for p in self.nearbyDevices
            {
                self.tableData.append(p.value)
            }
            
            DispatchQueue.main.async
            {
                self.tableView.reloadData()
            }
            
            
        } willRestoreStateCallback: { args in
            
        }

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
}

