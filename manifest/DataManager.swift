import Foundation
import SwiftUI

// MARK: - Value with Definition
struct Value: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let definition: String
    var isActive: Bool
    let schemaVersion: Int

    init(id: UUID = UUID(), name: String, definition: String, isActive: Bool = false, schemaVersion: Int = 1) {
        self.id = id
        self.name = name
        self.definition = definition
        self.isActive = isActive
        self.schemaVersion = schemaVersion
    }

    // Custom decoding to handle legacy data without schemaVersion
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        definition = try container.decode(String.self, forKey: .definition)
        isActive = try container.decode(Bool.self, forKey: .isActive)
        schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
    }

    // Computed property for soft, transparent color based on value name
    var color: Color {
        let colors: [Color] = [
            .green, .blue, .red, .purple,
            .orange, .yellow, .pink, .teal
        ]

        // Use hash of name to deterministically assign color
        let hash = abs(name.hashValue)
        let index = hash % colors.count
        return colors[index]
    }
}

// MARK: - Routine Item (Simplified, No Colors)
struct RoutineItem: Codable, Identifiable, Equatable {
    let id: UUID
    var title: String
    var time: String // Display time like "9:00 AM" (DEPRECATED - use startTime/endTime)
    var icon: String // SF Symbol name
    var valueIds: [UUID]
    var notificationEnabled: Bool
    var notificationHour: Int?
    var notificationMinute: Int?
    var order: Int

    // NEW: Timeline view properties
    var startTime: Date?      // Start time (e.g., 6:00 AM)
    var endTime: Date?        // End time (e.g., 7:00 AM)
    var activeDays: [Int]?    // Days of week: 0=Sun, 1=Mon, ... 6=Sat. nil = all days

    let schemaVersion: Int

    init(id: UUID = UUID(), title: String, time: String = "", icon: String = "checkmark.circle", valueIds: [UUID] = [], notificationEnabled: Bool = false, notificationHour: Int? = nil, notificationMinute: Int? = nil, order: Int = 0, startTime: Date? = nil, endTime: Date? = nil, activeDays: [Int]? = nil, schemaVersion: Int = 1) {
        self.id = id
        self.title = title
        self.time = time
        self.icon = icon
        self.valueIds = valueIds
        self.notificationEnabled = notificationEnabled
        self.notificationHour = notificationHour
        self.notificationMinute = notificationMinute
        self.order = order
        self.startTime = startTime
        self.endTime = endTime
        self.activeDays = activeDays
        self.schemaVersion = schemaVersion
    }

    // Custom decoding to handle legacy data without schemaVersion
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        time = try container.decode(String.self, forKey: .time)
        icon = try container.decode(String.self, forKey: .icon)
        valueIds = try container.decode([UUID].self, forKey: .valueIds)
        notificationEnabled = try container.decode(Bool.self, forKey: .notificationEnabled)
        notificationHour = try container.decodeIfPresent(Int.self, forKey: .notificationHour)
        notificationMinute = try container.decodeIfPresent(Int.self, forKey: .notificationMinute)
        order = try container.decode(Int.self, forKey: .order)
        startTime = try container.decodeIfPresent(Date.self, forKey: .startTime)
        endTime = try container.decodeIfPresent(Date.self, forKey: .endTime)
        activeDays = try container.decodeIfPresent([Int].self, forKey: .activeDays)
        schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
    }

    // Helper: Get duration in minutes
    var durationMinutes: Int? {
        guard let start = startTime, let end = endTime else { return nil }
        return Int(end.timeIntervalSince(start) / 60)
    }

    // Helper: Check if routine is active on a specific day (0=Sun, 6=Sat)
    func isActiveOn(weekday: Int) -> Bool {
        guard let days = activeDays else { return true } // nil = all days
        return days.contains(weekday)
    }
}

// MARK: - Reminder
struct Reminder: Codable, Identifiable, Equatable {
    let id: UUID
    var minutesBefore: Int? // nil = at time of event, 0 = at time, 15 = 15 min before, etc.
    var customDate: Date? // For custom absolute time reminders

    init(id: UUID = UUID(), minutesBefore: Int? = nil, customDate: Date? = nil) {
        self.id = id
        self.minutesBefore = minutesBefore
        self.customDate = customDate
    }

    // Custom decoder to handle missing fields gracefully
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        minutesBefore = try container.decodeIfPresent(Int.self, forKey: .minutesBefore)
        customDate = try container.decodeIfPresent(Date.self, forKey: .customDate)
    }
}

// MARK: - Task with Gradient Priority
struct Task: Codable, Identifiable, Equatable {
    let id: UUID
    let createdDate: Date
    var title: String
    var dueDate: Date?
    var valueIds: [UUID]
    var isCompleted: Bool
    var completedDate: Date?

    // Appointment properties
    var isAppointment: Bool
    var location: String?

    // Recurring properties
    var isRecurring: Bool
    var recurringFrequency: RecurringFrequency
    var recurringDays: [Int]? // For weekly: 0=Sun, 1=Mon, etc.
    var visibilityWindow: Int? // Days before to show task

    // Reminder properties
    var reminders: [Reminder]

    let schemaVersion: Int

    init(id: UUID = UUID(), title: String, dueDate: Date? = nil, valueIds: [UUID] = [], isAppointment: Bool = false, location: String? = nil, isRecurring: Bool = false, recurringFrequency: RecurringFrequency = .none, recurringDays: [Int]? = nil, visibilityWindow: Int? = nil, reminders: [Reminder] = [], schemaVersion: Int = 1) {
        self.id = id
        self.createdDate = Date()
        self.title = title
        self.dueDate = dueDate
        self.valueIds = valueIds
        self.isCompleted = false
        self.completedDate = nil
        self.isAppointment = isAppointment
        self.location = location
        self.isRecurring = isRecurring
        self.recurringFrequency = recurringFrequency
        self.recurringDays = recurringDays
        self.visibilityWindow = visibilityWindow
        self.reminders = reminders
        self.schemaVersion = schemaVersion
    }

