//
//  L2CapClientController.swift
//  UUSwiftBluetoothTester
//
//  Created by Rhonda DeVore on 9/14/23.
//

import UIKit
import CoreBluetooth
import UUSwiftBluetooth

class L2CapClientController:L2CapController
{
    var peripheral:UUPeripheral!
    {
        didSet
        {
            psm = UInt16(peripheral.localName.replacingOccurrences(of: "L2CapServer-", with: "")) ?? 0
        }
    }
    
    private var psm:UInt16 = 0
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.title = "L2Cap Client"
        
        self.configureLeftButton("Connect", connect)
//        self.configureMiddleButton("Open L2Cap", startChannel)
        self.configureRightButton("Ping", ping)
        
        
        self.initialOutputline = "Tap Connect to Begin"
        self.clearOutput()
    }
    
    func connect()
    {
        self.addOutputLine("Connecting...")
        self.peripheral.connect(timeout: UUPeripheral.Defaults.connectTimeout)
        {
            self.addOutputLine("Connected")
            self.startChannel()
            
        } disconnected:
        { error in
            
            self.addOutputLine("Disconnected. Error: \(self.errorDescription(error))")
        }

    }
    
    
    
    func startChannel()
    {
        self.addOutputLine("Opening L2CapChannel with psm \(self.psm)...")
        
        self.peripheral.openL2CapChannel(psm: self.psm)
        { numberOfBytesSent in
            
            self.addOutputLine("\(numberOfBytesSent) Bytes Sent!")
            
        } bytesReceivedCallback:
        { bytesReceived in
            
            if let rec = bytesReceived
            {
                self.addOutputLine("Recieved \(rec.count) bytes. Raw Bytes:\n\(rec.uuToHexString())\n")
            }
            else
            {
                self.addOutputLine("Received nil bytes!")
            }
            
        } completion:
        { channel, error in
            
            if let err = error
            {
                self.addOutputLine("Error: \(err)")
            }
            else if let _ = channel
            {
                self.addOutputLine("L2Cap Channel Connected!")
            }
            else
            {
                self.addOutputLine("L2Cap Channel connect attempt returned no error but no channel was created!")
            }
            
        }

    }
    
    func ping()
    {
        let tx = "4747474747"
        self.addOutputLine("TX: \(tx)")
        
        let data = Data(tx.uuToHexData() ?? NSData())
        self.peripheral.sendData(data)
        { error in
            
            self.addOutputLine("Data sent! Error: \(self.errorDescription(error))")
        }
    }
    
    
    
   
}





class L2CapController:UIViewController, UITableViewDelegate, UITableViewDataSource
{
    var initialOutputline:String? = nil
    
    ///Adds a line of text to the tableview. If a method is passed, it logs the line as well
    func addOutputLine(_ line:String, _ method:String? = nil)
    {
        DispatchQueue.main.async
        {
            self.tableView.beginUpdates()
            
            self.tableData.append(line)
            
            let indexPath = IndexPath(row: self.tableData.count - 1, section: 0)
            
            self.tableView.insertRows(at: [indexPath], with: .bottom)
            self.tableView.endUpdates()
            
            self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
            
            if let m = method
            {
                self.log(m, line)
            }
        }

    }
    
    func log(_ method:String, _ text:String)
    {
        NSLog("\(method) - \(text)")
    }
    
    ///Clears all tableview lines
    func clearOutput()
    {
        DispatchQueue.main.async
        {
            self.tableData.removeAll()
            
            if let initial = self.initialOutputline, !initial.isEmpty
            {
                self.tableData.append(initial)
            }
            
            self.tableView.reloadData()
        }
    }
    
    func configureLeftButton(_ title:String, _ action: @escaping (() -> Void))
    {
        configureButton(leftButton, title, action)
    }
    
    func configureMiddleButton(_ title:String, _ action: @escaping (() -> Void))
    {
        configureButton(middleButton, title, action)
    }
    
    func configureRightButton(_ title:String, _ action: @escaping (() -> Void))
    {
        configureButton(rightButton, title, action)
    }
    
    private func configureButton(_ button:UIButton, _ title:String, _ action: @escaping (() -> Void))
    {
        DispatchQueue.main.async
        {
            button.isHidden = false
            button.setTitle(title, for: .normal)
            button.addAction(UIAction( handler: { _ in action() }), for: .touchUpInside)
        }
    }
    
    private var tableData:[String] = []
    
    override func loadView() {
        super.loadView()
        
        self.view.backgroundColor = .white
        
        self.view.addSubview(leftButton)
        self.view.addSubview(middleButton)
        self.view.addSubview(rightButton)
        
        leftButton.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 5).isActive = true
        middleButton.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 5).isActive = true
        rightButton.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 5).isActive = true

        leftButton.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: 5).isActive = true
        rightButton.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: -5).isActive = true
        middleButton.leadingAnchor.constraint(equalTo: leftButton.trailingAnchor, constant: 5).isActive = true
        middleButton.trailingAnchor.constraint(equalTo: rightButton.leadingAnchor, constant: -5).isActive = true
        
        leftButton.widthAnchor.constraint(equalTo: middleButton.widthAnchor, multiplier: 1.0).isActive = true
        leftButton.widthAnchor.constraint(equalTo: rightButton.widthAnchor, multiplier: 1.0).isActive = true

        middleButton.widthAnchor.constraint(equalTo: leftButton.widthAnchor, multiplier: 1.0).isActive = true
        middleButton.widthAnchor.constraint(equalTo: rightButton.widthAnchor, multiplier: 1.0).isActive = true
        
        rightButton.widthAnchor.constraint(equalTo: leftButton.widthAnchor, multiplier: 1.0).isActive = true
        rightButton.widthAnchor.constraint(equalTo: middleButton.widthAnchor, multiplier: 1.0).isActive = true
        
        tableView.delegate = self
        tableView.dataSource = self
        
        self.view.addSubview(tableView)
        tableView.topAnchor.constraint(equalTo: leftButton.bottomAnchor, constant: 5).isActive = true
        tableView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: 5).isActive = true
        tableView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: -5).isActive = true
        tableView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -5).isActive = true
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.uuClassName)

    }
    
    private let leftButton:UIButton = {
        return createButton()
    }()
    
    private let middleButton:UIButton = {
        return createButton()
    }()
    
    private let rightButton:UIButton = {
        return createButton()
    }()
    
    private static func createButton() -> UIButton
    {
        let v = UIButton(type: .custom)
        v.translatesAutoresizingMaskIntoConstraints = false
        v.isHidden = true
        
        if #available(iOS 15, *)
        {
            v.setTitleColor(UIColor.tintColor, for: .normal)
        }
        else
        {
            v.setTitleColor(UIColor.systemBlue, for: .normal)
        }
        
        return v
    }
    
    private let tableView:UITableView = {
       let v = UITableView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .white
        return v
    }()
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return tableData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let data = tableData[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: UITableViewCell.uuClassName, for: indexPath)
        cell.selectionStyle = .none

        if #available(iOS 16, *)
        {
            var background = cell.defaultBackgroundConfiguration()
            background.backgroundColor = .white
            cell.backgroundConfiguration = background
        }
        else
        {
            cell.contentView.backgroundColor = .white
        }

        var content = cell.defaultContentConfiguration()
        content.text = data
        content.textProperties.font = UIFont.systemFont(ofSize: 12)
        cell.contentConfiguration = content
        
        return cell
    }
    
    func errorDescription(_ error:Error?) -> String
    {
        if let err = error
        {
            return "\(err)"
        }
        else
        {
            return "nil"
        }
    }
}
