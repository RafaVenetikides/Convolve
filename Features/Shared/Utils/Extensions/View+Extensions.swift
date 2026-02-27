//
//  View+Extensions.swift
//  Convolve
//
//  Created by Rafael Venetikides on 27/02/26.
//

import SwiftUI

extension View {
    func onRotate(perform action: @escaping (UIDeviceOrientation) -> Void) -> some View {
        self.modifier(DeviceRotationViewModifier(action: action))
    }
}
