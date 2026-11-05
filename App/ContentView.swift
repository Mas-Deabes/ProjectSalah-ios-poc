import SwiftUI
import FamilyControls
import DeviceActivity

struct ContentView: View {
    @State private var status = AuthorizationCenter.shared.authorizationStatus
    @State private var selection = Shared.loadSelection() ?? FamilyActivitySelection()
    @State private var showPicker = false
    @State private var message = ""
    @State private var log = Log.read()
    @State private var activeSchedules = ""

    // In the real app this becomes "athan time + 5 minutes".
    private let graceMinutes = 2

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

                Section("3. Lock") {
                    Button("Schedule lock in \(graceMinutes) minutes") { scheduleLock() }
                    Button("Lock now") {
                        PrayerLock.lock()
                        update("Locked. Try opening another app.")
                    }
                    .tint(.red)
                }

                Section("4. Unlock") {
                    Button("I've prayed") {
                        PrayerLock.unlock()
                        DeviceActivityCenter().stopMonitoring([.testPrayer])
                        update("Unlocked.")
                    }
                    .tint(.green)
                }

                if !message.isEmpty {
                    Section { Text(message) }
                }

                Section("Log") {
                    Text("Active schedules: \(activeSchedules.isEmpty ? "none" : activeSchedules)")
                    Text(log)
                        .font(.system(.caption, design: .monospaced))
                    Button("Refresh log") { refreshLog() }
                    Button("Clear log", role: .destructive) {
                        Log.clear()
                        refreshLog()
                    }
                }
            }
            .navigationTitle("ProjectSalah")
            .familyActivityPicker(isPresented: $showPicker, selection: $selection)
            .onChange(of: selection) { newValue in
                Shared.saveSelection(newValue)
            }
            .onAppear { refreshLog() }
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

    // Registers a schedule with iOS. The start lands on a whole minute,
    // and the schedule only uses hour and minute.
    private func scheduleLock() {
        let calendar = Calendar.current
        let nextMinute = calendar.dateInterval(of: .minute, for: Date())!.end
        let start = nextMinute.addingTimeInterval(TimeInterval(graceMinutes * 60))
        let end = start.addingTimeInterval(15 * 60)
        let parts: Set<Calendar.Component> = [.hour, .minute]

        let schedule = DeviceActivitySchedule(
            intervalStart: calendar.dateComponents(parts, from: start),
            intervalEnd: calendar.dateComponents(parts, from: end),
            repeats: false
        )

        do {
            let center = DeviceActivityCenter()
            center.stopMonitoring([.testPrayer])
            try center.startMonitoring(.testPrayer, during: schedule)
            let time = start.formatted(date: .omitted, time: .shortened)
            Log.write("Schedule registered for \(time)")
            update("Lock scheduled for \(time). Close the app and wait.")
        } catch {
            Log.write("Schedule failed: \(error.localizedDescription)")
            update("Schedule failed: \(error.localizedDescription)")
        }
    }

    private func refreshLog() {
        log = Log.read()
        activeSchedules = DeviceActivityCenter().activities
            .map(\.rawValue)
            .joined(separator: ", ")
    }

    private func update(_ text: String) {
        message = text
        refreshLog()
    }
}