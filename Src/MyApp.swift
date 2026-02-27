import SwiftUI

@main
struct MyApp: App {

    @State var orientation = UIDeviceOrientation.portrait

    var body: some Scene {
        WindowGroup {
            ZStack {

                ContentView()
                    .preferredColorScheme(.dark)

                if !orientation.isPortrait {
                    OrientationOverlayView()
                        .transition(.opacity)
                        .zIndex(999)
                }
            }
            .onRotate { newOrientation in
                orientation = newOrientation
            }
            .onAppear {
                orientation = UIDevice.current.orientation
            }
        }
    }
}
