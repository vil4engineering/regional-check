import CarPlay
import Observation
import UIKit

@MainActor
final class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    private var interfaceController: CPInterfaceController?
    private var connectionGate = CarPlayConnectionGate()

    private var location: LocationManager {
        AppDependencies.location
    }

    private var regions: RegionSelection {
        AppDependencies.regions
    }

    private var status: StatusController {
        AppDependencies.status
    }

    func templateApplicationScene(
        _: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController
    ) {
        handleConnect(interfaceController)
    }

    func templateApplicationScene(
        _: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController,
        to _: CPWindow
    ) {
        handleConnect(interfaceController)
    }

    func templateApplicationScene(
        _: CPTemplateApplicationScene,
        didDisconnectInterfaceController _: CPInterfaceController
    ) {
        handleDisconnect()
    }

    func templateApplicationScene(
        _: CPTemplateApplicationScene,
        didDisconnect _: CPInterfaceController,
        from _: CPWindow
    ) {
        handleDisconnect()
    }

    private func handleConnect(_ interfaceController: CPInterfaceController) {
        guard connectionGate.connect() else { return }
        self.interfaceController = interfaceController
        location.beginUpdating()
        status.setRegion(regions.selectedRegion)

        let initialTemplate = makeRootTemplate(state: status.state, regionTitle: status.regionTitle)
        interfaceController.setRootTemplate(initialTemplate, animated: false) { _, _ in }

        armRegionObservation()
        armLocationObservation()
        armStatusObservation()
        status.beginPeriodicRefresh()
        AppDependencies.liveActivity.beginCarPlaySession()
        AppDependencies.syncLiveActivityContent()

        Task { @MainActor [weak self] in
            guard let self, connectionGate.isConnected else { return }
            await status.refresh()
            AppDependencies.syncLiveActivityContent()
            await render(animated: true)
        }
    }

    private func handleDisconnect() {
        guard connectionGate.disconnect() else { return }
        interfaceController = nil
        status.endPeriodicRefresh()
        location.endUpdating()
        AppDependencies.liveActivity.endCarPlaySession()
    }

    private func armRegionObservation() {
        armObservation {
            _ = regions.selectedRegion
        } onChange: { [weak self] in
            guard let self else { return }
            status.setRegion(regions.selectedRegion)
            await status.refresh()
            AppDependencies.syncLiveActivityContent()
            await render(animated: true)
        }
    }

    private func armStatusObservation() {
        armObservation {
            _ = status.state
            _ = status.regionTitle
        } onChange: { [weak self] in
            guard let self else { return }
            await render(animated: true)
            AppDependencies.syncLiveActivityContent()
        }
    }

    private func armLocationObservation() {
        armObservation {
            _ = location.coordinateStamp
            _ = location.authorizationStatus
        } onChange: { [weak self] in
            guard let self else { return }
            if let fix = location.lastFix {
                regions.updateFromLocation(fix: fix)
            }
            await render(animated: true)
        }
    }

    private func armObservation(
        track: @escaping @MainActor () -> Void,
        onChange: @escaping @MainActor () async -> Void
    ) {
        guard connectionGate.isConnected else { return }
        withObservationTracking {
            track()
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                guard let self, connectionGate.isConnected else { return }
                armObservation(track: track, onChange: onChange)
                await onChange()
            }
        }
    }

    private func render(animated: Bool) async {
        guard let interfaceController else { return }
        do {
            try await interfaceController.setRootTemplate(
                makeRootTemplate(state: status.state, regionTitle: status.regionTitle),
                animated: animated
            )
        } catch {}
    }

    private func makeRootTemplate(state: StatusState, regionTitle: String) -> CPTemplate {
        var items = [
            CPInformationItem(title: regionTitle, detail: state.detailText),
        ]
        items.append(CPInformationItem(title: state.explanation, detail: nil))
        if status.isDataStale {
            items.append(
                CPInformationItem(
                    title: NSLocalizedString("status.stale", comment: ""),
                    detail: nil
                )
            )
        }
        if location.isAuthorizationBlocked {
            items.append(
                CPInformationItem(
                    title: NSLocalizedString("location.access.denied.carplay", comment: ""),
                    detail: nil
                )
            )
        }

        let refresh = CPTextButton(
            title: NSLocalizedString("Refresh", comment: ""),
            textStyle: .confirm
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                await status.refresh()
                AppDependencies.syncLiveActivityContent()
                await render(animated: true)
            }
        }

        return CPInformationTemplate(
            title: state.title,
            layout: .leading,
            items: items,
            actions: [refresh]
        )
    }
}
