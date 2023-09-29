//
//  OperationListController.swift
//  UUSwiftBluetoothTester
//
//  Created by Rhonda DeVore on 9/28/23.
//

import UIKit
import UUSwiftCore

class L2CapController:UIViewController, UITableViewDelegate, UITableViewDataSource
{
    var rightButton:UIBarButtonItem = UIBarButtonItem(title: "Action", image: nil, primaryAction: nil, menu: nil)

    var initialOutputline:String? = nil
    
    ///Adds a line of text to the tableview. If a method is passed, it logs the line as well
    func addOutputLine(_ line:String, _ method:String? = nil)
    {
        self.appendTableDataLine(line)
    }
    
    func addImageLine(image:UIImage)
    {
        self.appendTableDataLine(image)
    }
    
    //Adds or updates a row that states "47.5% Complete"
    func updateProgressRow(_ percent:Float)
    {
        DispatchQueue.main.async
        {
            if let _ = self.tableData.last as? Float
            {
                self.tableData[self.tableData.count - 1] = percent
                let indexPath = IndexPath(row: self.tableData.count - 1, section: 0)
                self.tableView.reloadRows(at: [indexPath], with: .none)
            }
            else
            {
                self.appendTableDataLine(percent)
            }
        }
        
    }
    
    private func appendTableDataLine(_ item:Any)
    {
        DispatchQueue.main.async
        {
            self.tableView.beginUpdates()
            
            self.tableData.append(item)
            
            let indexPath = IndexPath(row: self.tableData.count - 1, section: 0)
            
            self.tableView.insertRows(at: [indexPath], with: .bottom)
            self.tableView.endUpdates()
            
            self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
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
    
    func refreshMenu()
    {
        self.rightButton.menu = buildMenu()
    }
    
    open func buildMenu() -> UIMenu?
    {
        return nil
    }
    
    override func viewDidLoad() 
    {
        super.viewDidLoad()
        
        self.navigationItem.rightBarButtonItem = self.rightButton
        self.refreshMenu()
    }
    
    private var tableData:[Any] = []
    
    override func loadView() {
        super.loadView()
        
        self.view.backgroundColor = .white
        
        tableView.delegate = self
        tableView.dataSource = self
        
        self.view.addSubview(tableView)
        tableView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 5).isActive = true
        tableView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: 5).isActive = true
        tableView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: -5).isActive = true
        tableView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -5).isActive = true
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.uuClassName)
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = UITableView.automaticDimension

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
        content.text = data as? String
        content.image = data as? UIImage //Fill all the space because 
        
        if let progress = data as? Float
        {
            let prettyPercent = progress*100
            content.text = String(format: "%.2f%% Complete!", prettyPercent)
        }
        
        content.textProperties.font = UIFont.systemFont(ofSize: 12)
        content.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5)
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


class UUL2CapCommand:NSObject
{
    public enum Id:Int
    {
        case echo = 0x01
        case sendImage = 0x02
        case ackImage = 0x03
        
        static func fromUInt8(data:UInt8) -> Id?
        {
        
            switch data
            {
            case UInt8(Id.echo.rawValue):
                return .echo
            case UInt8(Id.sendImage.rawValue):
                return .sendImage
            default:
                return nil
            }
        }
    }
    
    private var bytesRecieved: Int = 0
    var totalExpectedBytes:Int = 0
    var commandId:Id
    var data:Data
    
