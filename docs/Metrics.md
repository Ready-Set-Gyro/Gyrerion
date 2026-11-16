# Metric definitions

Every metric is an **interval average**: it describes one `RunningInterval` as a whole,
not instantaneous values within it. All calculations are done in SI base units
(metres, seconds) and converted only when the caller asks.

Notation: `t` = duration (s, always > 0), `d` = distance (m, ≥ 0), `n` = step count (≥ 0).

## Provenance

Inputs are tagged by the caller as `.measured` or `.estimated`. A calculated result is:

- `.derived` if every input it uses is measured or derived;
- `.estimated` if any input it uses is estimated.

Results are never `.measured`. Duration is treated as measured (a clock).

Why this matters: GPS distance and pedometer distance are not equivalent.

| Input source | Typical provenance | Notes |
|---|---|---|
| GPS track distance | measured | Noisy; error grows with poor signal, tall buildings, tree cover, and short intervals. |
| Measured track / course | measured | |
| Pedometer step count | measured | A detection algorithm on accelerometer data; can miss or add steps. |
| Pedometer / accelerometer distance | estimated | Usually step count × a modelled step length. |
| Treadmill belt distance | measured | Accuracy depends on treadmill calibration. |

The library does not decide provenance for you. Tag inputs honestly; results follow.

## Speed

**Definition:** average speed `v = d / t`.
**Inputs:** distance, duration. **Unit:** m/s (`Measurement<UnitSpeed>`).
**Unavailable:** `.missingDistance` if distance is nil.
**Zero:** `d = 0` gives `v = 0`, which is available (the runner did not move).
**Limitations:** average over the interval; says nothing about variation within it.

## Pace

**Definition:** average pace `p = t / d = 1 / v`.
**Inputs:** distance, duration. **Unit:** stored as s/m. Read it with `duration(per: .kilometers)`, `duration(per: .miles)`, etc.
**Unavailable:** `.missingDistance`; `.noDistanceCovered` when `d = 0` (division by zero; pace is undefined, not infinite).
**Limitations:** because pace is a reciprocal, averaging paces from several intervals is **not** the same as the pace over the combined interval. Combine distances and durations, then calculate. This library does not yet combine intervals.

`Pace(speed:)` and `Pace(_:per:)` construct a pace directly. Both reject zero, negative, or non-finite inputs.

## Cadence

**Definition:** `c = 60 · n / t` steps per minute, counting steps of **both** feet.
**Inputs:** step count, duration. **Unit:** steps/min (`Cadence.stepsPerMinute`), or steps/s.
**Unavailable:** `.missingStepCount`.
**Zero:** `n = 0` gives `c = 0`, which is available.
**Limitations:** some devices report cadence per foot ("strides per minute"), which is half this value. Accuracy is bounded by the step detector.

## Step length and stride length

**Definitions:**
- step length `L_step = d / n`: distance between successive foot contacts (left → right).
- stride length `L_stride = 2 · d / n`: distance of one full gait cycle (left → left), i.e. two steps.

**Inputs:** distance, step count. **Unit:** metres (`Measurement<UnitLength>`).
**Unavailable:** `.missingDistance`, then `.missingStepCount` (checked in that order); `.noStepsTaken` when `n = 0`.
**Zero:** `d = 0` with `n > 0` gives `0 m`, which is available (e.g. running in place).

**Assumptions and limitations:**
- Averages over all steps. Left and right steps are not distinguished; this is **not** a symmetry measure.
- **Circularity:** if distance came from a pedometer that itself computed distance as steps × a modelled step length, then `d / n` returns that model's assumption, not an independent measurement. Tag such distance as `.estimated`; the result will be `.estimated` too.
- Terminology varies. Apple HealthKit's `runningStrideLength` is documented as the distance of a single step, so it corresponds to **step length** here.

## Identity used in tests

`v = c_per_second · L_step`, because `(n/t)(d/n) = d/t`. The test suite checks it as a consistency test.

## Numerical notes

- Inputs are validated: NaN, infinities, negatives, and zero duration are rejected.
- Expected values in tests come from independent hand/Python calculation and are compared with an absolute tolerance of 1e-9.
- Foundation defines `UnitSpeed.kilometersPerHour` as 0.277778 m/s (not exactly 1/3.6). The library's results are exact in m/s; converting to km/h introduces a relative error of about 8 × 10⁻⁷ (0.00001 km/h at 12 km/h). `UnitSpeed.knots` is similarly rounded. Length, duration, and mph conversions are exact.

## References

- Cavanagh, P. R. & Kram, R. (1989). Stride length in distance running: velocity, body dimensions, and added mass effects. *Medicine & Science in Sports & Exercise*, 21(4), 467–479. (Step vs stride terminology.)
- Apple Developer Documentation: `HKQuantityTypeIdentifier.runningStrideLength`.
