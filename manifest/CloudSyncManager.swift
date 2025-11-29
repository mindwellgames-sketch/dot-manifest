import Foundation
import Combine

/// Manages iCloud Key-Value Store synchronization
class CloudSyncManager: ObservableObject {
    static let shared = CloudSyncManager()

    private let store = NSUbiquitousKeyValueStore.default
    private var cancellables = Set<AnyCancellable>()
    private var observerToken: NSObjectProtocol?

    @Published var isSyncing = false
    @Published var lastSyncDate: Date?

    private init() {
        // Listen for changes from iCloud using closure-based observer
        observerToken = NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: store,
            queue: .main
        ) { [weak self] notification in
            self?.handleStoreDidChange(notification)
        }

        // Start synchronizing with iCloud
        store.synchronize()
    }

    deinit {
        if let token = observerToken {
            NotificationCenter.default.removeObserver(token)
        }
    }

    // MARK: - Sync Methods

    /// Upload data to iCloud
    func uploadData(key: String, data: Data) {
        store.set(data, forKey: key)
        store.synchronize()
        lastSyncDate = Date()
    }

    /// Download data from iCloud
    func downloadData(key: String) -> Data? {
        return store.data(forKey: key)
    }

    /// Force synchronize with iCloud
    func forceSynchronize() {
        isSyncing = true
        let success = store.synchronize()
        isSyncing = false
        if success {
            lastSyncDate = Date()
        }
    }

    private func handleStoreDidChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }

        // Get the reason for change
        if let reason = userInfo[NSUbiquitousKeyValueStoreChangeReasonKey] as? Int {
            switch reason {
            case NSUbiquitousKeyValueStoreServerChange,
                 NSUbiquitousKeyValueStoreInitialSyncChange:
                // Data changed in iCloud, notify observers
                NotificationCenter.default.post(name: .cloudDataDidChange, object: nil)
                lastSyncDate = Date()
            case NSUbiquitousKeyValueStoreQuotaViolationChange:
                #if DEBUG
                print("⚠️ iCloud quota exceeded")
                #endif
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: .showiCloudError,
                        object: nil,
                        userInfo: ["title": "iCloud Storage Full",
                                   "message": "Your iCloud storage is full. Data sync paused. Free up space in iCloud settings."]
                    )
                }
            case NSUbiquitousKeyValueStoreAccountChange:
                #if DEBUG
                print("⚠️ iCloud account changed")
                #endif
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: .showiCloudError,
                        object: nil,
                        userInfo: ["title": "iCloud Account Changed",
                                   "message": "Please restart the app to sync with your new iCloud account."]
                    )
                }
            default:
                break
            }
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let cloudDataDidChange = Notification.Name("cloudDataDidChange")
    static let showiCloudError = Notification.Name("ShowiCloudError")
}
