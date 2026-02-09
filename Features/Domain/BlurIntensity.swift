//
//  BlurIntensity.swift
//  WWDC26
//
//  Created by Rafael Venetikides on 06/02/26.
//

import Foundation

enum BlurIntensity: String, CaseIterable, Identifiable {
    case light = "Light"
    case medium = "Medium"
    case strong = "Strong"

    var id: String { rawValue }

    var fractionOfMinSide: Double {
        switch self {
        case .light: return 0.01
        case .medium: return 0.04
        case .strong: return 0.08
        }
    }
}
