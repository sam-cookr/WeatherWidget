import XCTest
@testable import WeatherWidget

final class RetryPolicyTests: XCTestCase {
    func testCanAttemptImmediatelyOnStart() {
        let policy = RetryPolicy()
        XCTAssertTrue(policy.canAttemptNow)
    }

    func testBackoffDelayAfterFailure() {
        let policy = RetryPolicy()
        policy.recordFailure()
        XCTAssertFalse(policy.canAttemptNow)
        XCTAssertGreaterThan(policy.nextRetryDelay, 0)
    }

    func testSuccessResetsPolicy() {
        let policy = RetryPolicy()
        policy.recordFailure()
        policy.recordSuccess()
        XCTAssertTrue(policy.canAttemptNow)
        XCTAssertEqual(policy.nextRetryDelay, 0)
    }

    func testDelaysAreMonotonicallyIncreasing() {
        let policy = RetryPolicy()
        var delays: [TimeInterval] = []
        for _ in 0..<5 {
            policy.recordFailure()
            delays.append(policy.nextRetryDelay)
            // Reset next-allowed so we can record failure again without waiting
            policy.recordSuccess()
        }
        // Each delay in the schedule should be >= the previous (base grows)
        // Note: delays here are all relative to 0 after reset, so we check the schedule property indirectly
        // by recording failures in sequence without resetting
        let policy2 = RetryPolicy()
        var seq: [TimeInterval] = []
        for _ in 0..<5 {
            policy2.recordFailure()
            seq.append(policy2.nextRetryDelay)
        }
        for i in 1..<seq.count {
            XCTAssertGreaterThanOrEqual(seq[i], seq[i-1], "Delay at step \(i) should be >= step \(i-1)")
        }
    }
}
