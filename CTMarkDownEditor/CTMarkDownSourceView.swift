//
//  CTMarkDownSourceView.swift
//  CTMarkDownEditor
//
//  Created by Kawakami on 2024/12/11.
//

import SwiftUI

struct CTMarkDownSourceView: View {
    @Binding var markdownSource: String

    var body: some View {
        VStack(alignment: .leading) {
            Text("MarkDown Source")
                .font(.headline)
                .padding(.bottom, 5)
            ScrollView {
                TextEditor(text: $markdownSource)
                    .font(.system(.body, design: .monospaced))
                    .disabled(false) // ユーザーの編集を有効にする
                    .padding()
            }
            .border(Color.gray, width: 1)
        }
        .padding()
        .onAppear {
            loadMarkDownFromFile()
        }
    }

    /// 一時ディレクトリからMarkDownソースを読み取る
    private func loadMarkDownFromFile() {
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("markdownSource.md")
        
        DispatchQueue.global(qos: .background).async {
            do {
                let markdown = try String(contentsOf: fileURL, encoding: .utf8)
                DispatchQueue.main.async {
                    self.markdownSource = markdown
                    print("MarkDown source loaded from file.")
                }
            } catch {
                print("Failed to load MarkDown source from file: \(error.localizedDescription)")
            }
        }
    }
}
