import Foundation

/// Validated input data for one continuous period of running.
///
/// Distance and step count are optional: `nil` means "not available", which is
/// different from zero. All values are checked on creation, so an existing
/// `RunningInterval` never holds NaN, infinite or negative values.
public struct RunningInterval: Sendable, Hashable {
    /// Elapsed time of the interval, measured by a clock. Always > 0.
    public let duration: Measurement<UnitDuration>
    /// Distance covered during the interval, if known. Always ≥ 0.
    public let distance: Sourced<Measurement<UnitLength>>?
    /// Steps taken during the interval, counting both feet, if known. Always ≥ 0.
    public let stepCount: Sourced<Int>?

    /// - Throws: `ValidationError` if duration is not finite and > 0, distance is not
    ///   finite and ≥ 0, or step count is negative.
    public init(
        duration: Measurement<UnitDuration>,
        distance: Sourced<Measurement<UnitLength>>? = nil,
        stepCount: Sourced<Int>? = nil
    ) throws(ValidationError) {
        try Validate.positive(duration.converted(to: .seconds).value, .duration)
        if let distance {
            try Validate.nonNegative(distance.value.converted(to: .meters).value, .distance)
        }
        if let stepCount, stepCount.value < 0 {
            throw .negative(.stepCount)
        }
        self.duration = duration
        self.distance = distance
        self.stepCount = stepCount
    }

    var seconds: Double { duration.converted(to: .seconds).value }
}
