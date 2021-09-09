//
//  LabelValueRowView.swift
//  UUSwiftBluetoothTester
//
//  Created by Ryan DeVore on 9/9/21.
//

import SwiftUI

struct LabelValueRowView: View
{
    var label: String
    var value: String
    
    var body: some View
    {
        HStack
        {
            Text(label)
                .bold()
            
            Text(value)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            
            Spacer()
        }
        .padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
    }
}
