import Foundation
import FamilyControls
import ManagedSettings

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

// Applies and removes the Screen Time shield.
enum PrayerLock {
    static func lock() {
        let store = ManagedSettingsStore(named: .prayer)
        let allowedApps = Shared.loadSelection()?.applicationTokens ?? []
        store.shield.applicationCategories = .all(except: allowedApps)
    }

    static func unlock() {
        ManagedSettingsStore(named: .prayer).clearAllSettings()
    }
}