//
//  Font+Extensions.swift
//  WWDC26
//
//  Created by Rafael Venetikides on 23/02/26.
//

import SwiftUI

extension Font {

    @MainActor
    static var customTitle: Font {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return .system(size: 68, weight: .bold)
        } else {
            return .system(size: 40, weight: .bold)
        }
    }

    @MainActor
    static var customTitleSmall: Font {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return .system(size: 54, weight: .bold)
        } else {
            return .system(size: 36, weight: .bold)
        }
    }

    @MainActor
    static var customBody: Font {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return .system(size: 28)
        } else {
            return .system(size: 18)
        }
    }

    @MainActor
    static var customBodySmall: Font {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return .system(size: 22)
        } else {
            return .system(size: 16)
        }
    }
}
