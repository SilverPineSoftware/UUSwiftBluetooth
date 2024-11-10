//
//  CharacteristicRowView.swift
//  UUSwiftBluetoothTester
//
//  Created by Ryan DeVore on 9/9/21.
//

import SwiftUI
import CoreBluetooth
import UUSwiftBluetooth

class CharacteristicRowViewModel: ObservableObject
{
    var peripheral: any UUPeripheral
    @Published var characteristic: CBCharacteristic
    @Published var showDivider: Bool
    
//    @Published var isNotifying: Bool
//    {
//        willSet
//        {
//            NSLog("isNotifying changing to: \(newValue)")
//        }
//    }
    
    @Published var canEditText: Bool
    @Published var editText: String
    
    enum DataDisplayType: Int, CaseIterable
    {
        case hex = 0
        case utf8 = 1
    }
    
    @Published var dataDisplay: Int
    {
        didSet
        {
            self.editText = dataAsText
        }
    }

    
    init(_ peripheral: any UUPeripheral, _ characteristic: CBCharacteristic, showDivider: Bool = false)
    {
        self.peripheral = peripheral
        self.characteristic = characteristic
        self.showDivider = showDivider
        //self.isNotifying = characteristic.isNotifying
        self.dataDisplay = DataDisplayType.hex.rawValue
        self.canEditText = (characteristic.uuCanWriteData || characteristic.uuCanWriteWithoutResponse)
        self.editText = characteristic.value?.uuToHexString() ?? ""
    }
    
    private func updateDerivedProperties()
    {
        //self.isNotifying = characteristic.isNotifying
        self.canEditText = (characteristic.uuCanWriteData || characteristic.uuCanWriteWithoutResponse)
        self.editText = characteristic.value?.uuToHexString() ?? ""
    }
    
    private var dataAsText: String
    {
        guard let data = characteristic.value else
        {
            return ""
        }
        
        if (dataDisplay == DataDisplayType.utf8.rawValue)
        {
            return String(data: data, encoding: .utf8) ?? ""
        }
        
        return data.uuToHexString()
    }
    
    private var editTextAsData: Data?
    {
        if (dataDisplay == DataDisplayType.utf8.rawValue)
        {
            return editText.data(using: .utf8)
        }
        
        return editText.uuToHexData() as Data?
    }
    
    func onToggleNotify()
    {
        peripheral.setNotifyValue(enabled: !characteristic.isNotifying, for: characteristic, timeout: 20.0)
        { updatedPeripheral, updatedCharacteristic, errOpt in
            
            NSLog("Characteristic \(updatedCharacteristic.uuid.uuidString) value changed to \(updatedCharacteristic.value?.uuToHexString() ?? "<nil>")")
            DispatchQueue.main.async
            {
                self.peripheral = updatedPeripheral
                self.characteristic = updatedCharacteristic
                self.editText = self.dataAsText
            }
            
        } completion:
        { updatedPeripheral, updatedCharacteristic, errOpt in
            
            DispatchQueue.main.async
            {
                self.peripheral = updatedPeripheral
                self.characteristic = updatedCharacteristic
                self.editText = self.dataAsText
            }
        }
    }
    
    func onReadData()
    {
        peripheral.readValue(for: characteristic, timeout: 20.0)
        { updatedPeripheral, updatedCharacteristic, errOpt in
            
            DispatchQueue.main.async
            {
                self.peripheral = updatedPeripheral
                self.characteristic = updatedCharacteristic
                self.editText = self.dataAsText
            }
        }
    }
    
    func onWriteData()
    {
        if let data = editTextAsData
        {
            peripheral.writeValue(data: data, for: characteristic, timeout: 20.0)
            { updatedPeripheral, updatedCharacteristic, errOpt in
                
                DispatchQueue.main.async
                {
                    self.peripheral = updatedPeripheral
                    self.characteristic = updatedCharacteristic
                    self.editText = self.dataAsText
                }
            }
        }
    }
    
