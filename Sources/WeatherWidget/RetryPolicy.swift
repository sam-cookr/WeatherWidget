import Foundation

/// Exponential-backoff retry policy with jitter. Resets on success or network reconnect.
/// Delays: 2s → 8s → 30s → 120s → 600s hold.
final class RetryPolicy {
    private let schedule: [TimeInterval] = [2, 8, 30, 120, 600]
    private var attempt = 0
    private var nextAllowedAt: Date = .distantPast

    var canAttemptNow: Bool {
        Date() >= nextAllowedAt
    }

    func recordSuccess() {
        attempt = 0
        nextAllowedAt = .distantPast
    }

    func recordFailure() {
        let base = attempt < schedule.count ? schedule[attempt] : schedule.last!
        let jitter = Double.random(in: 0...(base * 0.2))
        nextAllowedAt = Date().addingTimeInterval(base + jitter)
        attempt = min(attempt + 1, schedule.count)
    }

    var nextRetryDelay: TimeInterval {
        max(0, nextAllowedAt.timeIntervalSinceNow)
    }
}
