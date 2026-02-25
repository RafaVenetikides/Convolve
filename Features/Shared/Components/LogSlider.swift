//
//  LogSlider.swift
//  WWDC26
//
//  Created by Rafael Venetikides on 09/02/26.
//

import SwiftUI

struct LogSlider: View {
    @Binding var value: Double
    let minValue: Double
    let maxValue: Double
    let step: Double

    private func toSlider(_ v: Double) -> Double {
        let v = min(max(v, minValue), maxValue)
        let minLog = log(minValue)
        let maxLog = log(maxValue)
        return (log(v) - minLog) / (maxLog - minLog)
    }

    private func fromSlider(_ t: Double) -> Double {
        let minLog = log(minValue)
        let maxLog = log(maxValue)
        let v = exp(minLog + t * (maxLog - minLog))
        return v
    }

    var body: some View {
        Slider(
            value: Binding(
                get: {
                    toSlider(value)
                },
                set: { newT in
                    let raw = fromSlider(newT)

                    let snapped = (raw / step).rounded() * step
                    value = min(max(snapped, minValue), maxValue)
                }
            ),
            in: 0...1
        )
    }
}
