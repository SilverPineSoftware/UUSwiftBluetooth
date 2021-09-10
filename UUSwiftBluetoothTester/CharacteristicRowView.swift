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
    @Published var characteristic: CBCharacteristic
    @Published var showDivider: Bool
    
    @Published var isNotifying: Bool
    {
        willSet
        {
            NSLog("isNotifying changing to: \(newValue)")
        }
    }
    
    @Published var canWrite: Bool
    
    var charText: String
    {
        get
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
        
        set
        {
            NSLog("charText changing to \(newValue)")
        }
    }
    
    enum DataDisplayType: Int, CaseIterable
    {
        case hex = 0
        case utf8 = 1
    }
    
    @Published var dataDisplay: Int

    
    init(_ characteristic: CBCharacteristic, showDivider: Bool = false)
    {
        self.characteristic = characteristic
        self.showDivider = showDivider
        self.isNotifying = characteristic.isNotifying
        self.dataDisplay = DataDisplayType.hex.rawValue
        self.canWrite = (characteristic.uuCanWriteData || characteristic.uuCanWriteWithoutResponse)
    }
    
    func onTap()
    {
        NSLog("Tapped on charactertistic: \(characteristic.uuid.uuidString)")
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
            
            HStack
            {
                Toggle("IsNotifying:", isOn: $viewModel.isNotifying)
                    .disabled(!viewModel.characteristic.uuCanToggleNotify)
                    .allowsHitTesting(viewModel.characteristic.uuCanToggleNotify)
            }
            .padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
            
            HStack
            {
                Text("Data:")
                    .bold()
                
                Spacer()
                
                Picker("Foo", selection: $viewModel.dataDisplay)
                {
                    Text("hex").tag(CharacteristicRowViewModel.DataDisplayType.hex.rawValue)
                    Text("utf8").tag(CharacteristicRowViewModel.DataDisplayType.utf8.rawValue)
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            .padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
            
            HStack
            {
                TextEditor(text: $viewModel.charText)
                    .border(viewModel.canWrite ? Color.black : Color.gray)
                    .foregroundColor(viewModel.canWrite ? Color.black : Color.gray)
                    .disabled(viewModel.canWrite)
                    .allowsHitTesting(viewModel.canWrite)
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
