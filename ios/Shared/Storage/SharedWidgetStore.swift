import Foundation

struct SharedWidgetImage: Codable, Identifiable {
  let id: String
  let name: String
  let fileName: String
}

private struct SharedWidgetSelection: Codable {
  let firstWidgetId: String?
  let secondWidgetId: String?

  func widgetId(forSlot slot: Int) -> String? {
    switch slot {
    case 0:
      return firstWidgetId
    case 1:
      return secondWidgetId
    default:
      return nil
    }
  }

  func contains(_ id: String) -> Bool {
    firstWidgetId == id || secondWidgetId == id
  }
}

enum SharedWidgetStore {
  static let appGroupIdentifier = "group.com.tientrn.carwidget"
  private static let directoryName = "WidgetImages"
  private static let indexFileName = "widgets.json"
  private static let selectionFileName = "selection.json"

  static func loadWidgets() -> [SharedWidgetImage] {
    guard let directory = sharedDirectory(create: false) else { return [] }
    let indexURL = directory.appendingPathComponent(indexFileName)
    guard let data = try? Data(contentsOf: indexURL),
          let widgets = try? JSONDecoder().decode([SharedWidgetImage].self, from: data) else {
      return []
    }
    return widgets
  }

  static func imageURL(for widget: SharedWidgetImage) -> URL? {
    guard !widget.fileName.contains("/"),
          let directory = sharedDirectory(create: false) else { return nil }
    let url = directory.appendingPathComponent(widget.fileName)
    return FileManager.default.fileExists(atPath: url.path) ? url : nil
  }

  static func selectedWidget(forSlot slot: Int) -> SharedWidgetImage? {
    guard let widgetId = loadSelection().widgetId(forSlot: slot) else { return nil }
    return loadWidgets().first(where: { $0.id == widgetId })
  }

  static func setSelectedWidgets(firstId: String?, secondId: String?) throws {
    guard let directory = sharedDirectory(create: true) else {
      throw StoreError.sharedContainerUnavailable
    }

    let selection = SharedWidgetSelection(
      firstWidgetId: firstId,
      secondWidgetId: secondId == firstId ? nil : secondId
    )
    let selectionData = try JSONEncoder().encode(selection)
    try selectionData.write(
      to: directory.appendingPathComponent(selectionFileName),
      options: .atomic
    )

    let selectedIds = Set([selection.firstWidgetId, selection.secondWidgetId].compactMap { $0 })
    let widgets = loadWidgets()
    let retainedWidgets = widgets.filter { selectedIds.contains($0.id) }
    try writeIndex(retainedWidgets, to: directory)
    for widget in widgets where !selectedIds.contains(widget.id) {
      try? FileManager.default.removeItem(
        at: directory.appendingPathComponent(widget.fileName)
      )
    }
  }

  static func saveImage(_ data: Data, id: String, name: String) throws {
    guard !data.isEmpty, let directory = sharedDirectory(create: true) else {
      throw StoreError.sharedContainerUnavailable
    }
    guard loadSelection().contains(id) else {
      throw StoreError.widgetNotSelected
    }

    let fileName = "\(UUID().uuidString).png"
    try data.write(to: directory.appendingPathComponent(fileName), options: .atomic)
    var widgets = loadWidgets()
    let existingWidget = widgets.first(where: { $0.id == id })
    widgets.removeAll(where: { $0.id == id })
    widgets.append(SharedWidgetImage(id: id, name: name, fileName: fileName))
    try writeIndex(widgets, to: directory)
    if let existingWidget {
      try? FileManager.default.removeItem(
        at: directory.appendingPathComponent(existingWidget.fileName)
      )
    }
  }

  static func removeWidget(id: String) throws {
    guard let directory = sharedDirectory(create: false) else { return }
    var widgets = loadWidgets()
    guard let index = widgets.firstIndex(where: { $0.id == id }) else { return }
    let removed = widgets.remove(at: index)
    try? FileManager.default.removeItem(at: directory.appendingPathComponent(removed.fileName))
    try writeIndex(widgets, to: directory)
  }

  private static func writeIndex(_ widgets: [SharedWidgetImage], to directory: URL) throws {
    let data = try JSONEncoder().encode(widgets)
    try data.write(to: directory.appendingPathComponent(indexFileName), options: .atomic)
  }

  private static func loadSelection() -> SharedWidgetSelection {
    guard let directory = sharedDirectory(create: false),
          let data = try? Data(contentsOf: directory.appendingPathComponent(selectionFileName)),
          let selection = try? JSONDecoder().decode(SharedWidgetSelection.self, from: data) else {
      return SharedWidgetSelection(firstWidgetId: nil, secondWidgetId: nil)
    }
    return selection
  }

  private static func sharedDirectory(create: Bool) -> URL? {
    guard let container = FileManager.default.containerURL(
      forSecurityApplicationGroupIdentifier: appGroupIdentifier
    ) else { return nil }
    let directory = container.appendingPathComponent(directoryName, isDirectory: true)
    if create {
      do {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
      } catch {
        return nil
      }
    }
    return directory
  }

  enum StoreError: LocalizedError {
    case sharedContainerUnavailable
    case widgetNotSelected

    var errorDescription: String? {
      switch self {
      case .sharedContainerUnavailable:
        return "The shared widget container is unavailable."
      case .widgetNotSelected:
        return "Select this design as one of the two CarPlay widgets first."
      }
    }
  }
}
