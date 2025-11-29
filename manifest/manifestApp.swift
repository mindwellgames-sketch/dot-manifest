import SwiftUI
import UserNotifications

@main
struct manifestApp: App {
    @StateObject private var dataManager = DataManager()
    @StateObject private var locationManager = LocationManager()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("hasSeenValuesPrompt") private var hasSeenValuesPrompt = false
    @State private var showInitialValuesSelection = false

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                ContentView()
                    .environmentObject(dataManager)
                    .environmentObject(locationManager)
                    .preferredColorScheme(.light)
                    .sheet(isPresented: $showInitialValuesSelection) {
                        InitialValuesSelectionView()
                            .environmentObject(dataManager)
                            .onDisappear {
                                hasSeenValuesPrompt = true
                            }
                    }
                    .onAppear {
                        DispatchQueue.global(qos: .utility).async {
                            scheduleNotifications()
                        }

                        // Show values selection prompt if not seen yet
                        if !hasSeenValuesPrompt && dataManager.values.isEmpty {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                showInitialValuesSelection = true
                            }
                        }
                    }
                    .onChange(of: dataManager.routineItems) { _ in
                        DispatchQueue.global(qos: .utility).async {
                            scheduleNotifications()
                        }
                    }
                    .onChange(of: dataManager.tasks) { _ in
                        DispatchQueue.global(qos: .utility).async {
                            scheduleNotifications()
                        }
                    }
                    .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                        dataManager.saveAllDataImmediately()
                    }
                    .onReceive(NotificationCenter.default.publisher(for: .showiCloudError)) { notification in
                        if let userInfo = notification.userInfo,
                           let title = userInfo["title"] as? String,
                           let message = userInfo["message"] as? String {
                            dataManager.errorTitle = title
                            dataManager.errorMessage = message
                            dataManager.showErrorAlert = true
                        }
                    }
            } else {
                OnboardingView(isOnboardingComplete: $hasCompletedOnboarding)
                    .preferredColorScheme(.light)
            }
        }
    }

    private func scheduleNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        // Schedule notifications for all routine items that have notifications enabled
        for item in dataManager.routineItems {
            if item.notificationEnabled,
               let hour = item.notificationHour,
               let minute = item.notificationMinute {
                scheduleNotification(
                    id: item.id.uuidString,
                    title: item.title,
                    body: "Time for: \(item.time)",
                    hour: hour,
                    minute: minute
                )
            }
        }

        // Schedule task reminders
        scheduleTaskNotifications()
    }

    private func scheduleTaskNotifications() {
        for task in dataManager.tasks where !task.isCompleted {
            guard let dueDate = task.dueDate else { continue }

            for reminder in task.reminders {
                if let reminderDate = calculateReminderDate(reminder: reminder, task: task, dueDate: dueDate) {
                    scheduleTaskNotification(
                        id: "task-\(task.id.uuidString)-\(reminder.id.uuidString)",
                        title: task.isAppointment ? "Appointment Reminder" : "Task Reminder",
                        body: task.title,
                        date: reminderDate
                    )
                }
            }
        }
    }

    private func calculateReminderDate(reminder: Reminder, task: Task, dueDate: Date) -> Date? {
        if let customDate = reminder.customDate {
            return customDate
        } else if let minutesBefore = reminder.minutesBefore {
            let calendar = Calendar.current

            if task.isAppointment {
                // For appointments, subtract from the appointment time
                return calendar.date(byAdding: .minute, value: -minutesBefore, to: dueDate)
            } else {
                // For tasks, calculate based on 9 AM of due date
                var components = calendar.dateComponents([.year, .month, .day], from: dueDate)
                components.hour = 9
                components.minute = 0

                if let nineAM = calendar.date(from: components) {
                    if minutesBefore == 0 {
                        // On day of task at 9 AM
                        return nineAM
                    } else {
                        // Days before at 9 AM
                        return calendar.date(byAdding: .minute, value: -minutesBefore, to: nineAM)
                    }
                }
            }
        }
        return nil
    }

    private func scheduleTaskNotification(id: String, title: String, body: String, date: Date) {
        // Don't schedule notifications for past dates
        guard date > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                #if DEBUG
                print("Error scheduling task notification: \(error)")
                #endif
            } else {
                #if DEBUG
                print("✓ Scheduled task notification: \(title) at \(date)")
                #endif
            }
        }
    }

    private func scheduleNotification(id: String, title: String, body: String, hour: Int, minute: Int) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                #if DEBUG
                print("Error scheduling notification: \(error)")
                #endif
            }
        }
    }
}
