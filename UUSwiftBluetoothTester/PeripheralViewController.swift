//
//  PeripheralViewController.swift
//  UUSwiftBluetoothTester
//
//  Created by Ryan DeVore on 8/19/21.
//

import UIKit
import CoreBluetooth
import UUSwiftBluetooth

class HeaderButton
{
    var text: String = ""
    var enabled: Bool = true
    var action: (()->()) = { }
    
    required init(_ text: String, _ enabled: Bool, _ action: @escaping (()->()))
    {
        self.text = text
        self.action = action
        self.enabled = enabled
    }
}

class PeripheralViewController: UIViewController
{
    @IBOutlet weak var buttonCollectionView: UICollectionView!
    @IBOutlet weak var tableView: UITableView!
    
    private var buttons: [HeaderButton] = []
    
    var peripheral: UUPeripheral? = nil

    override func viewDidLoad() {
        super.viewDidLoad()

        refreshHeaderButtons()
    }
    
    private func refreshHeaderButtons()
    {
        buttons.removeAll()
        
        // Do any additional setup after loading the view.
        if (isConnected)
        {
            buttons.append(HeaderButton("Disonnect", true, onDisconnect))
            buttons.append(HeaderButton("Discover Services", true, onDiscoverServices))
            buttons.append(HeaderButton("Read RSSI", true, { }))
            //buttons.append(HeaderButton("Poll RSSI", true, { }))
            
        }
        else
        {
            buttons.append(HeaderButton("Connect", true, onConnect))
        }
        
        DispatchQueue.main.async
        {
            self.buttonCollectionView.reloadData()
        }
    }
    
    private var isConnected: Bool
    {
        guard let state = peripheral?.peripheralState else
        {
            return false
        }
        
        return state == .connected
    }
    
    private func onConnect()
    {
        if let p = peripheral
        {
            UUCoreBluetooth.shared.connectPeripheral(p, 60.0, 10.0) { p in
                NSLog("Connected!")
                self.refreshHeaderButtons()
            } _: { pp, e in
                NSLog("Disconnected!")
                self.refreshHeaderButtons()
            }

        }
    }
    
    private func onDisconnect()
    {
        
    }
    
    private func onDiscoverServices()
    {
        guard let peripheral = self.peripheral else
        {
            return
        }
        
        //peripheral
        peripheral.underlyingPeripheral.uuDiscoverServices(nil, 30.0)
        { updatedPeripheral, errOpt in
            
            NSLog("Service discovery complete")
            
            DispatchQueue.main.async
            {
                self.tableView.reloadData()
            }
        }
        
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension PeripheralViewController: UICollectionViewDataSource, UICollectionViewDelegate
{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        return buttons.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ButtonCollectionViewCell", for: indexPath) as? ButtonCollectionViewCell else
        {
            return UICollectionViewCell()
        }
        
        let button = buttons[indexPath.row]
        cell.update(button)
        return cell
    }
}

extension PeripheralViewController: UITableViewDataSource, UITableViewDelegate
{
    func numberOfSections(in tableView: UITableView) -> Int
    {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if (section == 0)
        {
            return 1
        }
        else if (section == 1)
        {
            return peripheral?.services?.count ?? 0
        }
        
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        guard let peripheral = self.peripheral else
        {
            return UITableViewCell()
        }
        
        if (indexPath.section == 0)
        {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "PeripheralInfoCell", for: indexPath) as? PeripheralInfoCell
            {
                cell.update(peripheral)
                return cell
            }
        }
        
        if (indexPath.section == 1)
        {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "PeripheralServiceCell", for: indexPath) as? PeripheralServiceCell,
               let services = peripheral.services
            {
                let rowData = services[indexPath.row]
                cell.update(rowData)
                return cell
            }
        }
        
        return UITableViewCell()
    }
}


class ButtonCollectionViewCell: UICollectionViewCell
{
    @IBOutlet weak var button: UIButton!
    
    private var model: HeaderButton? = nil
    
    func update(_ model: HeaderButton)
    {
        self.model = model
        self.button.setTitle(model.text, for: .normal)
        self.button.isEnabled = model.enabled
    }
    
    @IBAction func onButtonTap(_ sender: Any)
    {
        self.model?.action()
    }
}

class PeripheralInfoCell: UITableViewCell
{
    @IBOutlet weak var idLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var stateLabel: UILabel!
    @IBOutlet weak var rssiLabel: UILabel!
    
    func update(_ peripheral: UUPeripheral)
    {
        idLabel.text = "\(peripheral.identifier)"
        nameLabel.text = "\(peripheral.name)"
        stateLabel.text = UUCBPeripheralStateToString(peripheral.peripheralState)
        rssiLabel.text = "\(peripheral.rssi)"
    }
}

class PeripheralServiceCell: UITableViewCell
{
    @IBOutlet weak var label: UILabel!
    
    func update (_ service: CBService)
    {
        let uuidLabel = "UUID: "
        let nameLabel = "Name: "
        let isPrimaryLabel = "IsPrimary: "
        
        let boldParts = [uuidLabel, nameLabel, isPrimaryLabel]
        
        var lines: [String] = []
        lines.append("\(uuidLabel)\(service.uuid.uuidString)")
        lines.append("\(nameLabel)\(service.uuid.uuCommonName)")
        lines.append("\(isPrimaryLabel)\(service.isPrimary)")
        
        let text = lines.joined(separator: "\n")
        
        let mas = NSMutableAttributedString(string: text)
        
        let fontSize = CGFloat(16)
        let boldFont = UIFont.boldSystemFont(ofSize: fontSize)
        let normalFont = UIFont.systemFont(ofSize: fontSize)
        
        mas.addAttribute(.font, value: normalFont, range: NSMakeRange(0, text.count))
        
        for part in boldParts
        {
            let range = (text as NSString).range(of: part)
            mas.addAttribute(.font, value: boldFont, range: range)
        }
        
        label.attributedText = mas
    }
    
}
