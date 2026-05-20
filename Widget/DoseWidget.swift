import WidgetKit
import SwiftUI
import DoseCore

struct DoseWidget: Widget {
    let kind: String = "DoseWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DoseTimelineProvider()) { entry in
            DoseWidgetEntryView(entry: entry)
                .containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("DoseLeft")
        .description("Days remaining for your medications.")
        .supportedFamilies([
            .systemSmall, .systemMedium,
            .accessoryCircular, .accessoryRectangular,
        ])
    }
}

struct DoseWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: DoseEntry

    var body: some View {
        switch family {
        case .systemSmall:        SmallDoseView(entry: entry)
        case .systemMedium:       MediumDoseView(entry: entry)
        case .accessoryCircular:  LockCircularView(entry: entry)
        case .accessoryRectangular: LockRectangularView(entry: entry)
        default:                  SmallDoseView(entry: entry)
        }
    }
}
