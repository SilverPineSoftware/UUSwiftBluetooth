//
//  SectionHeaderView.swift
//  UUSwiftBluetoothTester
//
//  Created by Ryan DeVore on 9/9/21.
//

import SwiftUI

struct SectionHeaderView: View
{
    var label: String
    
    var body: some View {
        
        HStack
        {
            Text(label)
                .bold()
                .padding(EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5))
                
            Spacer()
        }
        .background(Color.gray)
    }
}
