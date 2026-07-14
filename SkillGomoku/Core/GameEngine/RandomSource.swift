import Foundation

protocol RandomSource {
    var state: UInt64 { get }
    mutating func nextUInt64() -> UInt64
    mutating func nextInt(in range: ClosedRange<Int>) -> Int
}

struct SeededRandomSource: RandomSource, Codable, Equatable, Sendable {
    private(set) var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0x5eed : seed
    }

    mutating func nextUInt64() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }

    mutating func nextInt(in range: ClosedRange<Int>) -> Int {
        let width = UInt64(range.upperBound - range.lowerBound + 1)
        return range.lowerBound + Int(nextUInt64() % width)
    }
}
