import SwiftUI

@available(iOS 26.0, *)
struct ContentView: View {
    @State private var startAnimation = false

    var body: some View {
        GeometryReader { metrics in
            ZStack {
                LinearGradient(
                    colors: [.purple, .blue],
                    startPoint: startAnimation ? .topLeading : .bottomLeading,
                    endPoint: startAnimation ? .bottomTrailing : .topTrailing
                )
                .ignoresSafeArea()

                VStack(alignment: .center) {
                    GlassEffectContainer {
                        Image(systemName: "apple.intelligence")
                            .resizable()
                            .foregroundColor(.white)
                            .scaledToFit()
                            .frame(
                                width: metrics.size.width * 0.37,
                            )
                            .padding(metrics.size.width * 0.05)
                    }
                    .padding()
                    .glassEffect(.clear.interactive())
                }
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 5.0).repeatForever()) {
                startAnimation.toggle()
            }
        }
    }
}
