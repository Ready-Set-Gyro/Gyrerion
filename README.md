# StrideMetrics

A Swift library for calculating running performance metrics, the measurement
foundation for **Ready, Set, Gyro!**.

It turns validated interval data (duration, distance, step count) into speed, pace,
cadence, step length and stride length. Every result says whether it is available and
whether it was derived from measurements or depends on an estimate.

> StrideMetrics is a measurement and analysis tool. It is not a medical device, and its
> outputs are not clinically validated measurements.

## Status

| Metric | Status |
|---|---|
| Speed | Implemented |
| Pace | Implemented |
| Cadence | Implemented |
| Step length / stride length | Implemented |
| Ground contact time | Planned (estimation from accelerometer data) |
| Running stability | Planned |
| Left/right symmetry | Planned |

Only the implemented rows exist in the code.

## Requirements

- Swift 6.0+ toolchain (Swift 6 language mode)
- Foundation only; no third-party dependencies
- Apple platforms (iOS, watchOS, macOS). Linux should work via swift-corelibs-foundation but is untested.

## Installation

In `Package.swift`:

```swift
dependencies: [
    .package(url: "<repository-url>", branch: "main"),
],
targets: [
    .target(name: "YourTarget", dependencies: [
        .product(name: "StrideMetrics", package: "StrideMetrics"),
    ]),
]
```

In Xcode: **File ▸ Add Package Dependencies…**, enter the repository URL, then add the
`StrideMetrics` library to your app target. During local development you can add the
package folder itself with **Add Local…**.

## Usage

```swift
import Foundation
import StrideMetrics

let interval = try RunningInterval(
    duration: Measurement(value: 25, unit: .minutes),
    distance: .measured(Measurement(value: 5, unit: .kilometers)),  // e.g. GPS
    stepCount: .measured(4250)                                      // e.g. pedometer
)
let metrics = RunningMetrics(interval)

if case .available(let pace, let provenance) = metrics.pace {
    print(pace.duration(per: .kilometers).converted(to: .minutes))  // 5.0 min
    print(provenance)                                               // derived
}
print(metrics.cadence.value?.stepsPerMinute ?? "unavailable")          // 170.0
print(metrics.strideLength.value ?? "unavailable")                     // ≈2.353 m
```

This example is checked by `ReadmeExampleTests`.

### Missing, zero, and invalid data are different

```swift
// Missing: no distance supplied → distance-based metrics are unavailable, not zero.
let noGPS = RunningMetrics(try RunningInterval(
    duration: Measurement(value: 60, unit: .seconds),
    stepCount: .measured(170)
))
noGPS.speed    // .unavailable(.missingDistance)
noGPS.cadence  // .available(Cadence(stepsPerMinute: 170), .derived)

// Zero: standing still is a real speed; pace is undefined.
let standing = RunningMetrics(try RunningInterval(
    duration: Measurement(value: 60, unit: .seconds),
    distance: .measured(Measurement(value: 0, unit: .meters))
))
standing.speed  // .available(0.0 m/s, .derived)
standing.pace   // .unavailable(.noDistanceCovered)

// Invalid: rejected before any calculation.
do {
    _ = try RunningInterval(duration: Measurement(value: 0, unit: .seconds))
} catch {
    // error == .zero(.duration)
}
```

### Measured vs estimated inputs

```swift
// Distance from a pedometer model is an estimate, so every result that uses it is too.
let pedometerOnly = RunningMetrics(try RunningInterval(
    duration: Measurement(value: 10, unit: .minutes),
    distance: .estimated(Measurement(value: 1.9, unit: .kilometers)),
    stepCount: .measured(1700)
))
pedometerOnly.speed.provenance        // .estimated
pedometerOnly.cadence.provenance      // .derived (uses step count only)
pedometerOnly.stepLength.provenance   // .estimated
```

### Pace and speed conversions

```swift
let target = try Pace(Measurement(value: 4, unit: .minutes), per: Measurement(value: 1, unit: .kilometers))
target.duration(per: .miles)                          // ≈386.25 s
target.speed.converted(to: .kilometersPerHour)        // ≈15 km/h

let fromSpeed = try Pace(speed: Measurement(value: 4, unit: .metersPerSecond))
fromSpeed.duration(per: .kilometers)                  // 250 s
```

## Building an app around it

The library has no dependency on CoreMotion, CoreLocation, HealthKit or SwiftUI. All
public types are immutable `Sendable` values, so you can compute metrics anywhere and
pass them straight to a view. A typical app layer:

1. collects sensor values for an interval,
2. tags each one `.measured` or `.estimated` (see [docs/Metrics.md](docs/Metrics.md#provenance)),
3. builds a `RunningInterval` and handles any `ValidationError`,
4. displays `MetricResult` values, showing the unavailable reason instead of a misleading zero.

Use `MeasurementFormatter` (or `.formatted()`) to display `Measurement` results in the
user's locale.

## Documentation

- [docs/Metrics.md](docs/Metrics.md): mathematical definitions, inputs, units, assumptions, limitations
- [docs/Architecture.md](docs/Architecture.md): structure, design decisions, how to add a metric

## Development

```sh
swift build
swift test
```

## Known limitations

- Metrics are averages over one interval. Combining intervals and time-series analysis are not implemented yet.
- No physiological plausibility checks. A 50 m/s "run" is accepted; only mathematically invalid input is rejected.
- Foundation's km/h and knots units use rounded coefficients (relative error ~8 × 10⁻⁷). See [docs/Metrics.md](docs/Metrics.md#numerical-notes).
- `Pace(_:per:)` with extreme magnitudes (e.g. 1e300 s per 1e-300 m) can overflow to infinity; real running data is nowhere near this.
- No `Codable` conformance yet. See [docs/Architecture.md](docs/Architecture.md).
