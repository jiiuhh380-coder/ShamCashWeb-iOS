import SwiftUI
import WebKit

final class WebViewModel: ObservableObject {
    let webView: WKWebView
    let homeURL = URL(string: "https://shamcash.sy")!

    @Published var canGoBack = false
    @Published var canGoForward = false
    @Published var isLoading = false
    @Published var progress: Double = 0

    private var progressObservation: NSKeyValueObservation?

    init() {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        webView = WKWebView(frame: .zero, configuration: config)
        webView.allowsBackForwardNavigationGestures = true
        webView.isOpaque = false
        webView.backgroundColor = .systemBackground
        webView.scrollView.backgroundColor = .systemBackground

        progressObservation = webView.observe(\.estimatedProgress) { [weak self] web, _ in
            DispatchQueue.main.async {
                self?.progress = web.estimatedProgress
            }
        }
        load(homeURL)
    }

    func load(_ url: URL) {
        webView.load(URLRequest(url: url))
    }

    func syncNavigationState() {
        canGoBack = webView.canGoBack
        canGoForward = webView.canGoForward
    }
}

struct WebViewRepresentable: UIViewRepresentable {
    let model: WebViewModel

    func makeCoordinator() -> Coordinator {
        Coordinator(model: model)
    }

    func makeUIView(context: Context) -> WKWebView {
        model.webView.navigationDelegate = context.coordinator
        model.webView.uiDelegate = context.coordinator
        return model.webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        let model: WebViewModel

        init(model: WebViewModel) {
            self.model = model
        }

        func webView(_ webView: WKWebView,
                     decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }

            if let scheme = url.scheme?.lowercased(),
               ["tel", "mailto", "whatsapp", "sms"].contains(scheme) {
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
                return
            }

            if let host = url.host?.lowercased(),
               host == "shamcash.sy" || host.hasSuffix(".shamcash.sy") {
                decisionHandler(.allow)
                return
            }

            if navigationAction.targetFrame == nil {
                webView.load(navigationAction.request)
                decisionHandler(.cancel)
                return
            }

            UIApplication.shared.open(url)
            decisionHandler(.cancel)
        }

        func webView(_ webView: WKWebView,
                     createWebViewWith configuration: WKWebViewConfiguration,
                     for navigationAction: WKNavigationAction,
                     windowFeatures: WKWindowFeatures) -> WKWebView? {
            if navigationAction.targetFrame == nil {
                webView.load(navigationAction.request)
            }
            return nil
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            model.isLoading = true
        }

        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
            model.syncNavigationState()
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            model.isLoading = false
            model.syncNavigationState()
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            model.isLoading = false
            model.syncNavigationState()
        }

        func webView(_ webView: WKWebView,
                     didFailProvisionalNavigation navigation: WKNavigation!,
                     withError error: Error) {
            model.isLoading = false
        }
    }
}

struct ContentView: View {
    @StateObject private var model = WebViewModel()

    var body: some View {
        VStack(spacing: 0) {
            if model.isLoading {
                ProgressView(value: model.progress)
                    .progressViewStyle(.linear)
            }
            WebViewRepresentable(model: model)
                .ignoresSafeArea(edges: .horizontal)
            HStack {
                Button {
                    model.webView.goBack()
                } label: {
                    Image(systemName: "chevron.right")
                }
                .disabled(!model.canGoBack)

                Spacer()

                Button {
                    model.webView.goForward()
                } label: {
                    Image(systemName: "chevron.left")
                }
                .disabled(!model.canGoForward)

                Spacer()

                Button {
                    model.webView.reload()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }

                Spacer()

                Button {
                    model.load(model.homeURL)
                } label: {
                    Image(systemName: "house")
                }
            }
            .font(.title3)
            .padding(.horizontal, 32)
            .padding(.vertical, 10)
            .background(.bar)
        }
    }
}
