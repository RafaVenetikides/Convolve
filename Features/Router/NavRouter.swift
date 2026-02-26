//
//  NavRouter.swift
//  WWDC26
//
//  Created by Rafael Venetikides on 26/02/26.
//

import SwiftUI

final class NavRouter: ObservableObject {
    @Published var path = NavigationPath()

    func push(_ route: Route) {
        path.append(route)
    }

    func goHome() {
        path = NavigationPath()
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
}
