import SwiftUI

struct StartScreen: View {
    @State private var showInfoSheet = false
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    @AppStorage(SettingsKeys.intervals)
    private var intervalSelection = IntervalSelection.default

    private var isCompactHeight: Bool {
        verticalSizeClass == .compact
    }

    // MARK: - Layout Parameters (extracted for testability)

    static func vstackSpacing(isCompact: Bool) -> CGFloat {
        isCompact ? 8 : 16
    }

    var body: some View {
        Group {
            if isCompactHeight {
                HStack(spacing: 24) {
                    singleNotesSection
                    Divider()
                    intervalsSection
                }
            } else {
                VStack(spacing: Self.vstackSpacing(isCompact: false)) {
                    Spacer()
                    singleNotesSection
                    Divider()
                    intervalsSection
                    Spacer()
                }
            }
        }
        .padding()
        .navigationTitle("Peach")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    showInfoSheet = true
                } label: {
                    Image(systemName: "info.circle")
                }
                .accessibilityLabel("Info")
            }
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                NavigationLink(value: NavigationDestination.profile) {
                    Image(systemName: "chart.xyaxis.line")
                }
                .accessibilityLabel("Profile")

                NavigationLink(value: NavigationDestination.settings) {
                    Image(systemName: "gearshape")
                }
                .accessibilityLabel("Settings")
            }
        }
        .navigationDestination(for: NavigationDestination.self) { destination in
            switch destination {
            case .comparison(let intervals):
                ComparisonScreen(intervals: intervals)
            case .pitchMatching(let intervals):
                PitchMatchingScreen(intervals: intervals)
            case .settings:
                SettingsScreen()
            case .profile:
                ProfileScreen()
            }
        }
        .sheet(isPresented: $showInfoSheet) {
            InfoScreen()
        }
    }

    // MARK: - Sections

    private var singleNotesSection: some View {
        VStack(spacing: Self.vstackSpacing(isCompact: isCompactHeight)) {
            Text("Single Notes")
                .font(.headline)

            NavigationLink(value: NavigationDestination.comparison(intervals: [.prime])) {
                Label("Hear & Compare", systemImage: "ear")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            NavigationLink(value: NavigationDestination.pitchMatching(intervals: [.prime])) {
                Label("Tune & Match", systemImage: "arrow.up.and.down")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
    }

    private var intervalsSection: some View {
        VStack(spacing: Self.vstackSpacing(isCompact: isCompactHeight)) {
            Text("Intervals")
                .font(.headline)

            NavigationLink(value: NavigationDestination.comparison(intervals: intervalSelection.intervals)) {
                Label("Hear & Compare", systemImage: "ear")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)

            NavigationLink(value: NavigationDestination.pitchMatching(intervals: intervalSelection.intervals)) {
                Label("Tune & Match", systemImage: "arrow.up.and.down")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
    }
}

#Preview {
    NavigationStack {
        StartScreen()
    }
}