    // Custom decoding to handle legacy data without schemaVersion
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        createdDate = try container.decodeIfPresent(Date.self, forKey: .createdDate) ?? Date()
        title = try container.decode(String.self, forKey: .title)
        dueDate = try container.decodeIfPresent(Date.self, forKey: .dueDate)
        valueIds = try container.decode([UUID].self, forKey: .valueIds)
        isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
        completedDate = try container.decodeIfPresent(Date.self, forKey: .completedDate)
        isAppointment = try container.decode(Bool.self, forKey: .isAppointment)
        location = try container.decodeIfPresent(String.self, forKey: .location)
        isRecurring = try container.decode(Bool.self, forKey: .isRecurring)
        recurringFrequency = (try? container.decode(RecurringFrequency.self, forKey: .recurringFrequency)) ?? .none
        recurringDays = try container.decodeIfPresent([Int].self, forKey: .recurringDays)
        visibilityWindow = try container.decodeIfPresent(Int.self, forKey: .visibilityWindow)
        reminders = try container.decode([Reminder].self, forKey: .reminders)
        schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
    }

    // Calculate days until due (for gradient color)
    var daysUntilDue: Int? {
        guard let dueDate = dueDate else { return nil }
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let startOfDue = calendar.startOfDay(for: dueDate)
        return calendar.dateComponents([.day], from: startOfToday, to: startOfDue).day
    }

    var isOverdue: Bool {
        guard let days = daysUntilDue else { return false }
        return days < 0
    }
}

enum RecurringFrequency: String, Codable, CaseIterable {
    case none = "None"
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
}

// MARK: - History Entry (for Year→Month→Day view)
struct HistoryEntry: Codable, Identifiable {
    let id: UUID
    let date: Date
    var completedRoutineIds: [UUID]
    var completedTaskIds: [UUID]
    let schemaVersion: Int

    init(id: UUID = UUID(), date: Date, completedRoutineIds: [UUID] = [], completedTaskIds: [UUID] = [], schemaVersion: Int = 1) {
        self.id = id
        self.date = date
        self.completedRoutineIds = completedRoutineIds
        self.completedTaskIds = completedTaskIds
        self.schemaVersion = schemaVersion
    }

    // Custom decoding to handle legacy data without schemaVersion
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        date = try container.decode(Date.self, forKey: .date)
        completedRoutineIds = try container.decode([UUID].self, forKey: .completedRoutineIds)
        completedTaskIds = try container.decode([UUID].self, forKey: .completedTaskIds)
        schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
    }
}

// MARK: - Quote for Loading Screen
struct Quote: Codable, Identifiable {
    let id: UUID
    let text: String
    let author: String
    let category: String?

    init(text: String, author: String, category: String? = nil) {
        self.id = UUID()
        self.text = text
        self.author = author
        self.category = category
    }

    // Custom decoder to handle missing fields gracefully
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        text = try container.decode(String.self, forKey: .text)
        author = try container.decode(String.self, forKey: .author)
        category = try container.decodeIfPresent(String.self, forKey: .category)
    }
}

// MARK: - Data Manager
class DataManager: ObservableObject {
    @Published var values: [Value] = [] {
        didSet {
            // Update cache when values change
            rebuildValueCache()
        }
    }
    @Published var routineItems: [RoutineItem] = []
    @Published var tasks: [Task] = []
    @Published var historyEntries: [HistoryEntry] = []
    @Published var quotes: [Quote] = []
    @Published var isLoading: Bool = false

    // Error handling for user-facing alerts
    @Published var showErrorAlert: Bool = false
    @Published var errorMessage: String = ""
    @Published var errorTitle: String = ""

    private let valuesSaveKey = "AppValues"
    private let routineSaveKey = "AppRoutine"
    private let tasksSaveKey = "AppTasks"
    private let historySaveKey = "AppHistory"

    // Value lookup cache for O(1) access instead of O(n) search
    private var valueCache: [UUID: Value] = [:]

    // Solar calculator for sunrise/sunset gradients
    let solarCalculator = SolarCalculator()

    // iCloud sync manager
    private let cloudSync = CloudSyncManager.shared

    // Debounced save mechanism
    private var saveWorkItem: DispatchWorkItem?
    private let saveDebounceDuration: TimeInterval = 2.0

    init() {
        loadValues()
        loadRoutine()
        migrateRoutineItems() // Fix items with empty activeDays
        loadTasks()
        loadHistory()
        loadQuotes()

        // Listen for iCloud changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCloudDataChange),
            name: .cloudDataDidChange,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func handleCloudDataChange() {
        DispatchQueue.main.async { [weak self] in
            self?.loadFromCloud()
        }
    }

    // MARK: - iCloud Sync
    private func loadFromCloud() {
        // Merge iCloud data with local data instead of blindly overwriting
        if let valuesData = cloudSync.downloadData(key: valuesSaveKey) {
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let cloudValues = try decoder.decode([Value].self, from: valuesData)
                values = mergeValues(local: values, cloud: cloudValues)
                #if DEBUG
                print("☁️ Merged values from iCloud")
                #endif
            } catch {
                #if DEBUG
                print("⚠️ Failed to decode iCloud values: \(error)")
                #endif
            }
        }

        if let routineData = cloudSync.downloadData(key: routineSaveKey) {
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let cloudRoutines = try decoder.decode([RoutineItem].self, from: routineData)
                routineItems = mergeRoutineItems(local: routineItems, cloud: cloudRoutines)
                #if DEBUG
                print("☁️ Merged routines from iCloud")
                #endif
            } catch {
                #if DEBUG
                print("⚠️ Failed to decode iCloud routine: \(error)")
                #endif
            }
        }

