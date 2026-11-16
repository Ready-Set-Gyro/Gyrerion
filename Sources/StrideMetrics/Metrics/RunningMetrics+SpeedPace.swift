import Foundation

extension RunningMetrics {
    /// v = d / t
    static func speed(_ interval: RunningInterval) -> MetricResult<Measurement<UnitSpeed>> {
        guard let distance = interval.distance else { return .unavailable(.missingDistance) }
        let meters = distance.value.converted(to: .meters).value
        return .available(
            Measurement(value: meters / interval.seconds, unit: .metersPerSecond),
            .ofResult(from: distance.provenance)
        )
    }

    /// p = t / d, undefined when d = 0.
    static func pace(_ interval: RunningInterval) -> MetricResult<Pace> {
        guard let distance = interval.distance else { return .unavailable(.missingDistance) }
        let meters = distance.value.converted(to: .meters).value
        guard meters > 0 else { return .unavailable(.noDistanceCovered) }
        return .available(
            Pace(secondsPerMeter: interval.seconds / meters),
            .ofResult(from: distance.provenance)
        )
    }
}