    func onWriteWithoutResponse()
    {
        if let data = editTextAsData
        {
            peripheral.writeValueWithoutResponse(data: data, for: characteristic)
            { updatedPeripheral, updatedCharacteristic, errOpt in
                
                DispatchQueue.main.async
                {
                    self.peripheral = updatedPeripheral
                    self.characteristic = updatedCharacteristic
                    self.editText = self.dataAsText
                }
            }
        }
    }
    
    
}

struct CharacteristicRowView: View
{
    @ObservedObject var viewModel: CharacteristicRowViewModel
    
    var body: some View
    {
        VStack
        {
            LabelValueRowView(label: "UUID:", value: viewModel.characteristic.uuid.uuidString)
            LabelValueRowView(label: "Name:", value: viewModel.characteristic.uuid.uuCommonName)
            
            // Properties
            HStack
            {
                Text("Properties:")
                    .bold()
                
                Spacer()
            }
            .padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
            
            HStack
            {
                Text(UUCBCharacteristicPropertiesToString(viewModel.characteristic.properties))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                
                Spacer()
            }
            .padding(EdgeInsets(top: 0, leading: 40, bottom: 0, trailing: 20))
            
            LabelValueRowView(label: "IsNotifying:", value: "\(viewModel.characteristic.isNotifying ? "Yes" : "No")")
            
            /*
            HStack
            {
                Toggle("IsNotifying:", isOn: $viewModel.isNotifying)
                    .disabled(!viewModel.characteristic.uuCanToggleNotify)
                    .allowsHitTesting(viewModel.characteristic.uuCanToggleNotify)
            }
            .padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
            */
            
            HStack
            {
                Text("Data:")
                    .bold()
                
                Spacer()
                
                Picker("", selection: $viewModel.dataDisplay)
                {
                    Text("hex").tag(CharacteristicRowViewModel.DataDisplayType.hex.rawValue)
                    Text("utf8").tag(CharacteristicRowViewModel.DataDisplayType.utf8.rawValue)
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 150)
            }
            .padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
            
            HStack
            {
                TextEditor(text: $viewModel.editText)
                    .foregroundColor(viewModel.canEditText ? Color.black : Color.gray)
                    .border(viewModel.canEditText ? Color.black : Color.gray)
                    .disabled(!viewModel.canEditText)
                    .allowsHitTesting(viewModel.canEditText)
                    //.frame(minHeight: 22)
                
                /*
                if (viewModel.canWrite)
                {
                    TextEditor(text: $viewModel.editText)
                        .foregroundColor(Color.black)
                        .border(Color.black)
                        .allowsHitTesting(viewModel.canWrite)
                }
                else
                {
                    Text(viewModel.editText)
                        .foregroundColor(Color.gray)
                        .border(Color.gray)
                        .background(Color.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
                }*/
                
                VStack
                {
                    Button("Toggle Notify", action: { viewModel.onToggleNotify()  })
                        .padding(EdgeInsets(top: 5, leading: 0, bottom: 0, trailing: 0))
                        .disabled(!viewModel.characteristic.uuCanToggleNotify)
                    
                    Button("Read Data", action: { viewModel.onReadData() })
                        .padding(EdgeInsets(top: 5, leading: 0, bottom: 0, trailing: 0))
                        .disabled(!viewModel.characteristic.uuCanReadData)
                    
                    Button("Write Data", action: { viewModel.onWriteData() })
                        .padding(EdgeInsets(top: 5, leading: 0, bottom: 0, trailing: 0))
                        .disabled(!viewModel.characteristic.uuCanWriteData)
                    
                    Button("WWOR", action: { viewModel.onWriteWithoutResponse() })
                        .padding(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0))
                        .disabled(!viewModel.characteristic.uuCanWriteWithoutResponse)
                }
                
                
            }
            .padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
            
            
            
            
            /*
            HStack
            {
                Text(viewModel.characteristic.value?.uuToHexString() ?? "")
                
                Spacer()
            }
            .padding(EdgeInsets(top: 0, leading: 40, bottom: 0, trailing: 20))
            */
            
            if (viewModel.showDivider)
            {
                Rectangle()
                    .fill(Color.black)
                    .frame(width: nil, height: 1, alignment: .leading)
            }
        }
    }
}
