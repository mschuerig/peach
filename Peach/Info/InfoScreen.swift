import SwiftUI

struct InfoScreen: View {
    @Environment(\.dismiss) private var dismiss
    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    static let gitHubURL = URL(string: "https://github.com/mschuerig/peach")!

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()

                Text("Peach")
                    .font(.largeTitle)
                    .bold()

                Text("Version \(appVersion)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                VStack(spacing: 6) {
                    Text("Developer: \("Michael Schürig")")
                        .font(.body)
                    Text(verbatim: "michael@schuerig.de")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 6) {
                    Link("GitHub", destination: Self.gitHubURL)
                        .font(.body)
                    Text("License: \("MIT")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("© 2026")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    InfoScreen()
}
