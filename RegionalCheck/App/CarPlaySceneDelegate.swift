import CarPlay
import Observation
import UIKit

@MainActor
final class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    private var interfaceController: CPInterfaceController?
    private var isConnected = false

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
        self.interfaceController = interfaceController
        isConnected = true
        location.beginUpdating()
        status.setRegion(regions.selectedRegion)

        let initialTemplate = makeRootTemplate(state: status.state, regionTitle: status.regionTitle)
        interfaceController.setRootTemplate(initialTemplate, animated: false) { _, _ in }

        armRegionObservation()
        armLocationObservation()
        armStatusObservation()
    }

    private func handleDisconnect() {
        isConnected = false
        interfaceController = nil
        location.endUpdating()
    }

    private func armRegionObservation() {
        guard isConnected else { return }
        withObservationTracking {
            _ = regions.selectedRegion
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                guard let self, isConnected else { return }
                status.setRegion(regions.selectedRegion)
                await render(animated: true)
                armRegionObservation()
            }
        }
    }

    private func armStatusObservation() {
        guard isConnected else { return }
        withObservationTracking {
            _ = status.state
            _ = status.regionTitle
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                guard let self, isConnected else { return }
                await render(animated: true)
                armStatusObservation()
            }
        }
    }

    private func armLocationObservation() {
        guard isConnected else { return }
        withObservationTracking {
            _ = location.coordinateStamp
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                guard let self, isConnected else { return }
                if let coordinate = location.coordinate {
                    regions.updateFromLocation(coordinate: coordinate)
                }
                armLocationObservation()
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

        let refresh = CPTextButton(
            title: NSLocalizedString("Refresh", comment: ""),
            textStyle: .confirm
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                await status.refresh()
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
