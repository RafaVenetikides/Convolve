import SwiftUI

struct ContentView: View {
    @StateObject private var router = NavRouter()

    var body: some View {
        NavigationStack(path: $router.path) {
            TitleView()
                .navigationDestination(for: Route.self) { route in
                    switch route{
                    case .intro:
                        IntroductionView()
                    case .mathDefinition:
                        MathDefinitionView()
                    case .operation:
                        ConvolutionOperationView()
                    case .applicationImage:
                        ImageProcessingExampleView()
                    case .applicationCNN:
                        NeuralNetworkExampleView()
                    case .playgroundIntro:
                        PlaygroundIntroductionView()
                    case .playgroundMenu:
                        PlaygroundCollectionView()
                    case .convolution(let assetName):
                        ConvolutionView(assetName: assetName)
                    case .convolutionPhoto(let data):
                        ConvolutionView(imageData: data)
                    }
                }
        }
        .environmentObject(router)
    }
}
