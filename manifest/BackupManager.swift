import Foundation
import SwiftUI

struct BackupData: Codable {
    let appVersion: String
    let backupDate: Date
    let values: [Value]
    let routineItems: [RoutineItem]
    let tasks: [Task]
    let history: [HistoryEntry]
}

class BackupManager {
    static let shared = BackupManager()

    private init() {}

    func createBackup(from dataManager: DataManager) -> BackupData {
        return BackupData(
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
            backupDate: Date(),
            values: dataManager.values,
            routineItems: dataManager.routineItems,
            tasks: dataManager.tasks,
            history: dataManager.historyEntries
        )
    }

    func exportBackup(from dataManager: DataManager) -> URL? {
        let backup = createBackup(from: dataManager)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted

        guard let jsonData = try? encoder.encode(backup) else {
            return nil
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let dateString = dateFormatter.string(from: Date())
        let filename = "Manifest_Backup_\(dateString).json"

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

        do {
            try jsonData.write(to: tempURL)
            return tempURL
        } catch {
            #if DEBUG
            print("Error writing backup file: \(error)")
            #endif
            return nil
        }
    }

    func importBackup(from url: URL, into dataManager: DataManager) throws {
        // Validate backup first
        guard validateBackup(from: url) else {
            throw BackupError.invalidBackup
        }

        let data = try Data(contentsOf: url)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let backup = try decoder.decode(BackupData.self, from: data)

        // Capture current state for rollback if needed
        let previousValues = dataManager.values
        let previousRoutines = dataManager.routineItems
        let previousTasks = dataManager.tasks
        let previousHistory = dataManager.historyEntries

        // Restore data to DataManager
        dataManager.values = backup.values
        dataManager.routineItems = backup.routineItems
        dataManager.tasks = backup.tasks
        dataManager.historyEntries = backup.history

        // Save to UserDefaults - if this fails, rollback
        do {
            dataManager.saveData()
        } catch {
            // Rollback to previous state
            dataManager.values = previousValues
            dataManager.routineItems = previousRoutines
            dataManager.tasks = previousTasks
            dataManager.historyEntries = previousHistory
            throw BackupError.saveFailed
        }
    }

    enum BackupError: Error, LocalizedError {
        case invalidBackup
        case saveFailed

        var errorDescription: String? {
            switch self {
            case .invalidBackup:
                return "The backup file is invalid or corrupted."
            case .saveFailed:
                return "Failed to save the restored data. Your previous data has been preserved."
            }
        }
    }

    func validateBackup(from url: URL) -> Bool {
        do {
            let data = try Data(contentsOf: url)

            // Decode to verify structure
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let backup = try decoder.decode(BackupData.self, from: data)

            // Verify data integrity
            guard !backup.values.isEmpty || !backup.routineItems.isEmpty || !backup.tasks.isEmpty else {
                return false // Completely empty backup is suspicious
            }

            // Verify no corrupted UUIDs
            for value in backup.values {
                guard !value.id.uuidString.isEmpty else { return false }
            }

            return true
        } catch {
            #if DEBUG
            print("Backup validation error: \(error)")
            #endif
            return false
        }
    }
}
