//
//  ContentView.swift
//  CTMarkDownEditor
//
//  Created by Kawakami on 2024/12/11.
//

import SwiftUI

struct ContentView: View {
    @State private var urlString: String = "https://www.apple.com/"
    @State private var url: URL? = URL(string: "https://www.apple.com/")
    @State private var htmlSource: String = ""
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    // タブの定義
    enum Tab {
        case web
        case html
    }
    
    @State private var selectedTab: Tab = .web
    @State private var isLoading: Bool = false  // ロード中の状態を管理

    #if os(iOS)
    @FocusState private var isURLFieldFocused: Bool
    #endif

    var body: some View {
        NavigationStack {
            VStack {
                // URL入力フィールドとロードボタン
                HStack {
                    TextField("Enter website URL", text: $urlString, onCommit: loadURL)
                        .textFieldStyle(RoundedBorderTextFieldStyle())  // 入力域のまわりを枠で囲む
                        .disableAutocorrection(true)                     // 自動修正を無効化
                        #if os(iOS)
                        .textInputAutocapitalization(.never)             // 自動大文字化を無効化
                        .keyboardType(.URL)                              // URL入力用キーボード
                        .submitLabel(.go)                                // リターンキーを「Go」に設定
                        .focused($isURLFieldFocused)                    // FocusStateをバインド
                        .onTapGesture {
                            Task {
                                await MainActor.run {
                                    self.isURLFieldFocused = true       // タップ時にフォーカスを設定
                                }
                            }
                        }
                        #endif
                        .padding([.leading, .trailing])

                    Button(action: loadURL) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Image(systemName: "arrow.clockwise")
                                .imageScale(.large)
                        }
                    }
                    .padding([.top, .trailing])
                    .disabled(isLoading)  // ロード中はボタンを無効化
                }
                .padding([.top])

                // タブに応じて CTWebView または CTHTMLSourceView を表示
                if selectedTab == .web {
                    CTWebView(url: $url, htmlSource: $htmlSource, isLoading: $isLoading, urlString: $urlString)
                } else {
                    CTHTMLSourceView(htmlSource: $htmlSource)
                }
            }
            .navigationTitle("Simple Web Browser")
            .toolbar {
                #if os(iOS)
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    // Webタブへの切り替えボタン
                    Button(action: { selectedTab = .web }) {
                        Image(systemName: "globe")
                        Text("Web")
                    }

                    // HTML Sourceタブへの切り替えボタン
                    Button(action: { selectedTab = .html }) {
                        Image(systemName: "doc.text")
                        Text("HTML Source")
                    }
                }
                #endif
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Invalid URL"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            #if os(iOS)
            .onAppear {
                // アプリ起動時に自動的にキーボードを表示
                Task {
                    await MainActor.run {
                        self.isURLFieldFocused = true
                    }
                }
            }
            #endif
        }
        #if os(iOS)
        .navigationViewStyle(StackNavigationViewStyle()) // iOS向けにスタックスタイルを使用
        #else
        .navigationViewStyle(DoubleColumnNavigationViewStyle()) // macOS向けにダブルカラムスタイルを使用
        #endif
    }

    func loadURL() {
        var formattedURLString = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        if !formattedURLString.hasPrefix("http://") && !formattedURLString.hasPrefix("https://") {
            formattedURLString = "https://" + formattedURLString
        }
        guard let newURL = URL(string: formattedURLString) else {
            alertMessage = "Please enter a valid URL."
            showAlert = true
            return
        }
        url = newURL
        #if os(iOS)
        isURLFieldFocused = false  // ロード後にキーボードを閉じる
        #endif
    }
}

#Preview {
    ContentView()
}
