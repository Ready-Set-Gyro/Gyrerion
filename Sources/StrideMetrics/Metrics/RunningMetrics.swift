import Foundation

/// All metrics this library can calculate for one `RunningInterval`.
///
/// Each metric is calculated independently, so a missing step count makes cadence
/// unavailable without affecting speed. See docs/Metrics.md for definitions.
public struct RunningMetrics: Sendable, Hashable {
    /// Average speed in metres per second.
    public let speed: MetricResult<Measurement<UnitSpeed>>
    /// Average pace.
    public let pace: MetricResult<Pace>
    /// Average cadence.
    public let cadence: MetricResult<Cadence>
    /// Average distance per step, in metres.
    public let stepLength: MetricResult<Measurement<UnitLength>>
    /// Average distance per stride (two steps, one full gait cycle), in metres.
    public let strideLength: MetricResult<Measurement<UnitLength>>

    public init(_ interval: RunningInterval) {
        speed = Self.speed(interval)
        pace = Self.pace(interval)
        cadence = Self.cadence(interval)
        stepLength = Self.stepLength(interval)
        strideLength = Self.strideLength(interval)
    }
}
