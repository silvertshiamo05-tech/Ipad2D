import SwiftUI

struct RootView: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.09, green: 0.10, blue: 0.15),
                                    Color(red: 0.16, green: 0.12, blue: 0.24)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack(spacing: 18) {
                Image(systemName: "scribble.variable")
                    .font(.system(size: 64, weight: .thin))
                    .foregroundStyle(.white)
                Text("Ipad2D")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("A clean-room Live2D Cubism editor for iPad")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.75))
                Text("Milestone 0 — app shell & build pipeline")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.top, 6)
            }
            .multilineTextAlignment(.center)
            .padding()
        }
    }
}
