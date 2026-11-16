/// Step rate, counting steps of both feet.
///
/// Some devices report "strides per minute" counting one foot only; that value is
/// half of this one. Always finite and ≥ 0.
public struct Cadence: Sendable, Hashable {
    public let stepsPerMinute: Double

    init(stepsPerMinute: Double) {
        self.stepsPerMinute = stepsPerMinute
    }

    public var stepsPerSecond: Double { stepsPerMinute / 60 }
}
