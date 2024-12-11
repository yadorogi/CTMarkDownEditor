//
//  CTHTMLSourceView.swift
//  CTMarkDownEditor
//
//  Created by Kawakami on 2024/12/11.
//

import SwiftUI

struct CTHTMLSourceView: View {
    @Binding var htmlSource: String

    var body: some View {
        VStack(alignment: .leading) {
            Text("HTML Source")
                .font(.headline)
                .padding(.bottom, 5)
            
            ScrollView {
                Text(htmlSource)
                    .font(.system(.body, design: .monospaced))
                    .padding()
            }
            .border(Color.gray, width: 1)
        }
        .padding()
    }
}
