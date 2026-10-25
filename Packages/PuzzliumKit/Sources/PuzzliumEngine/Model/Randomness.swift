import Foundation

/// Deterministic RNG so the same puzzle always cuts the same way (needed to restore saves).
public struct SplitMix64: RandomNumberGenerator, Sendable {
    private var state: UInt64

    public init(seed: UInt64) {
        state = seed
    }

    public mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

public enum StableHash {
    /// FNV-1a, truncated to 53 bits so it survives JSON round-trips exactly.
    public static func seed(_ parts: String...) -> UInt64 {
        var hash: UInt64 = 0xCBF2_9CE4_8422_2325
        for byte in parts.joined(separator: "|").utf8 {
            hash ^= UInt64(byte)
            hash &*= 0x0000_0100_0000_01B3
        }
        return hash & 0x001F_FFFF_FFFF_FFFF
    }
}
