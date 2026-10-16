import SwiftUI
import UIKit
import WidgetKit

struct CarWidgetEntry: TimelineEntry {
  let date: Date
  let imageURL: URL?
  let widgetName: String?
}

struct CarWidgetProvider: TimelineProvider {
  let slot: Int

  func placeholder(in context: Context) -> CarWidgetEntry {
    CarWidgetEntry(date: .now, imageURL: nil, widgetName: nil)
  }

  func getSnapshot(in context: Context, completion: @escaping (CarWidgetEntry) -> Void) {
    completion(entryForSelectedWidget())
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<CarWidgetEntry>) -> Void) {
    let entry = entryForSelectedWidget()
    completion(Timeline(entries: [entry], policy: .never))
  }

  private func entryForSelectedWidget() -> CarWidgetEntry {
    let selected = SharedWidgetStore.selectedWidget(forSlot: slot)
    return CarWidgetEntry(
      date: .now,
      imageURL: selected.flatMap(SharedWidgetStore.imageURL(for:)),
      widgetName: selected?.name
    )
  }
}

struct CarWidgetView: View {
  let entry: CarWidgetEntry

  var body: some View {
    Group {
      if let imageURL = entry.imageURL,
         let image = UIImage(contentsOfFile: imageURL.path) {
        Image(uiImage: image)
          .resizable()
          .scaledToFill()
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .clipped()
          .accessibilityLabel(entry.widgetName ?? "Car Widget")
      } else {
        VStack(spacing: 8) {
          Image(systemName: "car.side.fill")
            .font(.system(size: 26, weight: .medium))
          Text("Select a design in My Widgets")
            .font(.caption)
            .multilineTextAlignment(.center)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.04, green: 0.15, blue: 0.21))
      }
    }
    .containerBackground(.clear, for: .widget)
  }
}

struct CarWidget: Widget {
  let kind = "CarWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: CarWidgetProvider(slot: 0)) { entry in
      CarWidgetView(entry: entry)
    }
    .configurationDisplayName("Car Widget")
    .description("The first selected widget for CarPlay.")
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    .contentMarginsDisabled()
  }
}

struct CarWidget2: Widget {
  let kind = "CarWidget2"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: CarWidgetProvider(slot: 1)) { entry in
      CarWidgetView(entry: entry)
    }
    .configurationDisplayName("Car Widget 2")
    .description("The second selected widget for CarPlay.")
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    .contentMarginsDisabled()
  }
}

@main
struct CarWidgetBundle: WidgetBundle {
  var body: some Widget {
    CarWidget()
    CarWidget2()
  }
}
