import SwiftUI
import WebKit

// Milestone 1 — on-device Live2D canvas.
// Hybrid renderer: native app shell hosting the official Cubism Web runtime in
// a WKWebView (WebGL). A later milestone replaces this with a native Metal
// renderer via the official Cubism SDK for iOS.
struct RootView: View {
    var body: some View {
        ZStack(alignment: .top) {
            Color(red: 0.95, green: 0.96, blue: 0.97).ignoresSafeArea()
            Live2DCanvas().ignoresSafeArea()
            Text("Ipad2D · Live2D canvas")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.vertical, 6).padding(.horizontal, 12)
                .background(.ultraThinMaterial, in: Capsule())
                .padding(.top, 8)
        }
    }
}

struct Live2DCanvas: UIViewRepresentable {
    func makeUIView(context: Context) -> WKWebView {
        let cfg = WKWebViewConfiguration()
        cfg.allowsInlineMediaPlayback = true
        let web = WKWebView(frame: .zero, configuration: cfg)
        web.isOpaque = false
        web.backgroundColor = .clear
        web.scrollView.isScrollEnabled = false
        web.scrollView.contentInsetAdjustmentBehavior = .never
        if let url = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "web") {
            web.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
        return web
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
