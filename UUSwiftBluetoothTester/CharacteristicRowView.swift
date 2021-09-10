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
    
    init(_ characteristic: CBCharacteristic, showDivider: Bool = false)
    {
        self.characteristic = characteristic
        self.showDivider = showDivider
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
            
            if (viewModel.showDivider)
            {
                Rectangle()
                    .fill(Color.black)
                    .frame(width: nil, height: 1, alignment: .leading)
            }
        }
        .onTapGesture(perform: viewModel.onTap)
    }
}
