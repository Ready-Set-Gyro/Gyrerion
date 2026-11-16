import Foundation

extension RunningMetrics {
    /// c = 60 · n / t  (steps per minute, t in seconds)
    static func cadence(_ interval: RunningInterval) -> MetricResult<Cadence> {
        guard let steps = interval.stepCount else { return .unavailable(.missingStepCount) }
        return .available(
            Cadence(stepsPerMinute: 60 * Double(steps.value) / interval.seconds),
            .ofResult(from: steps.provenance)
        )
    }

    /// L_step = d / n, undefined when n = 0. Distance is checked first, so it is
    /// the reported reason when both inputs are missing.
    static func stepLength(_ interval: RunningInterval) -> MetricResult<Measurement<UnitLength>> {
        guard let distance = interval.distance else { return .unavailable(.missingDistance) }
        guard let steps = interval.stepCount else { return .unavailable(.missingStepCount) }
        guard steps.value > 0 else { return .unavailable(.noStepsTaken) }
        let meters = distance.value.converted(to: .meters).value
        return .available(
            Measurement(value: meters / Double(steps.value), unit: .meters),
            .ofResult(from: distance.provenance, steps.provenance)
        )
    }

    /// L_stride = 2 · L_step: one stride is one full gait cycle (left + right step).
    static func strideLength(_ interval: RunningInterval) -> MetricResult<Measurement<UnitLength>> {
        switch stepLength(interval) {
        case .available(let step, let provenance): .available(step * 2, provenance)
        case .unavailable(let reason): .unavailable(reason)
        }
    }
}
