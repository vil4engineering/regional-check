import AppIntents
import DriveCheckKit
import SwiftUI
import WidgetKit

struct DriveCheckSecondaryRegionWidget: Widget {
    let kind = "DriveCheckSecondaryRegionWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: SelectSecondaryRegionIntent.self,
            provider: DriveCheckSecondaryRegionProvider()
        ) { entry in
            DriveCheckSecondaryRegionView(entry: entry)
        }
        .configurationDisplayName("widget.secondary.title")
        .description("widget.secondary.description")
        .supportedFamilies([.systemSmall, .accessoryRectangular])
    }
}

struct SelectSecondaryRegionIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "widget.secondary.configure"

    @Parameter(title: "intent.region.parameter")
    var region: AlertRegion?

    func perform() async throws -> some IntentResult {
        if let region {
            SharedStore.shared.saveSecondaryRegion(region)
        }
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

struct DriveCheckSecondaryRegionProvider: AppIntentTimelineProvider {
    typealias Entry = DriveCheckSecondaryRegionEntry
    typealias Intent = SelectSecondaryRegionIntent

    func placeholder(in _: Context) -> DriveCheckSecondaryRegionEntry {
        DriveCheckSecondaryRegionEntry(date: Date(), region: .lviv, presentation: nil)
    }

    func snapshot(for configuration: SelectSecondaryRegionIntent,
                  in _: Context) async -> DriveCheckSecondaryRegionEntry
    {
        makeEntry(configuration: configuration)
    }

    func timeline(for configuration: SelectSecondaryRegionIntent,
                  in _: Context) async -> Timeline<DriveCheckSecondaryRegionEntry>
    {
        let entry = makeEntry(configuration: configuration)
        return Timeline(entries: [entry], policy: .after(WidgetTimelineBuilder.reloadDate(from: entry.date)))
    }

    private func makeEntry(configuration: SelectSecondaryRegionIntent) -> DriveCheckSecondaryRegionEntry {
        let store = SharedStore.shared
        if let configured = configuration.region {
            store.saveSecondaryRegion(configured)
        }
        let region = store.loadSecondaryRegion() ?? .kyivCity
        let presentation = store.loadIsPro()
            ? WidgetTimelineBuilder.presentation(store: store, region: region)
            : nil
        return DriveCheckSecondaryRegionEntry(date: Date(), region: region, presentation: presentation)
    }
}

struct DriveCheckSecondaryRegionEntry: TimelineEntry {
    let date: Date
    let region: AlertRegion
    let presentation: WidgetStatusPresentation?
}

struct DriveCheckSecondaryRegionView: View {
    let entry: DriveCheckSecondaryRegionEntry

    var body: some View {
        if let presentation = entry.presentation {
            VStack(alignment: .leading, spacing: 6) {
                Text(entry.region.title)
                    .font(.headline)
                Text(LocalizedStringKey(presentation.phase.titleKey))
                    .font(.subheadline)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .containerBackground(for: .widget) { Color(.systemBackground) }
        } else {
            Text("subscription.paywall.open")
                .font(.caption)
                .containerBackground(for: .widget) { Color(.systemBackground) }
        }
    }
}
