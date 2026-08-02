import ActivityKit
import Foundation
import Observation
import os

@MainActor
@Observable
final class LiveActivityController: LiveActivityControlling {
    private static let log = Logger(subsystem: "vil4max.RegionalCheck", category: "LiveActivity")

    private let subscription: SubscriptionManager
    private let pipeline = LiveActivitySerialPipeline()
    private var clients: Set<LiveActivitySessionClient> = []
    private var activity: Activity<DriveCheckActivityAttributes>?
    private var latestPhase: DriveCheckActivityPhase = .idle
    private var latestRegionTitle = ""
    private var latestCheckedAt: Date?
    private var latestSourceLabel = ""

    init(subscription: SubscriptionManager) {
        self.subscription = subscription
    }

    func beginPhoneForegroundSession() {
        insert(.phoneForeground)
    }

    func endPhoneForegroundSession() {
        remove(.phoneForeground)
    }

    func beginCarPlaySession() {
        insert(.carPlay)
    }

    func endCarPlaySession() {
        remove(.carPlay)
    }

    func update(
        phase: DriveCheckActivityPhase,
        regionTitle: String,
        checkedAt: Date?,
        sourceLabel: String
    ) {
        latestPhase = phase
        latestRegionTitle = regionTitle
        latestCheckedAt = checkedAt
        latestSourceLabel = sourceLabel
        reconcileActivity()
    }

    func endAll() {
        clients.removeAll()
        reconcileActivity()
    }

    private var canRunActivity: Bool {
        subscription.allows(.liveActivity)
            && ActivityAuthorizationInfo().areActivitiesEnabled
    }

    private func insert(_ client: LiveActivitySessionClient) {
        clients.insert(client)
        reconcileActivity()
    }

    private func remove(_ client: LiveActivitySessionClient) {
        clients.remove(client)
        reconcileActivity()
    }

    private func reconcileActivity() {
        pipeline.enqueue { [weak self] in
            guard let self else { return }
            let action = LiveActivityLifecyclePolicy.nextAction(
                canRun: canRunActivity,
                hasClients: !clients.isEmpty,
                hasActivity: activity != nil
            )
            switch action {
            case .none:
                break
            case .start:
                await startIfNeeded()
            case .update:
                await pushUpdate()
            case .terminate:
                await terminate(dismissal: .immediate)
            }
        }
    }

    private func startIfNeeded() async {
        guard canRunActivity, activity == nil, !clients.isEmpty else { return }
        let attributes = DriveCheckActivityAttributes()
        let state = contentState()
        let content = ActivityContent(
            state: state,
            staleDate: activityStaleDate
        )
        do {
            activity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
        } catch {
            Self.log.error("Activity.request failed: \(String(describing: error), privacy: .public)")
        }
    }

    private func pushUpdate() async {
        guard let activity else { return }
        let content = ActivityContent(
            state: contentState(),
            staleDate: activityStaleDate
        )
        await activity.update(content)
    }

    private func terminate(dismissal: ActivityUIDismissalPolicy) async {
        guard let activity else { return }
        self.activity = nil
        let content = ActivityContent(state: contentState(), staleDate: nil)
        await activity.end(content, dismissalPolicy: dismissal)
    }

    private var activityStaleDate: Date {
        let interval = StatusController.periodicRefreshInterval
        let seconds = Double(interval.components.seconds)
            + Double(interval.components.attoseconds) / 1_000_000_000_000_000_000
        return LiveActivityStaleDate.make(
            checkedAt: latestCheckedAt,
            refreshInterval: seconds
        )
    }

    private func contentState() -> DriveCheckActivityAttributes.ContentState {
        DriveCheckActivityAttributes.ContentState(
            phase: latestPhase,
            regionTitle: latestRegionTitle,
            checkedAt: latestCheckedAt,
            sourceLabel: latestSourceLabel
        )
    }
}
