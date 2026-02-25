//
//  Array.swift
//  WWDC26
//
//  Created by Rafael Venetikides on 11/02/26.
//

import Foundation

extension Array where Element == Int {
    func convolve(with other: [Int]) -> [Int] {
        let n = self.count
        let m = other.count
        var out = Array(repeating: 0, count: n + m - 1)
        for i in 0..<n {
            for j in 0..<m {
                out[i + j] += self[i] * other[j]
            }
        }
        return out
    }
}
