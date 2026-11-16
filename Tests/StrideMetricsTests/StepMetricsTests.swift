import Foundation
import XCTest
@testable import StrideMetrics

final class StepMetricsTests: XCTestCase {
    // MARK: Cadence

    /// 1800 steps in 10 min → 180 steps/min, 3 steps/s.
    func testCadenceReference() throws {
        let cadence = try XCTUnwrap(RunningMetrics(try Fixture.interval(seconds: 600, steps: 1800)).cadence.value)
        XCTAssertEqual(cadence.stepsPerMinute, 180, accuracy: tolerance)
        XCTAssertEqual(cadence.stepsPerSecond, 3, accuracy: tolerance)
    }

    /// 1234 steps in 397 s → 74040 / 397 = 186.49874055416 steps/min.
    func testCadenceNonRoundReference() throws {
        let cadence = try XCTUnwrap(RunningMetrics(try Fixture.interval(seconds: 397, steps: 1234)).cadence.value)
        XCTAssertEqual(cadence.stepsPerMinute, 186.49874055415617, accuracy: tolerance)
    }

    func testCadenceUsesDurationUnit() throws {
        let interval = try RunningInterval(duration: Measurement(value: 2, unit: .minutes), stepCount: .measured(340))
        XCTAssertEqual(try XCTUnwrap(RunningMetrics(interval).cadence.value).stepsPerMinute, 170, accuracy: tolerance)
    }

    func testZeroStepsGivesZeroCadence() throws {
        let metrics = RunningMetrics(try Fixture.interval(seconds: 60, steps: 0))
        XCTAssertEqual(metrics.cadence, .available(Cadence(stepsPerMinute: 0), .derived))
    }

    func testMissingStepsGivesNoCadence() throws {
        XCTAssertEqual(RunningMetrics(try Fixture.interval(seconds: 60, meters: 200)).cadence, .unavailable(.missingStepCount))
    }

    func testCadenceProvenanceFollowsStepCount() throws {
        let measured = RunningMetrics(try Fixture.interval(seconds: 60, steps: 170, stepProvenance: .measured))
        let estimated = RunningMetrics(try Fixture.interval(seconds: 60, steps: 170, stepProvenance: .estimated))
        XCTAssertEqual(measured.cadence.provenance, .derived)
        XCTAssertEqual(estimated.cadence.provenance, .estimated)
    }

    // MARK: Step and stride length

    /// 3000 m over 2700 steps → 1.1111… m per step, 2.2222… m per stride.
    func testStepAndStrideLengthReference() throws {
        let metrics = RunningMetrics(try Fixture.interval(seconds: 900, meters: 3000, steps: 2700))
        XCTAssertEqual(try XCTUnwrap(metrics.stepLength.value).value, 10.0 / 9.0, accuracy: tolerance)
        XCTAssertEqual(try XCTUnwrap(metrics.strideLength.value).value, 20.0 / 9.0, accuracy: tolerance)
    }

    /// Identity check: speed = cadence × step length (v = (n/t)(d/n) = d/t).
    func testSpeedEqualsCadenceTimesStepLength() throws {
        let metrics = RunningMetrics(try Fixture.interval(seconds: 397, meters: 1234.5, steps: 1111))
        let speed = try XCTUnwrap(metrics.speed.value).value
        let stepsPerSecond = try XCTUnwrap(metrics.cadence.value).stepsPerSecond
        let stepLength = try XCTUnwrap(metrics.stepLength.value).value
        XCTAssertEqual(stepsPerSecond * stepLength, speed, accuracy: tolerance)
    }

    func testStepLengthConvertsDistanceUnit() throws {
        let interval = try RunningInterval(
            duration: Measurement(value: 10, unit: .minutes),
            distance: .measured(Measurement(value: 1, unit: .miles)),
            stepCount: .measured(1000)
        )
        let step = try XCTUnwrap(RunningMetrics(interval).stepLength.value)
        XCTAssertEqual(step.converted(to: .meters).value, 1.609344, accuracy: tolerance)
    }

    func testZeroDistanceWithStepsGivesZeroStepLength() throws {
        let metrics = RunningMetrics(try Fixture.interval(seconds: 60, meters: 0, steps: 160))
        XCTAssertEqual(try XCTUnwrap(metrics.stepLength.value).value, 0)
        XCTAssertEqual(try XCTUnwrap(metrics.strideLength.value).value, 0)
    }

    func testZeroStepsGivesNoStepLength() throws {
        let metrics = RunningMetrics(try Fixture.interval(seconds: 60, meters: 100, steps: 0))
        XCTAssertEqual(metrics.stepLength, .unavailable(.noStepsTaken))
        XCTAssertEqual(metrics.strideLength, .unavailable(.noStepsTaken))
    }

    func testMissingInputsForStepLength() throws {
        XCTAssertEqual(RunningMetrics(try Fixture.interval(seconds: 60, steps: 100)).stepLength, .unavailable(.missingDistance))
        XCTAssertEqual(RunningMetrics(try Fixture.interval(seconds: 60, meters: 100)).stepLength, .unavailable(.missingStepCount))
        // Both missing: distance is reported first (documented order).
        XCTAssertEqual(RunningMetrics(try Fixture.interval(seconds: 60)).strideLength, .unavailable(.missingDistance))
    }

    func testStepLengthProvenanceCombinesInputs() throws {
        func provenance(_ d: Provenance, _ s: Provenance) throws -> Provenance? {
            RunningMetrics(try Fixture.interval(seconds: 60, meters: 200, steps: 170, distanceProvenance: d, stepProvenance: s))
                .strideLength.provenance
        }
        XCTAssertEqual(try provenance(.measured, .measured), .derived)
        XCTAssertEqual(try provenance(.estimated, .measured), .estimated)
        XCTAssertEqual(try provenance(.measured, .estimated), .estimated)
        XCTAssertEqual(try provenance(.derived, .measured), .derived)
    }
}
