import SwiftUI
import FamilyControls

struct ContentView: View {
    @State private var status = AuthorizationCenter.shared.authorizationStatus
    @State private var message = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("ProjectSalah")
                .font(.largeTitle)
                .bold()

            Text("Screen Time access: \(statusText)")

            Button("Request Screen Time access") {
                requestAccess()
            }
            .buttonStyle(.borderedProminent)

            Text(message)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private var statusText: String {
        switch status {
        case .approved: return "Approved"
        case .denied: return "Denied"
        case .notDetermined: return "Not asked yet"
        @unknown default: return "Unknown"
        }
    }

    private func requestAccess() {
        Task {
            do {
                try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                message = "Approved"
            } catch {
                message = "Failed: \(error.localizedDescription)"
            }
            status = AuthorizationCenter.shared.authorizationStatus
        }
    }
}