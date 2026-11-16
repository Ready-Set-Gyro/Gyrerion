import Foundation

/// Time taken per unit of distance: the reciprocal of speed.
///
/// Foundation has no pace unit, so this type stores seconds per metre and converts
/// on read. A smaller pace is faster; compare `speed` values if you need ordering.
public struct Pace: Sendable, Hashable {
    /// Seconds per metre. Always finite and > 0.
    public let secondsPerMeter: Double

    init(secondsPerMeter: Double) {
        self.secondsPerMeter = secondsPerMeter
    }

    /// Pace of covering `distance` in `duration`, e.g. 5 minutes per 1 kilometre.
    /// - Throws: `ValidationError` unless both values are finite and > 0.
    public init(_ duration: Measurement<UnitDuration>, per distance: Measurement<UnitLength>) throws(ValidationError) {
        let seconds = duration.converted(to: .seconds).value
        let meters = distance.converted(to: .meters).value
        try Validate.positive(seconds, .duration)
        try Validate.positive(meters, .distance)
        self.init(secondsPerMeter: seconds / meters)
    }

    /// The pace equivalent to a speed: pace = 1 / speed.
    /// - Throws: `ValidationError` unless speed is finite and > 0.
    public init(speed: Measurement<UnitSpeed>) throws(ValidationError) {
        let metersPerSecond = speed.converted(to: .metersPerSecond).value
        try Validate.positive(metersPerSecond, .speed)
        self.init(secondsPerMeter: 1 / metersPerSecond)
    }

    /// Time taken to cover one `unit`, e.g. `pace.duration(per: .kilometers)`.
    public func duration(per unit: UnitLength) -> Measurement<UnitDuration> {
        let metersPerUnit = Measurement(value: 1, unit: unit).converted(to: .meters).value
        return Measurement(value: secondsPerMeter * metersPerUnit, unit: .seconds)
    }

    /// The equivalent speed: speed = 1 / pace.
    public var speed: Measurement<UnitSpeed> {
        Measurement(value: 1 / secondsPerMeter, unit: .metersPerSecond)
    }
}
