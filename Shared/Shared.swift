import Foundation
import FamilyControls
import ManagedSettings
import DeviceActivity

// Saves and loads the apps the user chose to keep unlocked.
enum Shared {
    static let appGroup = "group.com.sif.projectsalah"
    private static let selectionKey = "allowedSelection"

    static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroup) ?? .standard
    }

    static func saveSelection(_ selection: FamilyActivitySelection) {
        if let data = try? JSONEncoder().encode(selection) {
            defaults.set(data, forKey: selectionKey)
        }
    }

    static func loadSelection() -> FamilyActivitySelection? {
        guard let data = defaults.data(forKey: selectionKey) else { return nil }
        return try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
    }
}

extension ManagedSettingsStore.Name {
    static let prayer = Self("prayer")
}

extension DeviceActivityName {
    static let testPrayer = Self("testPrayer")
}

// Applies and removes the Screen Time shield.
enum PrayerLock {
    static func lock() {
        let store = ManagedSettingsStore(named: .prayer)
        let allowedApps = Shared.loadSelection()?.applicationTokens ?? []
        store.shield.applicationCategories = .all(except: allowedApps)
        Log.write("Lock applied. Allowed apps: \(allowedApps.count)")
    }

    static func unlock() {
        ManagedSettingsStore(named: .prayer).clearAllSettings()
        Log.write("Unlocked")
    }
}

// Writes messages to a file in the shared App Group folder.
// Both the app and the extension write here; the app displays it.
enum Log {
    private static var url: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: Shared.appGroup)?
            .appendingPathComponent("log.txt")
    }

    static func write(_ message: String) {
        let time = Date().formatted(date: .omitted, time: .standard)
        let line = "\(time)  \(message)\n"
        guard let url else { return }
        if let handle = try? FileHandle(forWritingTo: url) {
            handle.seekToEndOfFile()
            handle.write(Data(line.utf8))
            try? handle.close()
        } else {
            try? line.write(to: url, atomically: true, encoding: .utf8)
        }
    }

    static func read() -> String {
        guard let url else { return "Shared folder not available." }
        return (try? String(contentsOf: url, encoding: .utf8)) ?? "(empty)"
    }

    static func clear() {
        guard let url else { return }
        try? FileManager.default.removeItem(at: url)
    }
}