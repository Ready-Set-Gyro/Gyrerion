/// Where a value came from.
///
/// The caller states the provenance of every input; the library never guesses it.
/// Calculated results are never `.measured`.
public enum Provenance: Sendable, Hashable, CaseIterable {
    /// Directly observed by an instrument: a clock, a GPS track's accumulated distance,
    /// a pedometer's detected step count, a measured track or treadmill belt distance.
    /// Measured values still carry instrument error (GPS distance in particular).
    case measured

    /// Calculated by a defined formula from inputs that were all measured or derived.
    /// Carries the error of those inputs and adds no modelling assumptions.
    case derived

    /// Produced by a model with assumptions, for example distance inferred from
    /// step count × an assumed step length, or any value calculated from such an input.
    case estimated

    /// Provenance of a value calculated from inputs with the given provenances.
    static func ofResult(from inputs: Provenance...) -> Provenance {
        inputs.contains(.estimated) ? .estimated : .derived
    }
}

/// A value paired with its provenance.
public struct Sourced<Value: Sendable & Hashable>: Sendable, Hashable {
    public let value: Value
    public let provenance: Provenance

    public init(_ value: Value, provenance: Provenance) {
        self.value = value
        self.provenance = provenance
    }

    public static func measured(_ value: Value) -> Sourced { Sourced(value, provenance: .measured) }
    public static func estimated(_ value: Value) -> Sourced { Sourced(value, provenance: .estimated) }
}
