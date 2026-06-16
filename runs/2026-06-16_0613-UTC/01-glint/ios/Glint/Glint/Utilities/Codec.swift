import Foundation

/// JSON codec helpers for persisting board snapshots and RNG state.
enum Codec {
    private static let encoder = JSONEncoder()
    private static let decoder = JSONDecoder()

    static func encodeBoard(_ board: Board) -> Data {
        (try? encoder.encode(board)) ?? Data()
    }

    static func decodeBoard(_ data: Data) -> Board? {
        try? decoder.decode(Board.self, from: data)
    }

    static func encodeRNG(_ rng: SplitMix64) -> Data {
        var s = rng.state
        return Data(bytes: &s, count: MemoryLayout<UInt64>.size)
    }

    static func decodeRNG(_ data: Data) -> SplitMix64? {
        guard data.count >= MemoryLayout<UInt64>.size else { return nil }
        var s: UInt64 = 0
        _ = withUnsafeMutableBytes(of: &s) { dst in
            data.copyBytes(to: dst, count: MemoryLayout<UInt64>.size)
        }
        return SplitMix64(rawState: s)
    }
}
