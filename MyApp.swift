import SwiftUI

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            if #available(iOS 26.0, *) {
                ContentView()
            } else {
                Text("This app only works in iOS 26.0\nPlease update your iOS version.")
            }
        }
    }
}
