//
//  CTWebView.swift
//  CTMarkDownEditor
//
//  Created by Kawakami on 2024/12/11.
//

import SwiftUI
import WebKit

struct CTWebView: View {
    @Binding var url: URL?
    @Binding var htmlSource: String
    @Binding var isLoading: Bool  // ロード中の状態をバインド
    @Binding var urlString: String  // URL入力フィールドの文字列をバインド

    var body: some View {
        PlatformWebView(url: $url, htmlSource: $htmlSource, isLoading: $isLoading, urlString: $urlString)
            .edgesIgnoringSafeArea(.all)
    }
}

#if os(iOS)
struct PlatformWebView: UIViewRepresentable {
    @Binding var url: URL?
    @Binding var htmlSource: String
    @Binding var isLoading: Bool  // ロード中の状態をバインド
    @Binding var urlString: String  // URL入力フィールドの文字列をバインド

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        if let url = url {
            webView.load(URLRequest(url: url))
        }
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        if let url = url {
            webView.load(URLRequest(url: url))
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: PlatformWebView

        init(_ parent: PlatformWebView) {
            self.parent = parent
        }

        // ページのロード開始
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = true
            }
        }

        // ページのロード完了
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // 現在のURLを取得してURL入力フィールドを更新
            if let currentURL = webView.url?.absoluteString {
                DispatchQueue.main.async {
                    self.parent.urlString = currentURL
                }
            }

            webView.evaluateJavaScript("document.documentElement.outerHTML.toString()") { (result, error) in
                if let html = result as? String {
                    DispatchQueue.main.async {
                        self.parent.htmlSource = html
                        self.parent.isLoading = false
                    }
                }
            }
        }

        // ページのロード失敗
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            handleLoadError(error, webView: webView)
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            handleLoadError(error, webView: webView)
        }

        private func handleLoadError(_ error: Error, webView: WKWebView) {
            let nsError = error as NSError
            // エラーコード -999 (NSURLErrorCancelled) は無視
            if nsError.code == NSURLErrorCancelled {
                DispatchQueue.main.async {
                    self.parent.isLoading = false
                }
                return
            }
            DispatchQueue.main.async {
                self.parent.isLoading = false
                self.parent.htmlSource = "Failed to load page: \(error.localizedDescription)"
            }
        }

        // リダイレクトの検出と処理
        func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping @MainActor (WKNavigationResponsePolicy) -> Void) {
            if let response = navigationResponse.response as? HTTPURLResponse,
               let url = response.url {
                // リダイレクトされたURLをURL入力フィールドに設定
                DispatchQueue.main.async {
                    self.parent.urlString = url.absoluteString
                    self.parent.url = url
                }
            }
            decisionHandler(.allow)
        }
    }
}

#elseif os(macOS)
struct PlatformWebView: NSViewRepresentable {
    @Binding var url: URL?
    @Binding var htmlSource: String
    @Binding var isLoading: Bool  // ロード中の状態をバインド
    @Binding var urlString: String  // URL入力フィールドの文字列をバインド
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        // 必要に応じて設定を追加
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        if let url = url, nsView.url != url {
            nsView.load(URLRequest(url: url))
        }
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: PlatformWebView

        init(_ parent: PlatformWebView) {
            self.parent = parent
        }

        // ページのロード開始
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = true
            }
        }

        // ページのロード完了
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // 現在のURLを取得してURL入力フィールドを更新
            if let currentURL = webView.url?.absoluteString {
                DispatchQueue.main.async {
                    self.parent.urlString = currentURL
                }
            }
            
            webView.evaluateJavaScript("document.documentElement.outerHTML.toString()") { (result, error) in
                if let html = result as? String {
                    DispatchQueue.main.async {
                        self.parent.htmlSource = html
                        self.parent.isLoading = false
                    }
                }
            }
        }

        // ページのロード失敗
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            handleLoadError(error, webView: webView)
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            handleLoadError(error, webView: webView)
        }

        private func handleLoadError(_ error: Error, webView: WKWebView) {
            let nsError = error as NSError
            // エラーコード -999 (NSURLErrorCancelled) は無視
            if nsError.code == NSURLErrorCancelled {
                DispatchQueue.main.async {
                    self.parent.isLoading = false
                }
                return
            }
            DispatchQueue.main.async {
                self.parent.isLoading = false
                self.parent.htmlSource = "Failed to load page: \(error.localizedDescription)"
            }
        }

        // リダイレクトの検出と処理
        func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping @MainActor (WKNavigationResponsePolicy) -> Void) {
            if let response = navigationResponse.response as? HTTPURLResponse,
               let url = response.url {
                // リダイレクトされたURLをURL入力フィールドに設定
                DispatchQueue.main.async {
                    self.parent.urlString = url.absoluteString
                    self.parent.url = url
                }
            }
            decisionHandler(.allow)
        }
    }
}
#endif
