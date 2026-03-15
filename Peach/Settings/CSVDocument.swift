import Foundation

struct CSVDocument {
    let csvString: String

    static func exportFileName(for date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmm"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let timestamp = formatter.string(from: date)
        return "peach-training-data-\(timestamp).csv"
    }
}
