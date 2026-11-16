import Foundation
import XCTest
@testable import StrideMetrics

final class ValidationTests: XCTestCase {
    private func assertRejects(
        _ expected: ValidationError,
        file: StaticString = #filePath, line: UInt = #line,
        _ make: () throws -> Void
    ) {
        XCTAssertThrowsError(try make(), file: file, line: line) { error in
            XCTAssertEqual(error as? ValidationError, expected, file: file, line: line)
        }
    }

    // MARK: Duration

    func testRejectsZeroDuration() {
        assertRejects(.zero(.duration)) { _ = try Fixture.interval(seconds: 0) }
    }

    func testRejectsNegativeZeroDuration() {
        assertRejects(.zero(.duration)) { _ = try Fixture.interval(seconds: -0.0) }
    }

    func testRejectsNegativeDuration() {
        assertRejects(.negative(.duration)) { _ = try Fixture.interval(seconds: -1) }
    }

    func testRejectsNonFiniteDuration() {
        assertRejects(.notFinite(.duration)) { _ = try Fixture.interval(seconds: .nan) }
        assertRejects(.notFinite(.duration)) { _ = try Fixture.interval(seconds: .infinity) }
    }

    func testAcceptsSmallestPositiveDuration() throws {
        XCTAssertNoThrow(try Fixture.interval(seconds: .leastNonzeroMagnitude))
    }

    func testValidatesDurationInGivenUnit() {
        assertRejects(.negative(.duration)) {
            _ = try RunningInterval(duration: Measurement(value: -1, unit: .minutes))
        }
    }

    // MARK: Distance

    func testAcceptsZeroDistance() throws {
        XCTAssertNoThrow(try Fixture.interval(seconds: 60, meters: 0))
    }

    func testRejectsNegativeDistance() {
        assertRejects(.negative(.distance)) { _ = try Fixture.interval(seconds: 60, meters: -0.001) }
    }

    func testRejectsNonFiniteDistance() {
        assertRejects(.notFinite(.distance)) { _ = try Fixture.interval(seconds: 60, meters: .nan) }
        assertRejects(.notFinite(.distance)) { _ = try Fixture.interval(seconds: 60, meters: -.infinity) }
    }

    // MARK: Step count

    func testAcceptsZeroSteps() throws {
        XCTAssertNoThrow(try Fixture.interval(seconds: 60, steps: 0))
    }

    func testRejectsNegativeSteps() {
        assertRejects(.negative(.stepCount)) { _ = try Fixture.interval(seconds: 60, steps: -1) }
    }

    // MARK: Missing is not zero

    func testMissingInputsStayNil() throws {
        let interval = try Fixture.interval(seconds: 60)
        XCTAssertNil(interval.distance)
        XCTAssertNil(interval.stepCount)
    }

    // MARK: Pace inputs

    func testPaceRejectsZeroOrInvalidInputs() {
        assertRejects(.zero(.distance)) { _ = try Pace(Fixture.seconds(300), per: Fixture.meters(0)) }
        assertRejects(.zero(.duration)) { _ = try Pace(Fixture.seconds(0), per: Fixture.meters(1000)) }
        assertRejects(.negative(.duration)) { _ = try Pace(Fixture.seconds(-300), per: Fixture.meters(1000)) }
        assertRejects(.notFinite(.distance)) { _ = try Pace(Fixture.seconds(300), per: Fixture.meters(.nan)) }
    }

    func testPaceFromSpeedRejectsNonPositiveSpeed() {
        assertRejects(.zero(.speed)) { _ = try Pace(speed: Measurement(value: 0, unit: .metersPerSecond)) }
        assertRejects(.negative(.speed)) { _ = try Pace(speed: Measurement(value: -3, unit: .metersPerSecond)) }
        assertRejects(.notFinite(.speed)) { _ = try Pace(speed: Measurement(value: .infinity, unit: .metersPerSecond)) }
    }
}
