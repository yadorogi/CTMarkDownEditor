//
//  CTWebView.swift
//  CTMarkDownEditor
//
//  Created by Kawakami on 2024/12/11.
//

import SwiftUI
import WebKit
import HTML2Markdown

struct CTWebView: View {
    @Binding var url: URL?
    @Binding var htmlSource: String
    @Binding var isLoading: Bool
    @Binding var urlString: String

    var body: some View {
        PlatformWebView(url: $url, htmlSource: $htmlSource, isLoading: $isLoading, urlString: $urlString)
            .edgesIgnoringSafeArea(.all)
    }
}

#if os(iOS)
struct PlatformWebView: UIViewRepresentable {
    @Binding var url: URL?
    @Binding var htmlSource: String
    @Binding var isLoading: Bool
    @Binding var urlString: String

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        if let url = url {
            webView.load(URLRequest(url: url))
        }
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard let url = url else { return }
        if webView.url != url {
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

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.isLoading = true
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
            
            // 1回目のHTML取得
            fetchHTML(webView: webView)
            
            // 2回目のHTML取得（2秒後）
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.fetchHTML(webView: webView)
            }
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            if (error as NSError).code == NSURLErrorCancelled {
                return
            }
            parent.isLoading = false
            parent.htmlSource = "Failed to load: \(error.localizedDescription)"
        }
        
        /// ページのHTMLを取得する関数
        private func fetchHTML(webView: WKWebView) {
            let script = """
            if (document.readyState === 'complete') {
                document.documentElement.outerHTML
            } else {
                null
            }
            """
            webView.evaluateJavaScript(script) { result, error in
                if let html = result as? String {
                    self.parent.htmlSource = html
                    print("HTML source updated successfully.")
                    self.saveHTMLToFile(html)
                    self.convertHTMLToMarkdown(html)
                } else if let error = error {
                    print("Error fetching HTML: \(error.localizedDescription)")
                }
            }
        }

        /// HTMLソースを一時ディレクトリに保存する
        private func saveHTMLToFile(_ html: String) {
            let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("htmlSource.html")
            do {
                try html.write(to: fileURL, atomically: true, encoding: .utf8)
                print("HTML source saved to: \(fileURL.path)")
            } catch {
                print("Failed to save HTML source: \(error.localizedDescription)")
            }
        }

        /// Markdownソースを一時ディレクトリに保存する
        private func convertHTMLToMarkdown(_ html: String) {
            do {
                let dom = try HTMLParser().parse(html: html)
                let markdown = dom.markdownFormatted(options: .unorderedListBullets)
                let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("markdownSource.md")
                try markdown.write(to: fileURL, atomically: true, encoding: .utf8)
                print("Markdown source saved to: \(fileURL.path)")
            } catch {
                print("Failed to convert and save Markdown: \(error.localizedDescription)")
            }
        }
    }
}

#elseif os(macOS)
struct PlatformWebView: NSViewRepresentable {
    @Binding var url: URL?
    @Binding var htmlSource: String
    @Binding var isLoading: Bool
    @Binding var urlString: String

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.preferences.javaScriptEnabled = true
        configuration.websiteDataStore = .default()
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        
        if let url = url {
            webView.load(URLRequest(url: url))
        }
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        guard let url = url, url != webView.url else { return }
        webView.load(URLRequest(url: url))
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: PlatformWebView

        init(_ parent: PlatformWebView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.isLoading = true
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
            // ページのHTMLソースを取得
            webView.evaluateJavaScript("document.documentElement.outerHTML") { result, error in
                if let html = result as? String {
                    self.parent.htmlSource = html
                } else if let error = error {
                    print("Error fetching HTML: \(error.localizedDescription)")
                }
            }
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            if (error as NSError).code == NSURLErrorCancelled {
                return
            }
            parent.isLoading = false
            parent.htmlSource = "Failed to load: \(error.localizedDescription)"
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            if (error as NSError).code == NSURLErrorCancelled {
                return
            }
            parent.isLoading = false
            parent.htmlSource = "Failed to load: \(error.localizedDescription)"
        }
    }
}
#endif
