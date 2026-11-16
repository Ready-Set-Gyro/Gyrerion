import Foundation
@testable import StrideMetrics

/// Deterministic inputs shared by the tests. Expected values in each test were
/// calculated independently (by hand / Python), not by the library.
enum Fixture {
    static func seconds(_ value: Double) -> Measurement<UnitDuration> { Measurement(value: value, unit: .seconds) }
    static func meters(_ value: Double) -> Measurement<UnitLength> { Measurement(value: value, unit: .meters) }

    static func interval(
        seconds: Double,
        meters: Double? = nil,
        steps: Int? = nil,
        distanceProvenance: Provenance = .measured,
        stepProvenance: Provenance = .measured
    ) throws -> RunningInterval {
        try RunningInterval(
            duration: Self.seconds(seconds),
            distance: meters.map { Sourced(Self.meters($0), provenance: distanceProvenance) },
            stepCount: steps.map { Sourced($0, provenance: stepProvenance) }
        )
    }
}

/// Tolerance for values derived from a handful of IEEE-754 operations.
let tolerance = 1e-9

/// Foundation's km/h coefficient is 0.277778 rather than 1/3.6 (see
/// `SpeedPaceTests.testFoundationKilometersPerHourCoefficientIsRounded`).
let kmhRelativeError = 1e-6
let kmhTolerance = 20 * kmhRelativeError  // absolute, for values up to ~20 km/h