    private init(commandId: Id)
    {
        self.commandId = commandId
        self.totalExpectedBytes = 0
        self.data = Data()
    }
    
    
    //appends to the data
    func appendBytes(_ incomingData:Data)
    {
        guard (!self.haveReceivedAllData()) else
        {
            NSLog("Tried to append \(incomingData.count) bytes but already have \(self.data.count) bytes of expected \(totalExpectedBytes)")
            return
        }
        
        let existingCount = self.data.count
        let requestedAdditionCount = data.count
        
        /*
        var adjustedData = data
        
        let preAdjustedCount = existingCount + requestedAdditionCount
        if (preAdjustedCount > totalExpectedBytes)
        {
            
            let remainingBytes = requestedAdditionCount - (preAdjustedCount - totalExpectedBytes)
            
            
            let indexToStart = 0
            if let loppedData = data.uuData(at: indexToStart, count: remainingBytes)
            {
                adjustedData = loppedData
                NSLog("Adjusting last chunk of data! Included only \(adjustedData.count) of \(data.count) bytes! (lopped chunk size: \(loppedData.count))")
            }
        }
        */
        
        bytesRecieved += incomingData.count
        
        self.data.append(incomingData)
        
        let previous = Int(bytesRecieved)
        //let adjustedCount = adjustedData.count
        
        //bytesRecieved += adjustedCount
                
        let complete:Float = percentageComplete()*100
        
        
        //NSLog("Recieved more data! (\(bytesRecieved)/\(totalExpectedBytes)) \(complete) :: AdjustedCount (\(incomingData.count)) : previousBytes (\(previous)) : updated: (\(bytesRecieved))")
        NSLog("Recieved more data! (\(bytesRecieved)/\(totalExpectedBytes)) \(complete)")
    }
    
    func haveReceivedAllData() -> Bool
    {
        return bytesRecieved >= totalExpectedBytes
    }
    
    func percentageComplete() -> Float
    {
        return ((totalExpectedBytes != 0) ? Float(bytesRecieved)/Float(totalExpectedBytes) : 0.0)
    }
    
    
    func toData() -> Data
    {
        var buffer = Data(capacity: UUL2CapCommand.headerSize + data.count)
                
        buffer.uuAppend(UInt8(0x55)) //U
        buffer.uuAppend(UInt8(0x55)) //U
        buffer.uuAppend(UInt8(0x42)) //B
        buffer.uuAppend(UInt8(0x6C)) //l
        buffer.uuAppend(UInt8(0x75)) //u
        buffer.uuAppend(UInt8(0x65)) //e
        buffer.uuAppend(UInt8(0x74)) //t
        buffer.uuAppend(UInt8(0x6F)) //o
        buffer.uuAppend(UInt8(0x6F)) //o
        buffer.uuAppend(UInt8(0x74)) //t
        buffer.uuAppend(UInt8(0x68)) //h
        buffer.uuAppend(UInt8(commandId.rawValue))
        buffer.uuAppend(UInt32(data.count))
        
        buffer.append(data)
        return buffer
    }
    
    
    
    static let headerSize = 16
    
    static func createToReceive(_ data:Data) -> UUL2CapCommand?
    {
        guard data.count > headerSize else
        {
            return nil
        }
        
        var index = 0
        
        let headerText = data.uuString(at: 0, count: 11, with: .utf8)
        guard (headerText == "UUBluetooth") else
        {
            NSLog("Header isn't for UUBluetooth, bailing!")
            return nil
        }
        
        
        index += headerText?.count ?? 0
        
        let commandByte = data.uuUInt8(at: index) ?? 0
        index += MemoryLayout<UInt8>.size
                
        guard let commandId = UUL2CapCommand.Id.fromUInt8(data: commandByte) else
        {
            return nil
        }
        
        let commandLength = data.uuUInt32(at: index)
        index += MemoryLayout<UInt32>.size

        let capacity = Int(commandLength ?? 0)
        NSLog("Creating L2CapCommand of size: \(capacity)")
        
//        let totalBytesExpectedWithHeader = capacity + UUL2CapCommand.headerSize
        
        let cmd = UUL2CapCommand(commandId: commandId)
        
        
        cmd.totalExpectedBytes = capacity
        
        if let cmdBytesLeft = data.uuData(at: index, count: data.count - index)
        {
            cmd.appendBytes(cmdBytesLeft)
        }
        
        return cmd
    }
    
    static func createToSend(_ commandId:UUL2CapCommand.Id, _ data:Data) -> UUL2CapCommand
    {
        let cmd = UUL2CapCommand(commandId: commandId)
        cmd.data = data
        return cmd
    }
}
