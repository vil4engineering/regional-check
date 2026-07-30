import ActivityKit
import Foundation
import Observation

@MainActor
@Observable
final class LiveActivityController: LiveActivityControlling {
    private let subscription: SubscriptionManager
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
        guard activity != nil, canRunActivity else { return }
        Task {
            await pushUpdate()
        }
    }

    func endAll() {
        clients.removeAll()
        Task {
            await terminate(dismissal: .immediate)
        }
    }

    private var canRunActivity: Bool {
        subscription.allows(.liveActivity)
            && ActivityAuthorizationInfo().areActivitiesEnabled
    }

    private func insert(_ client: LiveActivitySessionClient) {
        let wasEmpty = clients.isEmpty
        clients.insert(client)
        if wasEmpty {
            Task { await startIfNeeded() }
        }
    }

    private func remove(_ client: LiveActivitySessionClient) {
        clients.remove(client)
        if clients.isEmpty {
            Task { await terminate(dismissal: .immediate) }
        }
    }

    private func startIfNeeded() async {
        guard canRunActivity, activity == nil, !clients.isEmpty else { return }
        let attributes = DriveCheckActivityAttributes()
        let state = contentState()
        let content = ActivityContent(
            state: state,
            staleDate: Date().addingTimeInterval(600)
        )
        do {
            activity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
        } catch {}
    }

    private func pushUpdate() async {
        guard let activity else { return }
        let content = ActivityContent(
            state: contentState(),
            staleDate: Date().addingTimeInterval(600)
        )
        await activity.update(content)
    }

    private func terminate(dismissal: ActivityUIDismissalPolicy) async {
        guard let activity else { return }
        let content = ActivityContent(state: contentState(), staleDate: nil)
        await activity.end(content, dismissalPolicy: dismissal)
        self.activity = nil
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
