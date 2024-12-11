//
//  CTSplitView.swift
//  CTMarkDownEditor
//
//  Created by Kawakami on 2024/12/11.
//

import SwiftUI

struct SplitView<Content: View, Detail: View>: View {
    let content: () -> Content
    let detail: () -> Detail

    init(@ViewBuilder content: @escaping () -> Content, @ViewBuilder detail: @escaping () -> Detail) {
        self.content = content
        self.detail = detail
    }

    var body: some View {
        #if os(macOS)
        HStack(spacing: 0) {
            content()
                .frame(minWidth: 300, maxWidth: .infinity, minHeight: 400, maxHeight: .infinity)
            Divider()
            detail()
                .frame(minWidth: 300, maxWidth: .infinity, minHeight: 400, maxHeight: .infinity)
        }
        #else
        // iOS/iPadOSでは `SplitView` を使用せず、ContentView内で切り替えを管理
        EmptyView()
        #endif
    }
}
