import Foundation

extension Cents {
    private static let centFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        return formatter
    }()

    func formatted() -> String {
        Self.centFormatter.string(from: NSNumber(value: rawValue)) ?? String(format: "%.1f", rawValue)
    }
}
