import SwiftUI

struct ProfileScreen: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Text("Profile Screen")
                .font(.largeTitle)

            Text("Epic 5: See Your Progress - Profile & Statistics")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ProfileScreen()
    }
}
