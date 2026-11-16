import Foundation
import XCTest
@testable import StrideMetrics

final class SpeedPaceTests: XCTestCase {
    // MARK: Reference examples

    /// 5 km in 25:00 → 3.333… m/s = 12 km/h; 300 s/km; 482.8032 s/mi (300 × 1.609344).
    func testFiveKilometersInTwentyFiveMinutes() throws {
        let metrics = RunningMetrics(try Fixture.interval(seconds: 1500, meters: 5000))

        let speed = try XCTUnwrap(metrics.speed.value)
        XCTAssertEqual(speed.converted(to: .metersPerSecond).value, 10.0 / 3.0, accuracy: tolerance)
        XCTAssertEqual(speed.converted(to: .kilometersPerHour).value, 12, accuracy: kmhTolerance)

        let pace = try XCTUnwrap(metrics.pace.value)
        XCTAssertEqual(pace.duration(per: .kilometers).converted(to: .seconds).value, 300, accuracy: tolerance)
        XCTAssertEqual(pace.duration(per: .kilometers).converted(to: .minutes).value, 5, accuracy: tolerance)
        XCTAssertEqual(pace.duration(per: .miles).converted(to: .seconds).value, 482.8032, accuracy: tolerance)
    }

    /// 42.195 km in 2:00:35 (7235 s) → 5.83206634416 m/s, 171.465813485 s/km.
    func testMarathon() throws {
        let interval = try RunningInterval(
            duration: Measurement(value: 7235, unit: .seconds),
            distance: .measured(Measurement(value: 42.195, unit: .kilometers))
        )
        let metrics = RunningMetrics(interval)

        XCTAssertEqual(try XCTUnwrap(metrics.speed.value).value, 5.8320663441603315, accuracy: tolerance)
        XCTAssertEqual(
            try XCTUnwrap(metrics.pace.value).duration(per: .kilometers).value,
            171.46581348501007, accuracy: tolerance
        )
    }

    /// 1 mile in 6:00 → exactly 10 mph = 4.4704 m/s; 223.69362920544 s/km.
    func testSixMinuteMile() throws {
        let interval = try RunningInterval(
            duration: Measurement(value: 6, unit: .minutes),
            distance: .measured(Measurement(value: 1, unit: .miles))
        )
        let metrics = RunningMetrics(interval)

        let speed = try XCTUnwrap(metrics.speed.value)
        XCTAssertEqual(speed.value, 4.4704, accuracy: tolerance)
        XCTAssertEqual(speed.converted(to: .milesPerHour).value, 10, accuracy: tolerance)
        XCTAssertEqual(
            try XCTUnwrap(metrics.pace.value).duration(per: .kilometers).value,
            223.6936292054402, accuracy: tolerance
        )
    }

    // MARK: Pace ⇄ speed conversion

    func testPaceFromSpeed() throws {
        let pace = try Pace(speed: Measurement(value: 4, unit: .metersPerSecond))
        XCTAssertEqual(pace.duration(per: .kilometers).value, 250, accuracy: tolerance)

        let fromKmh = try Pace(speed: Measurement(value: 15, unit: .kilometersPerHour))
        XCTAssertEqual(fromKmh.duration(per: .kilometers).value, 240, accuracy: 240 * kmhRelativeError)
    }

    func testExplicitPaceMatchesSpeed() throws {
        let pace = try Pace(Measurement(value: 4, unit: .minutes), per: Measurement(value: 1, unit: .kilometers))
        XCTAssertEqual(pace.secondsPerMeter, 0.24, accuracy: tolerance)
        XCTAssertEqual(pace.speed.value, 15 / 3.6, accuracy: tolerance)
        XCTAssertEqual(pace.speed.converted(to: .kilometersPerHour).value, 15, accuracy: kmhTolerance)
    }

    func testRoundTrip() throws {
        for metersPerSecond in [0.5, 2.78, 4.4704, 6.2, 10.44] {
            let speed = Measurement(value: metersPerSecond, unit: UnitSpeed.metersPerSecond)
            XCTAssertEqual(try Pace(speed: speed).speed.value, metersPerSecond, accuracy: tolerance)
        }
    }

    // MARK: Regression: Foundation km/h coefficient

    /// Found while writing this suite: Foundation defines km/h as 0.277778 m/s instead
    /// of 1/3.6, a relative error of 8e-7. The library calculates in m/s and is exact;
    /// only conversions to/from km/h inherit the error. If this test starts failing,
    /// Foundation fixed the coefficient and `kmhTolerance` can be tightened.
    func testFoundationKilometersPerHourCoefficientIsRounded() {
        let oneKmh = Measurement(value: 1, unit: UnitSpeed.kilometersPerHour).converted(to: .metersPerSecond).value
        XCTAssertEqual(oneKmh, 0.277778)
        XCTAssertNotEqual(oneKmh, 1 / 3.6)
    }

    // MARK: Zero vs missing

    func testZeroDistanceGivesZeroSpeedButNoPace() throws {
        let metrics = RunningMetrics(try Fixture.interval(seconds: 60, meters: 0))
        XCTAssertEqual(metrics.speed, .available(Measurement(value: 0, unit: .metersPerSecond), .derived))
        XCTAssertEqual(metrics.pace, .unavailable(.noDistanceCovered))
    }

    func testMissingDistance() throws {
        let metrics = RunningMetrics(try Fixture.interval(seconds: 60, steps: 170))
        XCTAssertEqual(metrics.speed, .unavailable(.missingDistance))
        XCTAssertEqual(metrics.pace, .unavailable(.missingDistance))
        XCTAssertNil(metrics.speed.value)
        XCTAssertNil(metrics.speed.provenance)
    }

    // MARK: Provenance

    func testMeasuredDistanceGivesDerivedSpeed() throws {
        let metrics = RunningMetrics(try Fixture.interval(seconds: 600, meters: 2000, distanceProvenance: .measured))
        XCTAssertEqual(metrics.speed.provenance, .derived)
        XCTAssertEqual(metrics.pace.provenance, .derived)
    }

    func testEstimatedDistanceGivesEstimatedSpeed() throws {
        let metrics = RunningMetrics(try Fixture.interval(seconds: 600, meters: 2000, distanceProvenance: .estimated))
        XCTAssertEqual(metrics.speed.provenance, .estimated)
        XCTAssertEqual(metrics.pace.provenance, .estimated)
    }
}
