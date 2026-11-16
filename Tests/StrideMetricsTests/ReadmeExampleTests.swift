import Foundation
import StrideMetrics  // not @testable: the README must only use public API
import XCTest

/// Keeps README.md honest: this is the README "Usage" example, verbatim.
final class ReadmeExampleTests: XCTestCase {
    func testUsageExample() throws {
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

        XCTAssertEqual(metrics.pace.value?.duration(per: .kilometers).converted(to: .minutes).value ?? 0, 5, accuracy: 1e-9)
        XCTAssertEqual(metrics.pace.provenance, .derived)
        XCTAssertEqual(metrics.cadence.value?.stepsPerMinute ?? 0, 170, accuracy: 1e-9)
        XCTAssertEqual(metrics.strideLength.value?.value ?? 0, 10_000.0 / 4250.0, accuracy: 1e-9)
    }
}
