# Architecture

## Shape

One SwiftPM library target, `StrideMetrics`, with no dependencies beyond Foundation.

```
Sources/StrideMetrics/
  Core/         Value types: RunningInterval (input), Pace, Cadence,
                Provenance + Sourced, MetricResult + UnavailableReason
  Validation/   ValidationError and the finite / non-negative / positive checks
  Metrics/      RunningMetrics and one file per metric family (formulas live here)
Tests/StrideMetricsTests/
```

The folders are organisational, not separate modules. Splitting into multiple targets
adds `public`-boundary overhead without benefit at this size; revisit when a part
genuinely needs to be used without the rest.

An `Estimation/` area is planned (ground contact time, stability, symmetry), but
nothing in it exists yet, so there is no folder for it.

## Data flow

```
raw values ──► RunningInterval(...)  ── throws ValidationError if invalid
                     │
                     ▼
              RunningMetrics(interval)
                     │
     speed / pace / cadence / stepLength / strideLength
                     │
         MetricResult: .available(value, provenance)
                    | .unavailable(reason)
```

## Design decisions

**Invalid ≠ unavailable ≠ zero ≠ missing.**
- *Invalid* (NaN, negative, zero duration): rejected when the `RunningInterval` is created. A `RunningInterval` that exists is valid.
- *Missing*: an optional input is `nil`. Metrics that need it return `.unavailable(.missing…)`.
- *Undefined*: e.g. pace at 0 m returns `.unavailable(.noDistanceCovered)`.
- *Zero*: a real value (0 m/s), returned as `.available`.

**Foundation `Measurement` for units.** Length, duration and speed use `Measurement<UnitLength/UnitDuration/UnitSpeed>`, so conversion and unit safety come from the platform and an app can format results with `MeasurementFormatter` directly. Custom types exist only where Foundation has no unit: `Pace` (time per distance) and `Cadence` (steps per time).

**Provenance on every input and result.** See [Metrics.md](Metrics.md#provenance).

**Everything is an immutable `Sendable` value type.** Results can be computed on any thread or actor and handed to UI code. Calculations are pure and cheap, so the API is synchronous; `async` would add nothing.

**Typed throws.** `RunningInterval.init` and the `Pace` initialisers throw `ValidationError` specifically (`throws(ValidationError)`), so callers can switch over cases exhaustively.

**No `Codable` yet.** Synthesised decoding would bypass the validating initialisers. Add it with a custom `init(from:)` that re-validates, when persistence is needed.

## Integration boundary (for the future iOS app)

The library does not import CoreMotion, CoreLocation, HealthKit or SwiftUI. An app
adapter is expected to:

1. Read sensor data (e.g. `CMPedometerData.numberOfSteps`, CoreLocation track distance, workout elapsed time).
2. Tag each value's provenance honestly (see the table in Metrics.md).
3. Build a `RunningInterval`, handling `ValidationError` (usually a sensor glitch worth logging).
4. Compute `RunningMetrics` and display `.available` values; show `.unavailable` reasons rather than zeros.

## Adding a metric

1. Write its definition, inputs, units, assumptions and limitations in `docs/Metrics.md` first, with a citable source.
2. Add a `MetricResult` property to `RunningMetrics` and a formula in `Metrics/RunningMetrics+<Name>.swift`.
3. Add any new inputs to `RunningInterval` as optional `Sourced` values, validated in its initialiser.
4. Test against independently calculated reference values, plus missing, zero and provenance cases.
