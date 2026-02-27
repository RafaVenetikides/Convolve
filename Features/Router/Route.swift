//
//  Route.swift
//  WWDC26
//
//  Created by Rafael Venetikides on 26/02/26.
//

import Foundation

enum Route: Hashable {
    case intro
    case mathDefinition
    case operation
    case applicationImage
    case applicationCNN
    case playgroundIntro
    case playgroundMenu
    case convolution(assetName: String)
    case convolutionPhoto(imageData: Data)
}
