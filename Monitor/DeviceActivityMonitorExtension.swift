import DeviceActivity
import ManagedSettings

// iOS runs this in the background when a schedule starts or ends,
// even if the main app is closed.
class DeviceActivityMonitorExtension: DeviceActivityMonitor {

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        Log.write("Extension: schedule started (\(activity.rawValue))")
        PrayerLock.lock()
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        // Doesn't unlock. Only the user's confirmation does that.
        Log.write("Extension: schedule ended (\(activity.rawValue)), lock kept")
    }
}