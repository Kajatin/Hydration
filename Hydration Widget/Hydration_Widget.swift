//
//  Hydration_Widget.swift
//  Hydration Widget
//
//  Created by Roland Kajatin on 26/06/2022.
//

import WidgetKit
import SwiftUI

extension Color {
    public init(description: String) {
        let colors = [Color.brown, Color.indigo, Color.blue, Color.teal, Color.green, Color.yellow, Color.orange, Color.red, Color.pink]
        if let color = colors.first(where: { $0.description == description }) {
            self = color
        } else {
            self = .blue
        }
    }
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> HydrationWidgetEntry {
        HydrationWidgetEntry(date: Date.now, target: 3000, progress: 1650)
    }

    func getSnapshot(in context: Context, completion: @escaping (HydrationWidgetEntry) -> ()) {
        let target: Float = 3000
        let progress: Float = 1650
        let entry: HydrationWidgetEntry
        
        if context.isPreview {
            entry = HydrationWidgetEntry(date: Date.now, target: target, progress: progress)
        } else {
            // Get widget data from UserDefaults
            let userDefaults = UserDefaults(suiteName: "group.widget.com.gmail.roland.kajatin")
            let target = userDefaults?.value(forKey: "target") as? Float ?? 3000
            let progress = userDefaults?.value(forKey: "progress") as? Float ?? 0
            let colorDescription = userDefaults?.value(forKey: "color") as? String ?? "blue"
            let color = Color(description: colorDescription)
            entry = HydrationWidgetEntry(date: Date.now, target: target, progress: progress, color: color)
        }
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [HydrationWidgetEntry] = []

        // Get widget data from UserDefaults
        let userDefaults = UserDefaults(suiteName: "group.widget.com.gmail.roland.kajatin")
        let target = userDefaults?.value(forKey: "target") as? Float ?? 3000
        let progress = userDefaults?.value(forKey: "progress") as? Float ?? 0
        let colorDescription = userDefaults?.value(forKey: "color") as? String ?? "blue"
        let color = Color(description: colorDescription)
        entries.append(HydrationWidgetEntry(date: Date.now, target: target, progress: progress, color: color))

        let timeline = Timeline(entries: entries, policy: .never)
        completion(timeline)
    }
}

struct HydrationWidgetEntry: TimelineEntry {
    var date: Date
    var target: Float
    var progress: Float
    var color: Color = .blue
}

struct Hydration_WidgetEntryView : View {
    @Environment(\.widgetFamily) var family: WidgetFamily
    @Environment(\.widgetRenderingMode) var renderingMode: WidgetRenderingMode
    
    var entry: Provider.Entry
    
    @ViewBuilder
    var body: some View {
        switch family {
        case .accessoryCircular: HydrationProgressCircular(entry: entry)
        case .accessoryRectangular: HydrationProgressRectangular(entry: entry)
        case .accessoryInline: HydrationProgressInline(entry: entry)
        case .accessoryCorner: HydrationProgressCorner(entry: entry)
        default: HydrationProgressCircular(entry: entry)
        }
    }
}

struct HydrationProgressCircular: View {
    var entry: Provider.Entry

    var body: some View {
        Gauge(value: entry.progress, in: 0...entry.target) {
            Text("%")
        } currentValueLabel: {
            Text("\((100 * entry.progress / entry.target).rounded(.towardZero).formatted())")
        }
        .gaugeStyle(.circular)
        .tint(Gradient(colors: [entry.color.opacity(0.6), entry.color]))
    }
}

struct HydrationProgressRectangular: View {
    var entry: Provider.Entry
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: "drop.fill")
                    .foregroundColor(entry.color)
                    .widgetAccentable()
                Text("Hydration")
                    .font(.headline)
            }
            
            HStack {
                Text("\(entry.progress.formatted())")
                    .foregroundColor(entry.color)
                    .font(.headline)
                    .widgetAccentable()
//                    .privacySensitive()
                Text("mL consumed")
                    .font(.body)
            }
            
            ProgressView(value: entry.progress, total: entry.target) { }
                .tint(entry.color)
                .widgetAccentable()
        }
    }
}

struct HydrationProgressInline: View {
    var entry: Provider.Entry
    
    var body: some View {
        ViewThatFits{
            Text("\(entry.progress.formatted())/\(entry.target.formatted()) mL consumed")
            Text("\(entry.progress.formatted()) mL consumed")
            Text("\((100 * entry.progress / entry.target).rounded(.towardZero).formatted())% consumed")
            Text("\(entry.progress.formatted()) mL")
            Text("\((100 * entry.progress / entry.target).rounded(.towardZero).formatted())%")
        }
    }
}

struct HydrationProgressCorner: View {
    var entry: Provider.Entry
    
    var body: some View {
        Text("\((100 * entry.progress / entry.target).rounded(.towardZero).formatted())%")
            .font(.title)
            .widgetLabel {
                ProgressView(value: entry.progress, total: entry.target)
                    .tint(entry.color)
                    .widgetAccentable()
            }
    }
}

@main
struct Hydration_Widget: Widget {
    let kind: String = "com.widget.Hydration_Widget"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: Provider()
        ) { entry in
            Hydration_WidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Hydration Progress")
        .description("Shows your hydration progress towards the target")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline, .accessoryCorner])
    }
}

struct Hydration_Widget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            Hydration_WidgetEntryView(entry: HydrationWidgetEntry(date: Date.now, target: 3000, progress: 1650))
                .previewContext(WidgetPreviewContext(family: .accessoryCircular))
                .previewDisplayName("Circular")
            Hydration_WidgetEntryView(entry: HydrationWidgetEntry(date: Date.now, target: 3000, progress: 1650))
                .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
                .previewDisplayName("Rectangular")
            Hydration_WidgetEntryView(entry: HydrationWidgetEntry(date: Date.now, target: 3000, progress: 1650))
                .previewContext(WidgetPreviewContext(family: .accessoryInline))
                .previewDisplayName("Inline")
            Hydration_WidgetEntryView(entry: HydrationWidgetEntry(date: Date.now, target: 3000, progress: 1650))
                .previewContext(WidgetPreviewContext(family: .accessoryCorner))
                .previewDisplayName("Corner")
        }
    }
}