        if let tasksData = cloudSync.downloadData(key: tasksSaveKey) {
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let cloudTasks = try decoder.decode([Task].self, from: tasksData)
                tasks = mergeTasks(local: tasks, cloud: cloudTasks)
                #if DEBUG
                print("☁️ Merged tasks from iCloud")
                #endif
            } catch {
                #if DEBUG
                print("⚠️ Failed to decode iCloud tasks: \(error)")
                #endif
            }
        }

        if let historyData = cloudSync.downloadData(key: historySaveKey) {
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let cloudHistory = try decoder.decode([HistoryEntry].self, from: historyData)
                historyEntries = mergeHistoryEntries(local: historyEntries, cloud: cloudHistory)
                #if DEBUG
                print("☁️ Merged history from iCloud")
                #endif
            } catch {
                #if DEBUG
                print("⚠️ Failed to decode iCloud history: \(error)")
                #endif
            }
        }
    }

    // MARK: - Conflict Resolution
    private func mergeValues(local: [Value], cloud: [Value]) -> [Value] {
        var merged: [UUID: Value] = [:]

        // Add all local values
        for value in local {
            merged[value.id] = value
        }

        // Merge cloud values - prefer local if both exist (local is source of truth for toggles)
        for cloudValue in cloud {
            if merged[cloudValue.id] == nil {
                merged[cloudValue.id] = cloudValue
            }
        }

        return Array(merged.values)
    }

    private func mergeRoutineItems(local: [RoutineItem], cloud: [RoutineItem]) -> [RoutineItem] {
        var merged: [UUID: RoutineItem] = [:]

        // Add all local routine items
        for item in local {
            merged[item.id] = item
        }

        // Merge cloud items - prefer local if both exist (local is most recent)
        for cloudItem in cloud {
            if merged[cloudItem.id] == nil {
                merged[cloudItem.id] = cloudItem
            }
        }

        return Array(merged.values)
    }

    private func mergeTasks(local: [Task], cloud: [Task]) -> [Task] {
        var merged: [UUID: Task] = [:]

        // Add all local tasks
        for task in local {
            merged[task.id] = task
        }

        // Merge cloud tasks - use completedDate to determine which is more recent
        for cloudTask in cloud {
            if let localTask = merged[cloudTask.id] {
                // Both exist - pick the one that was modified most recently
                let cloudModified = cloudTask.completedDate ?? cloudTask.createdDate
                let localModified = localTask.completedDate ?? localTask.createdDate

                if cloudModified > localModified {
                    merged[cloudTask.id] = cloudTask
                }
            } else {
                // Only exists in cloud
                merged[cloudTask.id] = cloudTask
            }
        }

        return Array(merged.values)
    }

    private func mergeHistoryEntries(local: [HistoryEntry], cloud: [HistoryEntry]) -> [HistoryEntry] {
        var merged: [UUID: HistoryEntry] = [:]

        // Add all local history entries
        for entry in local {
            merged[entry.id] = entry
        }

        // Merge cloud entries - prefer one with more completed items
        for cloudEntry in cloud {
            if let localEntry = merged[cloudEntry.id] {
                let cloudTotal = cloudEntry.completedRoutineIds.count + cloudEntry.completedTaskIds.count
                let localTotal = localEntry.completedRoutineIds.count + localEntry.completedTaskIds.count

                if cloudTotal > localTotal {
                    merged[cloudEntry.id] = cloudEntry
                }
            } else {
                merged[cloudEntry.id] = cloudEntry
            }
        }

        return Array(merged.values)
    }

    // MARK: - Values
    func loadValues() {
        guard let data = UserDefaults.standard.data(forKey: valuesSaveKey) else {
            // No saved data - load comprehensive values library (183 values)
            #if DEBUG
            print("💾 No saved values found, loading default library")
            #endif
            values = ValuesLibrary.allValues
            saveValues()
            return
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            values = try decoder.decode([Value].self, from: data)
            #if DEBUG
            print("✅ Loaded \(values.count) values from storage")
            #endif
        } catch {
            #if DEBUG
            print("❌ ERROR loading values: \(error.localizedDescription)")
            #endif

            // Try to recover from iCloud backup before falling back to defaults
            if let cloudData = cloudSync.downloadData(key: valuesSaveKey) {
                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    let cloudValues = try decoder.decode([Value].self, from: cloudData)
                    values = cloudValues
                    #if DEBUG
                    print("✅ Recovered \(values.count) values from iCloud backup")
                    #endif
                    saveValues()
                    return
                } catch {
                    #if DEBUG
                    print("⚠️ iCloud recovery also failed: \(error.localizedDescription)")
                    #endif
                }
            }

            #if DEBUG
            print("   Falling back to default values library")
            #endif
            values = ValuesLibrary.allValues
            showError(title: "Data Recovery", message: "Your values were reset to defaults. Please restore from backup if available.")
            saveValues()
        }
    }

    // MARK: - Debounced Save
    private func debouncedSave() {
        // Cancel any pending save
        saveWorkItem?.cancel()

        // Create new save work item
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }

            // Perform actual save
            self.saveAllData()
        }

        saveWorkItem = workItem

        // Schedule save after debounce duration
        DispatchQueue.main.asyncAfter(deadline: .now() + saveDebounceDuration, execute: workItem)
    }

    // Immediate synchronous save for app backgrounding - ensures data is saved before app terminates
    func saveAllDataImmediately() {
        saveWorkItem?.cancel()

        // Synchronous save - must complete before app backgrounds
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let valuesData = try encoder.encode(values)
            let routineData = try encoder.encode(routineItems)
            let tasksData = try encoder.encode(tasks)
            let historyData = try encoder.encode(historyEntries)

            UserDefaults.standard.set(valuesData, forKey: valuesSaveKey)
            UserDefaults.standard.set(routineData, forKey: routineSaveKey)
            UserDefaults.standard.set(tasksData, forKey: tasksSaveKey)
            UserDefaults.standard.set(historyData, forKey: historySaveKey)

            // iCloud upload can be async - it's okay if this doesn't complete
            cloudSync.uploadData(key: valuesSaveKey, data: valuesData)
            cloudSync.uploadData(key: routineSaveKey, data: routineData)
            cloudSync.uploadData(key: tasksSaveKey, data: tasksData)
            cloudSync.uploadData(key: historySaveKey, data: historyData)

            #if DEBUG
            print("✅ Immediate save completed (local + iCloud)")
            #endif
        } catch {
            #if DEBUG
            print("❌ CRITICAL ERROR in immediate save: \(error.localizedDescription)")
            #endif
        }
    }

    private func saveAllData() {
        // Capture data on main thread
        let valuesToSave = values
        let routinesToSave = routineItems
        let tasksToSave = tasks
        let historyToSave = historyEntries

        // Encode JSON on background thread to prevent UI blocking
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            do {
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                let valuesData = try encoder.encode(valuesToSave)
                let routineData = try encoder.encode(routinesToSave)
                let tasksData = try encoder.encode(tasksToSave)
                let historyData = try encoder.encode(historyToSave)

                // Save to UserDefaults and iCloud on main thread
                DispatchQueue.main.async {
                    UserDefaults.standard.set(valuesData, forKey: self.valuesSaveKey)
                    UserDefaults.standard.set(routineData, forKey: self.routineSaveKey)
                    UserDefaults.standard.set(tasksData, forKey: self.tasksSaveKey)
                    UserDefaults.standard.set(historyData, forKey: self.historySaveKey)

                    // Upload to iCloud
                    self.cloudSync.uploadData(key: self.valuesSaveKey, data: valuesData)
                    self.cloudSync.uploadData(key: self.routineSaveKey, data: routineData)
                    self.cloudSync.uploadData(key: self.tasksSaveKey, data: tasksData)
                    self.cloudSync.uploadData(key: self.historySaveKey, data: historyData)

                    #if DEBUG
                    print("✅ Debounced save completed (local + iCloud)")
                    #endif
                }
            } catch {
                #if DEBUG
                print("❌ CRITICAL ERROR in debounced save: \(error.localizedDescription)")
                #endif
                self.showError(title: "Save Failed", message: "Unable to save your changes. Please try again. Error: \(error.localizedDescription)")
            }
        }
    }

    // Helper method to show error alerts
    private func showError(title: String, message: String) {
        DispatchQueue.main.async { [weak self] in
            self?.errorTitle = title
            self?.errorMessage = message
            self?.showErrorAlert = true
        }
    }

    func saveValues() {
        let valuesToSave = values
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            do {
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                let encoded = try encoder.encode(valuesToSave)
                DispatchQueue.main.async {
                    UserDefaults.standard.set(encoded, forKey: self.valuesSaveKey)
                    self.cloudSync.uploadData(key: self.valuesSaveKey, data: encoded)
                    #if DEBUG
                    print("✅ Saved \(valuesToSave.count) values (local + iCloud)")
                    #endif
                }
            } catch {
                #if DEBUG
                print("❌ CRITICAL ERROR saving values: \(error.localizedDescription)")
                #endif
                self.showError(title: "Save Failed", message: "Unable to save your values. Error: \(error.localizedDescription)")
            }
        }
    }

    func toggleValueActive(_ value: Value) {
        if let index = values.firstIndex(where: { $0.id == value.id }) {
            values[index].isActive.toggle()
            debouncedSave()
        }
    }

    func addCustomValue(name: String, definition: String) {
        let newValue = Value(name: name, definition: definition, isActive: true)
        values.append(newValue)
        debouncedSave()
    }

    // MARK: - Value Cache for Performance
    private func rebuildValueCache() {
        valueCache = Dictionary(uniqueKeysWithValues: values.map { ($0.id, $0) })
    }

    func getValue(by id: UUID) -> Value? {
        return valueCache[id]
    }

    var activeValues: [Value] {
        values.filter { $0.isActive }
    }

    // MARK: - Routine
    func loadRoutine() {
        guard let data = UserDefaults.standard.data(forKey: routineSaveKey) else {
            #if DEBUG
            print("💾 No saved routines found, starting with empty list")
            #endif
            routineItems = []
            return
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            routineItems = try decoder.decode([RoutineItem].self, from: data).sorted { $0.order < $1.order }
            #if DEBUG
            print("✅ Loaded \(routineItems.count) routine items")
            #endif
        } catch {
            #if DEBUG
            print("❌ ERROR loading routines: \(error.localizedDescription)")
            print("   Starting with empty routine list to prevent data corruption")
            #endif
            routineItems = []
        }
    }

    func saveRoutine() {
        let routinesToSave = routineItems
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            do {
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                let encoded = try encoder.encode(routinesToSave)
                DispatchQueue.main.async {
                    UserDefaults.standard.set(encoded, forKey: self.routineSaveKey)
                    self.cloudSync.uploadData(key: self.routineSaveKey, data: encoded)
                    #if DEBUG
                    print("✅ Saved \(routinesToSave.count) routine items (local + iCloud)")
                    #endif
                }
            } catch {
                #if DEBUG
                print("❌ CRITICAL ERROR saving routines: \(error.localizedDescription)")
                #endif
                self.showError(title: "Save Failed", message: "Unable to save your routines. Error: \(error.localizedDescription)")
            }
        }
    }

    func addRoutineItem(_ item: RoutineItem) {
        var newItem = item
        newItem.order = routineItems.count
        routineItems.append(newItem)
        debouncedSave()
    }

    func updateRoutineItem(_ item: RoutineItem) {
        if let index = routineItems.firstIndex(where: { $0.id == item.id }) {
            routineItems[index] = item
            debouncedSave()
        }
    }

    func deleteRoutineItem(_ item: RoutineItem) {
        routineItems.removeAll { $0.id == item.id }
        debouncedSave()
    }

    // Fix routine items with empty activeDays array (should be nil to show on all days)
    func migrateRoutineItems() {
        var needsSave = false
        for index in routineItems.indices {
            if let activeDays = routineItems[index].activeDays, activeDays.isEmpty {
                // Convert empty array to nil (means "all days")
                routineItems[index].activeDays = nil
                needsSave = true
                #if DEBUG
                print("✓ Migrated routine item: \(routineItems[index].title) - now active all days")
                #endif
            }
        }
        if needsSave {
            debouncedSave()
            #if DEBUG
            print("✓ Migration complete: Fixed \(routineItems.count) routine items")
            #endif
        }
    }

    // MARK: - Tasks
    func loadTasks() {
        guard let data = UserDefaults.standard.data(forKey: tasksSaveKey) else {
            #if DEBUG
            print("💾 No saved tasks found, starting with empty list")
            #endif
            tasks = []
            return
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            tasks = try decoder.decode([Task].self, from: data)
            #if DEBUG
            print("✅ Loaded \(tasks.count) tasks")
            #endif
        } catch {
            #if DEBUG
            print("❌ ERROR loading tasks: \(error.localizedDescription)")
            print("   Starting with empty task list to prevent data corruption")
            #endif
            tasks = []
        }
    }

    func saveTasks() {
        let tasksToSave = tasks
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            do {
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                let encoded = try encoder.encode(tasksToSave)
                DispatchQueue.main.async {
                    UserDefaults.standard.set(encoded, forKey: self.tasksSaveKey)
                    self.cloudSync.uploadData(key: self.tasksSaveKey, data: encoded)
                    #if DEBUG
                    print("✅ Saved \(tasksToSave.count) tasks (local + iCloud)")
                    #endif
                }
            } catch {
                #if DEBUG
                print("❌ CRITICAL ERROR saving tasks: \(error.localizedDescription)")
                #endif
                self.showError(title: "Save Failed", message: "Unable to save your tasks. Error: \(error.localizedDescription)")
            }
        }
    }

    func addTask(_ task: Task) {
        tasks.append(task)
        debouncedSave()
    }

    func updateTask(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
            debouncedSave()
        }
    }

    func deleteTask(_ task: Task) {
        tasks.removeAll { $0.id == task.id }
        debouncedSave()
    }

    func completeTask(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted = true
            tasks[index].completedDate = Date()

            // Add to today's history
            addCompletedTaskToHistory(taskId: task.id)

            // Handle recurring
            if task.isRecurring {
                generateNextRecurringTask(from: task)
            }

            debouncedSave()
        }
    }

    func uncompleteTask(_ task: Task) {
        // Remove from today's history
        var entry = getTodayHistoryEntry()
        entry.completedTaskIds.removeAll { $0 == task.id }
        updateHistoryEntry(entry)

        // Mark task as not completed
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted = false
            tasks[index].completedDate = nil
            debouncedSave()
        }
    }

    func snoozeTask(_ task: Task, days: Int) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            if let currentDueDate = tasks[index].dueDate {
                let calendar = Calendar.current
                if let newDueDate = calendar.date(byAdding: .day, value: days, to: currentDueDate) {
                    tasks[index].dueDate = newDueDate
                    debouncedSave()
                }
            }
        }
    }

    func generateNextRecurringTask(from task: Task) {
        guard let dueDate = task.dueDate else { return }
        let calendar = Calendar.current
        var nextDue: Date?

        switch task.recurringFrequency {
        case .daily:
            nextDue = calendar.date(byAdding: .day, value: 1, to: dueDate)
        case .weekly:
            nextDue = calendar.date(byAdding: .weekOfYear, value: 1, to: dueDate)
        case .monthly:
            nextDue = calendar.date(byAdding: .month, value: 1, to: dueDate)
        case .none:
            break
        }

        if let nextDue = nextDue {
            let newTask = Task(
                title: task.title,
                dueDate: nextDue,
                valueIds: task.valueIds,
                isAppointment: task.isAppointment,
                location: task.location,
                isRecurring: true,
                recurringFrequency: task.recurringFrequency,
                recurringDays: task.recurringDays,
                visibilityWindow: task.visibilityWindow,
                reminders: task.reminders  // Copy reminders to new instance (iOS behavior)
            )
            addTask(newTask)
        }
    }

    var activeTasks: [Task] {
        tasks.filter { !$0.isCompleted }
            .sorted { task1, task2 in
                // Overdue first, then by due date
                let days1 = task1.daysUntilDue ?? Int.max
                let days2 = task2.daysUntilDue ?? Int.max
                return days1 < days2
            }
    }

    var overdueTasks: [Task] {
        activeTasks.filter { $0.isOverdue }
    }

    var activeNonOverdueTasks: [Task] {
        activeTasks.filter { !$0.isOverdue }
    }

    // MARK: - History
    func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: historySaveKey) else {
            #if DEBUG
            print("💾 No saved history found, starting with empty list")
            #endif
            historyEntries = []
            return
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            historyEntries = try decoder.decode([HistoryEntry].self, from: data)
            #if DEBUG
            print("✅ Loaded \(historyEntries.count) history entries")
            #endif
        } catch {
            #if DEBUG
            print("❌ ERROR loading history: \(error.localizedDescription)")
            print("   Starting with empty history to prevent data corruption")
            #endif
            historyEntries = []
        }
    }

    func saveHistory() {
        let historyToSave = historyEntries
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            do {
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                let encoded = try encoder.encode(historyToSave)
                DispatchQueue.main.async {
                    UserDefaults.standard.set(encoded, forKey: self.historySaveKey)
                    self.cloudSync.uploadData(key: self.historySaveKey, data: encoded)
                    #if DEBUG
                    print("✅ Saved \(historyToSave.count) history entries (local + iCloud)")
                    #endif
                }
            } catch {
                #if DEBUG
                print("❌ CRITICAL ERROR saving history: \(error.localizedDescription)")
                #endif
                self.showError(title: "Save Failed", message: "Unable to save your history. Error: \(error.localizedDescription)")
            }
        }
    }

    func saveData() {
        saveValues()
        debouncedSave()
    }

    func getTodayHistoryEntry() -> HistoryEntry {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let existing = historyEntries.first(where: { calendar.isDate($0.date, inSameDayAs: today) }) {
            return existing
        } else {
            let newEntry = HistoryEntry(date: today)
            historyEntries.append(newEntry)
            debouncedSave()
            return newEntry
        }
    }

    func addCompletedRoutineToHistory(routineId: UUID) {
        var entry = getTodayHistoryEntry()
        if !entry.completedRoutineIds.contains(routineId) {
            entry.completedRoutineIds.append(routineId)
            updateHistoryEntry(entry)
        }
    }

    func addCompletedTaskToHistory(taskId: UUID) {
        var entry = getTodayHistoryEntry()
        if !entry.completedTaskIds.contains(taskId) {
            entry.completedTaskIds.append(taskId)
            updateHistoryEntry(entry)
        }
    }

    func updateHistoryEntry(_ entry: HistoryEntry) {
        if let index = historyEntries.firstIndex(where: { $0.id == entry.id }) {
            historyEntries[index] = entry
            debouncedSave()
        }
    }

    func deleteHistoryEntry(_ entry: HistoryEntry) {
        historyEntries.removeAll { $0.id == entry.id }
        debouncedSave()
    }

    func clearHistory() {
        historyEntries.removeAll()
        saveAllDataImmediately()
    }

    // MARK: - Quotes
    func loadQuotes() {
        quotes = QuotesLibrary.allQuotes
    }

    func randomQuote() -> Quote {
        quotes.randomElement() ?? Quote(text: "What you think, you become. What you feel, you attract. What you imagine, you create.", author: "Buddha")
    }
}

