/// The outcome of calculating one metric.
///
/// A metric is either available, with the provenance of the calculated value,
/// or unavailable with a reason. A zero-valued metric (e.g. 0 m/s) is `.available`;
/// `.unavailable` means the value is missing or mathematically undefined.
public enum MetricResult<Value: Sendable & Hashable>: Sendable, Hashable {
    case available(Value, Provenance)
    case unavailable(UnavailableReason)

    /// The value if available, otherwise `nil`.
    public var value: Value? {
        if case .available(let value, _) = self { value } else { nil }
    }

    /// The provenance if available, otherwise `nil`.
    public var provenance: Provenance? {
        if case .available(_, let provenance) = self { provenance } else { nil }
    }
}

/// Why a metric could not be calculated.
public enum UnavailableReason: Sendable, Hashable {
    /// The interval has no distance input.
    case missingDistance
    /// The interval has no step count input.
    case missingStepCount
    /// Distance is zero, so time per distance (pace) is undefined.
    case noDistanceCovered
    /// Step count is zero, so distance per step is undefined.
    case noStepsTaken
}
