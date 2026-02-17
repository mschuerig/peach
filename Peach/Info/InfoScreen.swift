import SwiftUI

struct InfoScreen: View {
    @Environment(\.dismiss) private var dismiss
    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()

                Text("Peach")
                    .font(.largeTitle)
                    .bold()

                Text("Developer: \("Michael")")
                    .font(.body)

                Text("© 2026")
                    .font(.body)

                Text("Version \(appVersion)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

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
