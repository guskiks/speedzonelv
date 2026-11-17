import Foundation

/// Phase 1 demo drive.
///
/// This is intentionally *not* a GPS simulation pretending to be real driving.
/// It produces a deterministic 1.2 km scenario and feeds the same
/// `SpeedCalculationEngine` that the production session will use. The UI marks
/// every frame as demo data.
@MainActor
final class DemoRideSimulator {
    var onUpdate: ((RideSnapshot) -> Void)?

    private let zone = SpeedZone.demo
    private var timer: Timer?
    private var lastTick: Date?

    private var phase: RidePhase = .approaching
    private var currentSpeedKmh: Double = 72
    private var approachRemainingMeters: Double = 260
    private var travelledMeters: Double = 0
    private var elapsed: TimeInterval = 0
    private var startSpeedKmh: Double?
    private var targetSpeedKmh: Int = 90

    private var startedAt = Date()
    private var samples: [SpeedSample] = []
    private var lastSampleAt: Date?

    deinit {
        timer?.invalidate()
    }

    func start(targetSpeedKmh: Int? = nil) {
        stop()

        self.targetSpeedKmh = targetSpeedKmh ?? zone.speedLimitKmh
        phase = .approaching
        currentSpeedKmh = 72
        approachRemainingMeters = 260
        travelledMeters = 0
        elapsed = 0
        startSpeedKmh = nil
        startedAt = Date()
        samples = []
        lastSampleAt = nil
        lastTick = Date()

        publish()

        let timer = Timer(timeInterval: 0.33, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        lastTick = nil
    }

    private func tick() {
        guard let lastTick else { return }
        let now = Date()
        let delta = min(max(now.timeIntervalSince(lastTick), 0), 1)
        self.lastTick = now
        guard delta > 0 else { return }

        switch phase {
        case .approaching:
            currentSpeedKmh = min(88, currentSpeedKmh + 4.5 * delta)
            currentSpeedKmh += Double.random(in: -0.6...0.6)
            currentSpeedKmh = min(max(currentSpeedKmh, 60), 92)

            approachRemainingMeters -= (currentSpeedKmh / 3.6) * delta

            if approachRemainingMeters <= 0 {
                let overshoot = max(-approachRemainingMeters, 0)
                phase = .active
                startSpeedKmh = currentSpeedKmh
                elapsed = 0
                travelledMeters = min(overshoot, zone.officialLengthMeters)
                approachRemainingMeters = 0
                appendSample(force: true)
            }

        case .active:
            elapsed += delta
            let target = 88 + 5.5 * sin(elapsed / 5.8)
            currentSpeedKmh = target + Double.random(in: -1.2...1.2)
            currentSpeedKmh = min(max(currentSpeedKmh, 78), 97)
            travelledMeters += (currentSpeedKmh / 3.6) * delta

            if travelledMeters >= zone.officialLengthMeters {
                travelledMeters = zone.officialLengthMeters
                appendSample(force: true)
                currentSpeedKmh = 0
                phase = .completed
                timer?.invalidate()
                timer = nil
            } else {
                appendSample(force: false)
            }

        case .completed:
            timer?.invalidate()
            timer = nil
        }

        publish()
    }

    private func appendSample(force: Bool) {
        let now = Date()
        let elapsed = max(now.timeIntervalSince(startedAt), 0)
        if !force,
           let lastSampleAt,
           now.timeIntervalSince(lastSampleAt) < 0.9 {
            return
        }

        samples.append(
            SpeedSample(
                distanceMeters: travelledMeters,
                speedKmh: currentSpeedKmh,
                elapsed: elapsed,
                timestamp: now
            )
        )
        lastSampleAt = now
    }

    private func publish() {
        let remaining = max(zone.officialLengthMeters - travelledMeters, 0)
        let average = SpeedCalculationEngine.averageSpeedKmh(
            distanceMeters: travelledMeters,
            duration: elapsed
        )

        let predicted: Double?
        let recommended: Double?

        switch phase {
        case .approaching:
            predicted = nil
            recommended = nil
        case .active:
            predicted = SpeedCalculationEngine.predictedAverageKmh(
                distanceTravelledMeters: travelledMeters,
                totalDistanceMeters: zone.officialLengthMeters,
                elapsed: elapsed,
                currentSpeedKmh: currentSpeedKmh
            )
            recommended = SpeedCalculationEngine.recommendedRemainingAverageKmh(
                distanceTravelledMeters: travelledMeters,
                totalDistanceMeters: zone.officialLengthMeters,
                elapsed: elapsed,
                targetAverageKmh: Double(targetSpeedKmh)
            )
        case .completed:
            predicted = average
            recommended = nil
        }

        let snapshot = RideSnapshot(
            phase: phase,
            zone: zone,
            currentSpeedKmh: currentSpeedKmh,
            targetSpeedKmh: targetSpeedKmh,
            averageSpeedKmh: phase == .approaching ? nil : average,
            startSpeedKmh: startSpeedKmh,
            distanceTravelledMeters: travelledMeters,
            remainingDistanceMeters: remaining,
            distanceToEntryMeters: phase == .approaching ? max(approachRemainingMeters, 0) : nil,
            elapsed: elapsed,
            estimatedRemainingTime: phase == .active
                ? SpeedCalculationEngine.estimatedRemainingTime(
                    remainingDistanceMeters: remaining,
                    currentSpeedKmh: currentSpeedKmh
                )
                : nil,
            predictedAverageKmh: predicted,
            recommendedAverageKmh: recommended,
            progress: min(max(travelledMeters / zone.officialLengthMeters, 0), 1),
            accuracyMeters: phase == .approaching
                ? Double.random(in: 8...14)
                : Double.random(in: 4...8),
            isDemo: true,
            capturedAt: Date(),
            samples: samples
        )

        onUpdate?(snapshot)
    }
}