// Comprehensive library of 150+ values with definitions
struct ValuesLibrary {
    static let allValues: [Value] = [
        Value(name: "Accountability", definition: "Taking responsibility for your actions and their consequences; being answerable to others and yourself for commitments made."),
        Value(name: "Achievement", definition: "Striving to accomplish goals and reach milestones; finding satisfaction in tangible results and success."),
        Value(name: "Adaptability", definition: "Being flexible and open to change; adjusting effectively to new circumstances and challenges."),
        Value(name: "Adventure", definition: "Seeking new experiences and embracing the unknown; finding excitement in exploration and discovery."),
        Value(name: "Ambition", definition: "Having strong desire and determination to achieve something; setting high goals and working toward them."),
        Value(name: "Authenticity", definition: "Being genuine and true to yourself; expressing your real thoughts, feelings, and values rather than conforming."),
        Value(name: "Autonomy", definition: "Having independence and self-direction; making your own choices and controlling your own life."),
        Value(name: "Balance", definition: "Maintaining equilibrium between different aspects of life; avoiding extremes and finding harmony."),
        Value(name: "Beauty", definition: "Appreciating and creating aesthetic experiences; valuing visual, artistic, or natural elegance."),
        Value(name: "Belonging", definition: "Feeling connected and accepted within a community or group; having meaningful relationships and social bonds."),
        Value(name: "Benevolence", definition: "Caring about the welfare of others; acting with kindness and goodwill toward people."),
        Value(name: "Boldness", definition: "Having courage to take risks and stand out; being willing to be different or controversial when necessary."),
        Value(name: "Calmness", definition: "Maintaining inner peace and composure; approaching situations with serenity rather than anxiety."),
        Value(name: "Caring", definition: "Showing concern and compassion for others' wellbeing; being attentive to others' needs and feelings."),
        Value(name: "Challenge", definition: "Seeking difficult tasks that test your abilities; finding motivation in overcoming obstacles."),
        Value(name: "Clarity", definition: "Pursuing clear thinking and communication; removing ambiguity and confusion from situations."),
        Value(name: "Collaboration", definition: "Working cooperatively with others toward shared goals; valuing teamwork and collective effort."),
        Value(name: "Commitment", definition: "Dedicating yourself fully to people, causes, or goals; following through on promises and obligations."),
        Value(name: "Community", definition: "Contributing to and participating in collective groups; valuing social connection and shared identity."),
        Value(name: "Compassion", definition: "Feeling deep sympathy for others' suffering and wanting to alleviate it; combining empathy with action."),
        Value(name: "Competence", definition: "Developing skill and capability in your endeavors; striving for mastery and effectiveness."),
        Value(name: "Competition", definition: "Engaging in contests or rivalries; finding motivation in measuring yourself against others."),
        Value(name: "Confidence", definition: "Believing in your abilities and judgment; approaching challenges with self-assurance."),
        Value(name: "Connection", definition: "Building deep, meaningful relationships; feeling emotionally linked to others."),
        Value(name: "Conscientiousness", definition: "Being thorough, careful, and diligent; taking duties seriously and acting responsibly."),
        Value(name: "Consistency", definition: "Being reliable and predictable in behavior; maintaining steadiness across time and situations."),
        Value(name: "Contentment", definition: "Finding satisfaction with what you have; experiencing peace and acceptance with your current state."),
        Value(name: "Contribution", definition: "Making a positive difference in the world; adding value to others' lives or to society."),
        Value(name: "Courage", definition: "Facing fear, danger, or difficulty with bravery; taking action despite uncertainty or risk."),
        Value(name: "Creativity", definition: "Generating original ideas and novel solutions; expressing imagination and innovation."),
        Value(name: "Curiosity", definition: "Having a strong desire to learn and explore; asking questions and seeking understanding."),
        Value(name: "Dependability", definition: "Being reliable and trustworthy; consistently doing what you say you'll do."),
        Value(name: "Determination", definition: "Persisting despite obstacles; maintaining firmness of purpose and resolve."),
        Value(name: "Dignity", definition: "Treating yourself and others with respect and worth; maintaining self-respect regardless of circumstances."),
        Value(name: "Diligence", definition: "Working carefully and persistently; showing steady, earnest effort in your endeavors."),
        Value(name: "Discipline", definition: "Controlling your impulses and maintaining focus; following through with rules and routines."),
        Value(name: "Discovery", definition: "Finding new knowledge, places, or experiences; enjoying the process of learning and uncovering."),
        Value(name: "Diversity", definition: "Valuing differences in people, ideas, and approaches; embracing variety and inclusion."),
        Value(name: "Efficiency", definition: "Accomplishing tasks with minimal waste of time or resources; optimizing processes and efforts."),
        Value(name: "Empathy", definition: "Understanding and sharing the feelings of others; seeing situations from others' perspectives."),
        Value(name: "Empowerment", definition: "Enabling yourself and others to take control; building confidence and capability in people."),
        Value(name: "Endurance", definition: "Persisting through long-term challenges; having stamina and staying power."),
        Value(name: "Energy", definition: "Bringing vitality and enthusiasm to activities; maintaining high levels of vigor and drive."),
        Value(name: "Enjoyment", definition: "Finding pleasure and fun in experiences; prioritizing activities that bring joy."),
        Value(name: "Enthusiasm", definition: "Showing intense interest and excitement; approaching life with passion and zeal."),
        Value(name: "Equality", definition: "Treating all people as having equal worth and rights; opposing discrimination and hierarchy."),
        Value(name: "Excellence", definition: "Pursuing the highest quality in everything; refusing to settle for mediocre results."),
        Value(name: "Excitement", definition: "Seeking stimulation and thrilling experiences; valuing activities that create arousal and energy."),
        Value(name: "Exploration", definition: "Investigating new territories, ideas, or possibilities; pushing beyond familiar boundaries."),
        Value(name: "Fairness", definition: "Treating people equitably and justly; applying consistent standards without favoritism."),
        Value(name: "Faith", definition: "Having trust and belief in something greater than yourself; maintaining conviction without complete proof."),
        Value(name: "Family", definition: "Prioritizing close relatives and chosen kin; valuing familial bonds and obligations."),
        Value(name: "Fearlessness", definition: "Acting without being paralyzed by fear; confronting intimidating situations directly."),
        Value(name: "Fidelity", definition: "Being faithful and loyal to commitments, people, or principles; maintaining constancy."),
        Value(name: "Flexibility", definition: "Adapting easily to changes; avoiding rigid thinking or behavior patterns."),
        Value(name: "Focus", definition: "Concentrating attention on priorities; avoiding distraction and maintaining clear direction."),
        Value(name: "Forgiveness", definition: "Letting go of resentment and anger; offering pardon to yourself and others."),
        Value(name: "Freedom", definition: "Having liberty to act, think, and choose; being unrestricted by excessive external control."),
        Value(name: "Friendship", definition: "Building and maintaining close personal relationships; valuing companionship and mutual support."),
        Value(name: "Frugality", definition: "Using resources carefully and avoiding waste; living within or below your means."),
        Value(name: "Fun", definition: "Engaging in playful, enjoyable activities; prioritizing lightheartedness and entertainment."),
        Value(name: "Generosity", definition: "Giving freely of your time, resources, or energy; being liberal and openhanded."),
        Value(name: "Gentleness", definition: "Being mild, tender, and kind in manner; avoiding harshness or roughness."),
        Value(name: "Grace", definition: "Moving through life with elegance and dignity; responding to situations with poise."),
        Value(name: "Gratitude", definition: "Feeling and expressing thankfulness; appreciating what you have and what others do."),
        Value(name: "Growth", definition: "Continuously developing and improving yourself; evolving beyond your current state."),
        Value(name: "Happiness", definition: "Pursuing joy and positive emotional states; prioritizing wellbeing and life satisfaction."),
        Value(name: "Harmony", definition: "Seeking peaceful coexistence and compatibility; avoiding conflict and discord."),
        Value(name: "Health", definition: "Maintaining physical, mental, and emotional wellbeing; prioritizing your body's needs."),
        Value(name: "Helpfulness", definition: "Assisting others and being of service; offering aid and support readily."),
        Value(name: "Honesty", definition: "Telling the truth and being straightforward; refusing to deceive or mislead."),
        Value(name: "Honor", definition: "Acting with integrity and adhering to ethical principles; maintaining reputation and respect."),
        Value(name: "Hope", definition: "Maintaining optimism about the future; believing positive outcomes are possible."),
        Value(name: "Humility", definition: "Being modest and avoiding arrogance; recognizing your limitations and others' contributions."),
        Value(name: "Humor", definition: "Finding and creating amusement; approaching life with levity and the ability to laugh."),
        Value(name: "Independence", definition: "Being self-reliant and not needing others' approval; functioning autonomously."),
        Value(name: "Individuality", definition: "Expressing your unique identity; celebrating what makes you different from others."),
        Value(name: "Innovation", definition: "Creating new methods, ideas, or products; driving change through invention."),
        Value(name: "Inquisitiveness", definition: "Asking questions and seeking deeper understanding; being intellectually curious and probing."),
        Value(name: "Integrity", definition: "Living according to your values consistently; having strong moral principles and honesty."),
        Value(name: "Intelligence", definition: "Valuing mental capability and using reason; pursuing knowledge and understanding."),
        Value(name: "Intimacy", definition: "Building deep emotional closeness with others; sharing vulnerability and authentic connection."),
        Value(name: "Intuition", definition: "Trusting your instincts and inner knowing; making decisions based on gut feelings."),
        Value(name: "Joy", definition: "Experiencing and spreading intense happiness; finding delight in life's moments."),
        Value(name: "Justice", definition: "Ensuring fair treatment and consequences; advocating for what is right and equitable."),
        Value(name: "Kindness", definition: "Being considerate, generous, and friendly; treating others with warmth and care."),
        Value(name: "Knowledge", definition: "Acquiring information and understanding; valuing education and intellectual development."),
        Value(name: "Leadership", definition: "Guiding and inspiring others toward goals; taking responsibility for direction and vision."),
        Value(name: "Learning", definition: "Continuously acquiring new skills and information; remaining a lifelong student."),
        Value(name: "Legacy", definition: "Creating lasting impact beyond your lifetime; building something that endures."),
        Value(name: "Leisure", definition: "Valuing free time and relaxation; making space for rest and recreational activities."),
        Value(name: "Love", definition: "Feeling and expressing deep affection; caring intensely for others' wellbeing and happiness."),
        Value(name: "Loyalty", definition: "Remaining faithful to people, organizations, or causes; standing by commitments through difficulty."),
        Value(name: "Mastery", definition: "Achieving expert-level skill; pursuing excellence and deep competence in areas of focus."),
        Value(name: "Meaning", definition: "Finding purpose and significance in life; ensuring activities align with deeper values."),
        Value(name: "Mindfulness", definition: "Being present and aware in the current moment; paying attention without judgment."),
        Value(name: "Moderation", definition: "Avoiding excess and maintaining reasonable limits; finding the middle path."),
        Value(name: "Modesty", definition: "Being unassuming and humble; avoiding showiness or excessive pride."),
        Value(name: "Open-mindedness", definition: "Considering new ideas and perspectives; avoiding prejudgment and rigid thinking."),
        Value(name: "Openness", definition: "Being transparent and receptive; sharing honestly and welcoming others' input."),
        Value(name: "Optimism", definition: "Maintaining a positive outlook; expecting favorable outcomes and focusing on possibilities."),
        Value(name: "Order", definition: "Creating and maintaining organization; having structure and systematic approaches."),
        Value(name: "Originality", definition: "Being unique and unconventional; creating things that are novel and distinctly yours."),
        Value(name: "Passion", definition: "Feeling intense enthusiasm and emotion; being deeply invested in what matters to you."),
        Value(name: "Patience", definition: "Accepting delays without frustration; maintaining calm and composure while waiting."),
        Value(name: "Peace", definition: "Seeking tranquility and absence of conflict; valuing serenity internally and externally."),
        Value(name: "Perseverance", definition: "Continuing despite difficulty or opposition; refusing to give up on important goals."),
        Value(name: "Playfulness", definition: "Approaching life with spontaneity and fun; not taking everything seriously."),
        Value(name: "Positivity", definition: "Focusing on the good in situations; maintaining an upbeat and constructive attitude."),
        Value(name: "Power", definition: "Having influence and control over outcomes; being able to affect change and make impact."),
        Value(name: "Pragmatism", definition: "Being practical and realistic; focusing on what works rather than ideals alone."),
        Value(name: "Precision", definition: "Being exact and accurate; paying attention to details and avoiding errors."),
        Value(name: "Preparedness", definition: "Planning ahead and being ready; anticipating needs and potential challenges."),
        Value(name: "Presence", definition: "Being fully engaged in the current moment; giving complete attention to what's happening now."),
        Value(name: "Pride", definition: "Taking satisfaction in achievements and identity; maintaining self-respect and dignity."),
        Value(name: "Privacy", definition: "Protecting personal boundaries and information; maintaining control over your private life."),
        Value(name: "Productivity", definition: "Accomplishing tasks efficiently and effectively; generating meaningful output and results."),
        Value(name: "Professionalism", definition: "Maintaining high standards in work; behaving competently and appropriately in professional settings."),
        Value(name: "Prosperity", definition: "Achieving success and flourishing in all areas of life; experiencing abundance and thriving conditions."),
        Value(name: "Purpose", definition: "Having clear direction and meaning; knowing why you do what you do."),
        Value(name: "Quality", definition: "Prioritizing excellence over quantity; ensuring high standards in outputs and experiences."),
        Value(name: "Rationality", definition: "Using logic and reason; making decisions based on evidence and clear thinking."),
        Value(name: "Recognition", definition: "Being acknowledged for your contributions; receiving appreciation and validation from others."),
        Value(name: "Reflection", definition: "Thinking deeply about experiences and yourself; engaging in introspection and contemplation."),
        Value(name: "Reliability", definition: "Being consistently dependable; following through on commitments regularly."),
        Value(name: "Resilience", definition: "Bouncing back from setbacks; recovering quickly from difficulties and adapting."),
        Value(name: "Resourcefulness", definition: "Finding creative solutions with available means; overcoming obstacles through ingenuity."),
        Value(name: "Respect", definition: "Treating others with consideration and regard; honoring people's worth and boundaries."),
        Value(name: "Responsibility", definition: "Being accountable for duties and obligations; taking ownership of your role and actions."),
        Value(name: "Restraint", definition: "Exercising self-control; avoiding impulsive or excessive behavior."),
        Value(name: "Risk-taking", definition: "Willingly exposing yourself to uncertainty; trying things despite potential negative outcomes."),
        Value(name: "Safety", definition: "Protecting yourself and others from harm; prioritizing security and avoiding danger."),
        Value(name: "Security", definition: "Having stability and freedom from threats; maintaining a safe foundation in life."),
        Value(name: "Self-awareness", definition: "Understanding your own thoughts, feelings, and motivations; recognizing your patterns and impact."),
        Value(name: "Self-care", definition: "Attending to your own needs and wellbeing; prioritizing activities that restore and nourish you."),
        Value(name: "Self-control", definition: "Managing impulses and emotions; directing your behavior through willpower."),
        Value(name: "Self-expression", definition: "Communicating your authentic self; sharing your thoughts, feelings, and creativity freely."),
        Value(name: "Self-reliance", definition: "Depending on your own capabilities; being able to function independently."),
        Value(name: "Self-respect", definition: "Valuing and honoring yourself; maintaining dignity and positive self-regard."),
        Value(name: "Service", definition: "Contributing to others' wellbeing; dedicating effort to helping and supporting."),
        Value(name: "Significance", definition: "Making a meaningful impact; being important or influential in some way."),
        Value(name: "Simplicity", definition: "Reducing complexity and excess; focusing on essentials and avoiding complications."),
        Value(name: "Sincerity", definition: "Being genuine and honest in expression; meaning what you say without pretense."),
        Value(name: "Solitude", definition: "Valuing time alone; finding peace and renewal in your own company."),
        Value(name: "Spirituality", definition: "Connecting with something transcendent; exploring meaning beyond the material world."),
        Value(name: "Spontaneity", definition: "Acting on impulse and in the moment; being flexible and unpredictable."),
        Value(name: "Stability", definition: "Maintaining consistency and reliability; avoiding unnecessary change or chaos."),
        Value(name: "Status", definition: "Achieving recognition and social standing; being respected and admired by others."),
        Value(name: "Stewardship", definition: "Taking care of resources and responsibilities entrusted to you; managing with long-term thinking."),
        Value(name: "Strength", definition: "Possessing physical, mental, or emotional power; having capacity to endure and overcome."),
        Value(name: "Structure", definition: "Creating frameworks and systems; organizing life with clear rules and boundaries."),
        Value(name: "Success", definition: "Achieving desired outcomes and goals; reaching milestones others recognize as accomplishments."),
        Value(name: "Support", definition: "Providing help and encouragement to others; being there when people need you."),
        Value(name: "Sustainability", definition: "Acting with long-term viability in mind; ensuring resources and systems can continue."),
        Value(name: "Teamwork", definition: "Collaborating effectively with others; contributing to collective success."),
        Value(name: "Temperance", definition: "Exercising moderation and self-restraint; avoiding excess in all things."),
        Value(name: "Tenacity", definition: "Holding firmly to goals and convictions; refusing to let go despite challenges."),
        Value(name: "Thoughtfulness", definition: "Being considerate and reflective; thinking carefully about impacts and meanings."),
        Value(name: "Thrift", definition: "Using resources economically; getting maximum value while spending minimally."),
        Value(name: "Tradition", definition: "Honoring customs and established practices; maintaining connection to cultural heritage."),
        Value(name: "Tranquility", definition: "Experiencing calm and peace; living without anxiety or turbulence."),
        Value(name: "Transparency", definition: "Being open and clear in communication; operating without hidden agendas."),
        Value(name: "Trust", definition: "Having confidence in others' reliability; believing in integrity and keeping promises."),
        Value(name: "Trustworthiness", definition: "Being worthy of others' confidence; demonstrating reliability and honesty consistently."),
        Value(name: "Truth", definition: "Seeking and speaking what is accurate and real; prioritizing facts over convenience."),
        Value(name: "Understanding", definition: "Comprehending deeply and empathizing; seeing beyond surface to grasp full context."),
        Value(name: "Uniqueness", definition: "Embracing what makes you different; celebrating distinctive qualities and perspectives."),
        Value(name: "Unity", definition: "Creating cohesion and oneness; bringing people or elements together harmoniously."),
        Value(name: "Versatility", definition: "Adapting to various roles and situations; having diverse capabilities and flexibility."),
        Value(name: "Victory", definition: "Achieving wins and overcoming opposition; succeeding in competitive endeavors."),
        Value(name: "Vigor", definition: "Bringing physical and mental energy; approaching life with vitality and intensity."),
        Value(name: "Vision", definition: "Seeing possibilities for the future; having clear, inspiring ideas about what could be."),
        Value(name: "Vitality", definition: "Living with energy and aliveness; feeling vibrant and fully engaged in life."),
        Value(name: "Warmth", definition: "Showing affection and friendliness; creating comfort and positive emotional atmosphere."),
        Value(name: "Wealth", definition: "Having abundant financial resources; accumulating material prosperity."),
        Value(name: "Wisdom", definition: "Applying knowledge with good judgment; understanding deep truths about life and people."),
        Value(name: "Wonder", definition: "Experiencing awe and amazement; maintaining childlike curiosity about the world."),
        Value(name: "Zeal", definition: "Having intense enthusiasm and dedication; pursuing goals with passionate fervor.")
    ]
}
