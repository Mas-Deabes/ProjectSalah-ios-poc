import SwiftUI
import FamilyControls

struct ContentView: View {
    @State private var status = AuthorizationCenter.shared.authorizationStatus
    @State private var selection = Shared.loadSelection() ?? FamilyActivitySelection()
    @State private var showPicker = false
    @State private var message = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("1. Permission") {
                    Text("Screen Time access: \(statusText)")
                    Button("Request Screen Time access") { requestAccess() }
                }

                Section("2. Apps that stay unlocked") {
                    Text("Selected: \(selection.applicationTokens.count) apps")
                    Button("Choose allowed apps") { showPicker = true }
                }

                Section("3. Test the lock") {
                    Button("Lock now") {
                        PrayerLock.lock()
                        message = "Locked. Try opening another app."
                    }
                    .tint(.red)

                    Button("I've prayed") {
                        PrayerLock.unlock()
                        message = "Unlocked."
                    }
                    .tint(.green)
                }

                if !message.isEmpty {
                    Section { Text(message) }
                }
            }
            .navigationTitle("ProjectSalah")
            .familyActivityPicker(isPresented: $showPicker, selection: $selection)
            .onChange(of: selection) { newValue in
                Shared.saveSelection(newValue)
            }
        }
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