import SwiftUI

enum ChartImageRenderer {

    static func render(mode: TrainingMode, progressTimeline: ProgressTimeline, date: Date = Date()) -> URL? {
        let view = ExportChartView(mode: mode, progressTimeline: progressTimeline, date: date)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2.0
        guard let cgImage = renderer.cgImage else { return nil }
        let uiImage = UIImage(cgImage: cgImage)
        guard let pngData = uiImage.pngData() else { return nil }
        let fileName = exportFileName(for: date, mode: mode)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            try pngData.write(to: url)
            return url
        } catch {
            return nil
        }
    }

    static func exportFileName(for date: Date = Date(), mode: TrainingMode) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmm"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let timestamp = formatter.string(from: date)
        return "peach-\(mode.slug)-\(timestamp).png"
    }
}
