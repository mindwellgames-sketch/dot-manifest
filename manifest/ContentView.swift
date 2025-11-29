import SwiftUI
import CoreLocation
import MapKit
import UserNotifications

// MARK: - Main Content View with 4 Tabs
struct ContentView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var locationManager: LocationManager
    @State private var selectedTab = 0
    @State private var showLoadingScreen = true

    var body: some View {
        ZStack {
            // Main Tab View
            TabView(selection: $selectedTab) {
                RoutineView()
                    .tabItem {
                        Image(systemName: "sun.haze.fill")
                    }
                    .tag(0)
                    .accessibilityLabel("My Routine tab")

                ToDoView()
                    .tabItem {
                        Image(systemName: "checklist")
                    }
                    .tag(1)
                    .accessibilityLabel("To Do tab")

                ValuesView()
                    .tabItem {
                        Image(systemName: "v.circle")
                    }
                    .tag(2)
                    .accessibilityLabel("Values tab")

                HistoryView()
                    .tabItem {
                        Image(systemName: "chart.bar.xaxis")
                    }
                    .tag(3)
                    .accessibilityLabel("History tab")

                SettingsView()
                    .tabItem {
                        Image(systemName: "gearshape")
                    }
                    .tag(4)
                    .accessibilityLabel("Settings tab")
            }
            .accentColor(.black)

            // Loading Screen Overlay
            if showLoadingScreen {
                LoadingScreen(isShowing: $showLoadingScreen)
                    .transition(.opacity)
            }
        }
        .alert(isPresented: $dataManager.showErrorAlert) {
            Alert(
                title: Text(dataManager.errorTitle),
                message: Text(dataManager.errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

// MARK: - Loading Screen with Quote
struct LoadingScreen: View {
    @EnvironmentObject var dataManager: DataManager
    @Binding var isShowing: Bool
    @State private var quote: Quote?

    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 30) {
                Text(".manifest")
                    .font(.custom("Georgia-Bold", size: 28))
                    .foregroundColor(.primary)

                if let quote = quote {
                    VStack(spacing: 12) {
                        Text("\"\(quote.text)\"")
                            .font(.custom("Georgia", size: 18))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)

                        Text("— \(quote.author)")
                            .font(.custom("Georgia", size: 14))
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .onTapGesture {
            withAnimation(.easeOut(duration: 0.4)) {
                isShowing = false
            }
        }
        .onAppear {
            quote = dataManager.randomQuote()
        }
    }
}

// MARK: - Routine View (Tab 1) - Timeline View
struct RoutineView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var locationManager: LocationManager
    @State private var showingAddRoutine = false
    @State private var selectedDate: Date = Date()

    // Filter routines for selected day's weekday
    var filteredRoutines: [RoutineItem] {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: selectedDate) - 1 // 0=Sun, 6=Sat

        return dataManager.routineItems.filter { item in
            item.isActiveOn(weekday: weekday) && item.startTime != nil
        }.sorted { ($0.startTime ?? Date()) < ($1.startTime ?? Date()) }
    }

    var body: some View {
        ZStack {
            // Standard background color
            Color(uiColor: .systemGroupedBackground)

            VStack(spacing: 0) {
                // Month label and Date Selector
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(monthYearString)
                            .font(.custom("Georgia", size: 16))
                            .foregroundColor(.primary)

                        Spacer()

                        Text(".my routine")
                            .font(.custom("Georgia-Bold", size: 23))
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal)

                    DateSelector(selectedDate: $selectedDate)
                        .padding(.horizontal)
                }
                .padding(.top, 16)
                .padding(.bottom, 12)
                .background(Color(uiColor: .secondarySystemBackground))
                .shadow(color: Color.primary.opacity(0.05), radius: 4, y: 2)

                if filteredRoutines.isEmpty {
                    // Empty State
                    VStack(spacing: 20) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 72))
                            .foregroundColor(.secondary.opacity(0.4))

                        Text("No routines for \(dayName)")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(.primary)

                        Button(action: {
                            showingAddRoutine = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 16))
                                Text("Add Your First Routine")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 14)
                            .background(Color.black)
                            .cornerRadius(12)
                        }
                        .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.opacity)
                    .animation(.easeIn(duration: 0.3), value: filteredRoutines.isEmpty)
                } else {
                    // Timeline View
                    TimelineView(routines: filteredRoutines, selectedDate: selectedDate)
                }
            }

            // Floating Action Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        showingAddRoutine = true
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.primary)
                            .frame(width: 60, height: 60)
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        Circle()
                                            .stroke(Color(uiColor: .systemBackground).opacity(0.5), lineWidth: 1)
                                    )
                                    .shadow(color: Color.primary.opacity(0.15), radius: 10, x: 0, y: 4)
                            )
                    }
                    .accessibilityLabel("Add routine item")
                    .accessibilityHint("Opens form to create a new routine item")
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .sheet(isPresented: $showingAddRoutine) {
            AddRoutineItemView()
        }
    }

    var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedDate)
    }

    var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: selectedDate)
    }
}

// MARK: - Week Selector Component (Sunday-Saturday)
struct DateSelector: View {
    @Binding var selectedDate: Date
    @AppStorage("weekStartDay") private var weekStartDay = 1 // 1=Sunday, 2=Monday, ..., 7=Saturday

    var dates: [Date] {
        let calendar = Calendar.current
        let today = Date()

        // Find the most recent week start based on user preference (1=Sunday through 7=Saturday)
        let weekday = calendar.component(.weekday, from: today) // 1=Sunday, 2=Monday, etc.

        // Calculate days from week start
        // If today's weekday >= weekStartDay, subtract directly
        // If today's weekday < weekStartDay, need to go back to previous week
        let daysFromWeekStart: Int
        if weekday >= weekStartDay {
            daysFromWeekStart = weekday - weekStartDay
        } else {
            daysFromWeekStart = 7 - (weekStartDay - weekday)
        }

        guard let weekStart = calendar.date(byAdding: .day, value: -daysFromWeekStart, to: calendar.startOfDay(for: today)) else {
            return []
        }

        // Return current week (7 days starting from weekStart)
        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: weekStart)
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            ForEach(dates, id: \.self) { date in
                let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)

                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedDate = date
                    }
                }) {
                    VStack(spacing: 4) {
                        // Date number (large)
                        Text("\(Calendar.current.component(.day, from: date))")
                            .font(.system(size: 18))
                            .foregroundColor(isSelected ? Color(uiColor: .systemBackground) : .primary)

                        // Day letter (small)
                        Text(dayLetter(date))
                            .font(.system(size: 10))
                            .foregroundColor(isSelected ? Color(uiColor: .systemBackground).opacity(0.9) : .gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isSelected ? Color.primary : Color(uiColor: .secondarySystemBackground))
                            .shadow(color: isSelected ? Color.primary.opacity(0.15) : Color.clear, radius: 8, y: 4)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(dateAccessibilityLabel(date))
                .accessibilityAddTraits(isSelected ? [.isSelected] : [])
            }
        }
    }

    func dayLetter(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        let dayString = formatter.string(from: date)
        return String(dayString.prefix(1))
    }

    func dateAccessibilityLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Timeline View Component
struct TimelineView: View {
    let routines: [RoutineItem]
    let selectedDate: Date
    let timeWidth: CGFloat = 65

    var body: some View {
        ScrollView {
            ZStack(alignment: .topLeading) {
                // Time labels positioned at card tops
                ForEach(Array(routines.enumerated()), id: \.element.id) { index, routine in
                    Text(timeString(routine.startTime))
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .frame(width: timeWidth, alignment: .trailing)
                        .padding(.trailing, 4)
                        .offset(y: CGFloat(index) * 92) // 80px card + 12px spacing
                }

                // Routine cards
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(routines) { routine in
                        TimelineCard(routine: routine, selectedDate: selectedDate, timeWidth: timeWidth)
                            .padding(.leading, timeWidth + 8)
                            .padding(.trailing, 16)
                            .transition(.asymmetric(insertion: .move(edge: .leading).combined(with: .opacity), removal: .move(edge: .trailing).combined(with: .opacity)))
                    }
                }
            }
            .padding(.top, 20)
            .padding(.bottom, 100)
        }
    }

    func timeString(_ date: Date?) -> String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

// MARK: - Timeline Card
struct TimelineCard: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var locationManager: LocationManager
    let routine: RoutineItem
    let selectedDate: Date
    let timeWidth: CGFloat
    @State private var showingEditSheet = false
    @State private var showingValuesToast = false
    @State private var locationUpdateTrigger: UUID = UUID()
    @State private var isPressed = false

    // Gradient caching for performance
    @State private var cachedGradient: LinearGradient?
    @State private var lastGradientHour: Int?

    var cardHeight: CGFloat {
        return 80 // Standard size for all cards
    }

    var valueNames: String {
        let names = routine.valueIds.compactMap { valueId in
            dataManager.getValue(by: valueId)?.name
        }
        return "Serves: " + names.joined(separator: ", ")
    }

    var isCompleted: Bool {
        let calendar = Calendar.current
        if let entry = dataManager.historyEntries.first(where: {
            calendar.isDate($0.date, inSameDayAs: selectedDate)
        }) {
            return entry.completedRoutineIds.contains(routine.id)
        }
        return false
    }

    var timeOfDayGradient: LinearGradient {
        let _ = locationUpdateTrigger // Force dependency on location updates

        let currentTime = Date()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: currentTime)

        // Return cached gradient if hour hasn't changed
        if let cached = cachedGradient, let lastHour = lastGradientHour, lastHour == currentHour {
            return cached
        }

        // Calculate new gradient
        let sunrise: Date
        let sunset: Date

        if let location = locationManager.lastLocation {
            #if DEBUG
            print("🌍 Using REAL location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
            #endif
            let solarTimes = dataManager.solarCalculator.calculateSolarTimes(for: location)
            sunrise = solarTimes.sunrise
            sunset = solarTimes.sunset

            #if DEBUG
            // Create formatters for UTC and local time display
            let utcFormatter = DateFormatter()
            utcFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            utcFormatter.dateFormat = "HH:mm"

            let localFormatter = DateFormatter()
            localFormatter.timeZone = TimeZone.current
            localFormatter.dateFormat = "HH:mm zzz"

            print("☀️ Sunrise: \(utcFormatter.string(from: sunrise)) UTC = \(localFormatter.string(from: sunrise))")
            print("🌅 Sunset: \(utcFormatter.string(from: sunset)) UTC = \(localFormatter.string(from: sunset))")
            print("🕐 Current: \(utcFormatter.string(from: currentTime)) UTC = \(localFormatter.string(from: currentTime))")
            #endif
        } else {
            #if DEBUG
            print("⚠️ NO LOCATION - using defaults (6 AM / 6 PM)")
            #endif
            // Default sunrise/sunset times if location unavailable (6 AM / 6 PM)
            let now = Date()
            sunrise = calendar.date(bySettingHour: 6, minute: 0, second: 0, of: now) ?? now
            sunset = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: now) ?? now
        }

        let gradient = TimeOfDayGradient.gradientForTime(currentTime, sunrise: sunrise, sunset: sunset)

        #if DEBUG
        print("🎨 Gradient computed for \(routine.title)")
        #endif

        // Cache the gradient
        DispatchQueue.main.async {
            cachedGradient = gradient
            lastGradientHour = currentHour
        }

        return gradient
    }

    func toggleCompletion() {
        let calendar = Calendar.current
        let wasCompleted = isCompleted

        // Find or create history entry for selected date
        if let index = dataManager.historyEntries.firstIndex(where: {
            calendar.isDate($0.date, inSameDayAs: selectedDate)
        }) {
            // Entry exists, toggle completion
            var entry = dataManager.historyEntries[index]
            if let routineIndex = entry.completedRoutineIds.firstIndex(of: routine.id) {
                entry.completedRoutineIds.remove(at: routineIndex)
            } else {
                entry.completedRoutineIds.append(routine.id)
            }
            dataManager.historyEntries[index] = entry
        } else {
            // Create new entry
            let newEntry = HistoryEntry(
                date: selectedDate,
                completedRoutineIds: [routine.id],
                completedTaskIds: []
            )
            dataManager.historyEntries.append(newEntry)
        }

        dataManager.saveData()

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        if !wasCompleted {
            // Success haptic when completing
            generator.notificationOccurred(.success)
        } else {
            // Light haptic when uncompleting
            let lightGenerator = UIImpactFeedbackGenerator(style: .light)
            lightGenerator.impactOccurred()
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Icon (or blank space if no icon) - fixed width to prevent text shift
            ZStack {
                if !routine.icon.isEmpty {
                    Image(systemName: routine.icon)
                        .font(.system(size: 20))
                        .foregroundColor(.primary)
                }
            }
            .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(routine.title)
                    .font(.system(size: 16))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .strikethrough(isCompleted, color: .secondary)

                Text(timeRangeString)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                // Dots + info icon for values
                if !routine.valueIds.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(0..<routine.valueIds.count, id: \.self) { _ in
                            Circle()
                                .fill(Color.primary)
                                .frame(width: 5, height: 5)
                        }

                        Button(action: {
                            showingValuesToast = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                showingValuesToast = false
                            }
                        }) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Spacer()

            // Completion toggle circle on right side
            Button(action: toggleCompletion) {
                Image(systemName: isCompleted ? "circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(.primary)
                    .scaleEffect(isCompleted ? 1.0 : 0.95)
                    .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isCompleted)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .frame(height: cardHeight)
        .clipped()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(timeOfDayGradient)
                .opacity(0.25)
                .shadow(color: Color.primary.opacity(0.08), radius: 8, x: 0, y: 4)
        )
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .opacity(isPressed ? 0.8 : 1.0)
        .animation(.easeOut(duration: 0.15), value: isPressed)
        .onTapGesture {
            showingEditSheet = true
        }
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .overlay(
            Group {
                if showingValuesToast {
                    VStack {
                        Spacer()
                        Text(valueNames)
                            .font(.system(size: 12))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(uiColor: .secondarySystemBackground).opacity(0.95))
                            .cornerRadius(6)
                            .padding(.bottom, 6)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.3), value: showingValuesToast)
                }
            }
        )
        .onChange(of: locationManager.lastLocation) { _ in
            #if DEBUG
            print("📍 Location changed! Triggering gradient update...")
            #endif
            locationUpdateTrigger = UUID()
        }
        .sheet(isPresented: $showingEditSheet) {
            EditRoutineItemView(item: routine)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(routine.title), \(timeRangeString)")
        .accessibilityValue(isCompleted ? "Completed" : "Not completed")
        .accessibilityHint("Double tap to edit. Double tap the circle to toggle completion.")
    }

    var timeRangeString: String {
        guard let start = routine.startTime, let end = routine.endTime else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
}

struct RoutineItemRow: View {
    @EnvironmentObject var dataManager: DataManager
    let item: RoutineItem
    @State private var isCompleted = false
    @State private var showingValuesToast = false
    @State private var showingEditSheet = false

    var valueNames: String {
        let names = item.valueIds.compactMap { valueId in
            dataManager.getValue(by: valueId)?.name
        }
        return "Serves: " + names.joined(separator: ", ")
    }

    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            Button(action: {
                isCompleted.toggle()
                if isCompleted {
                    dataManager.addCompletedRoutineToHistory(routineId: item.id)
                    // Show toast with values served
                    if !item.valueIds.isEmpty {
                        showingValuesToast = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            showingValuesToast = false
                        }
                    }
                }
            }) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(isCompleted ? .black : .gray)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.system(size: 17))
                    .foregroundColor(.primary)
                    .strikethrough(isCompleted, color: .gray)

                if !item.time.isEmpty {
                    Text(item.time)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }

                // Show dots + info icon for values
                if !item.valueIds.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(0..<item.valueIds.count, id: \.self) { _ in
                            Circle()
                                .fill(Color.primary)
                                .frame(width: 6, height: 6)
                        }

                        Button(action: {
                            showingValuesToast = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                showingValuesToast = false
                            }
                        }) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Spacer()

            ZStack {
                if !item.icon.isEmpty {
                    Image(systemName: item.icon)
                        .font(.system(size: 20))
                        .foregroundColor(.gray)
                }
            }
            .frame(width: 20, height: 20)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(uiColor: .secondarySystemBackground))
                .shadow(color: Color.primary.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .onTapGesture {
            showingEditSheet = true
        }
        .overlay(
            Group {
                if showingValuesToast {
                    VStack {
                        Spacer()
                        Text(valueNames)
                            .font(.system(size: 13))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color(uiColor: .secondarySystemBackground).opacity(0.95))
                            .cornerRadius(8)
                            .padding(.bottom, 8)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.3), value: showingValuesToast)
                }
            }
        )
        .sheet(isPresented: $showingEditSheet) {
            EditRoutineItemView(item: item)
        }
    }
}

// MARK: - To-Do View (Tab 2) with Gradient
struct ToDoView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var locationManager: LocationManager
    @State private var showingAddTask = false
    @State private var showingUrgencyHelp = false

    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Custom Header
                HStack {
                    Text(".to do list")
                        .font(.custom("Georgia-Bold", size: 23))
                        .foregroundColor(.black)
                        .padding(.leading, 12)

                    Spacer()

                    Button(action: {
                        showingUrgencyHelp = true
                    }) {
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: 18))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 12)
                    .popover(isPresented: $showingUrgencyHelp) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Task Urgency Colors")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.primary)

                            Text("Each task card shows a color that indicates how soon it's due:")
                                .font(.system(size: 15))
                                .foregroundColor(.primary)

                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 8) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.red.opacity(0.2))
                                        .frame(width: 24, height: 24)
                                    Text("0-2 days (urgent)")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                }
                                HStack(spacing: 8) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.orange.opacity(0.18))
                                        .frame(width: 24, height: 24)
                                    Text("3-6 days (soon)")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                }
                                HStack(spacing: 8) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.yellow.opacity(0.18))
                                        .frame(width: 24, height: 24)
                                    Text("7-9 days (moderate)")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                }
                                HStack(spacing: 8) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.green.opacity(0.14))
                                        .frame(width: 24, height: 24)
                                    Text("10+ days (plenty of time)")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                }
                            }

                            Text("The color helps you prioritize at a glance.")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                        }
                        .padding(20)
                        .frame(maxWidth: 320)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 12)
                .background(Color(uiColor: .secondarySystemBackground))

                if dataManager.overdueTasks.isEmpty && dataManager.activeNonOverdueTasks.isEmpty {
                    // Empty State
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 72))
                            .foregroundColor(.secondary.opacity(0.4))

                        Text("All Clear!")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(.primary)

                        Button(action: {
                            showingAddTask = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 16))
                                Text("Add a Task")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 14)
                            .background(Color.black)
                            .cornerRadius(12)
                        }
                        .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.opacity)
                    .animation(.easeIn(duration: 0.3), value: dataManager.overdueTasks.isEmpty && dataManager.activeNonOverdueTasks.isEmpty)
                } else {
                    List {
                        // Overdue Section
                        if !dataManager.overdueTasks.isEmpty {
                            Section {
                                OverdueSection(tasks: dataManager.overdueTasks)
                            }
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                        }

                        // Active Tasks (Gradient)
                        ForEach(dataManager.activeNonOverdueTasks) { task in
                            TaskCard(task: task)
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                }
            }

            // Floating Action Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        showingAddTask = true
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.primary)
                            .frame(width: 60, height: 60)
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        Circle()
                                            .stroke(Color(uiColor: .systemBackground).opacity(0.5), lineWidth: 1)
                                    )
                                    .shadow(color: Color.primary.opacity(0.15), radius: 10, x: 0, y: 4)
                            )
                    }
                    .accessibilityLabel("Add task or appointment")
                    .accessibilityHint("Opens form to create a new task or appointment")
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .sheet(isPresented: $showingAddTask) {
            AddTaskView()
        }
    }
}

struct OverdueSection: View {
    let tasks: [Task]
    @State private var isExpanded = true

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button(action: {
                withAnimation {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text("OVERDUE · \(tasks.count)")
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }

            // Tasks
            if isExpanded {
                VStack(spacing: 8) {
                    ForEach(tasks) { task in
                        TaskCard(task: task, isOverdue: true)
                            .transition(.asymmetric(insertion: .move(edge: .leading).combined(with: .opacity), removal: .move(edge: .trailing).combined(with: .opacity)))
                    }
                }
                .padding(.top, 8)
            }
        }
    }
}

struct TaskCard: View {
    @EnvironmentObject var dataManager: DataManager
    let task: Task
    var isOverdue: Bool = false
    @State private var showingValuesToast = false
    @State private var showingEditSheet = false
    @State private var showingUndoToast = false
    @State private var undoTimer: Timer?
    @State private var completedTaskSnapshot: Task?
    @State private var isPressed = false

    var valueNames: String {
        let names = task.valueIds.compactMap { valueId in
            dataManager.getValue(by: valueId)?.name
        }
        return "Serves: " + names.joined(separator: ", ")
    }

    var backgroundColor: Color {
        if isOverdue {
            return Color.red.opacity(0.15) // Soft transparent red
        }

        guard let days = task.daysUntilDue else {
            return Color.gray.opacity(0.1)
        }

        // Gradient: 0 days = red, 14+ days = green (soft, transparent versions)
        switch days {
        case 0:
            return Color.red.opacity(0.2) // Soft red
        case 1:
            return Color.red.opacity(0.18) // Soft red
        case 2:
            return Color.orange.opacity(0.18) // Soft red-orange
        case 3...4:
            return Color.orange.opacity(0.16) // Soft orange
        case 5...6:
            return Color.yellow.opacity(0.18) // Soft yellow
        case 7...9:
            return Color.green.opacity(0.15) // Soft yellow-green
        case 10...13:
            return Color.green.opacity(0.14) // Soft green
        default:
            return Color.green.opacity(0.12) // Soft deep green
        }
    }

    var textColor: Color {
        // With soft transparent backgrounds, always use black text
        return .black
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.system(size: 16, weight: task.isAppointment ? .bold : .regular))
                    .foregroundColor(textColor)

                Text(dueDateText)
                    .font(.system(size: 13))
                    .foregroundColor(textColor.opacity(0.8))

                // Show location if appointment has one
                if task.isAppointment, let location = task.location, !location.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 11))
                            .foregroundColor(textColor.opacity(0.7))
                        Text(location)
                            .font(.system(size: 12))
                            .foregroundColor(textColor.opacity(0.7))
                    }
                }

                // Show dots + info icon for values
                if !task.valueIds.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(0..<task.valueIds.count, id: \.self) { _ in
                            Circle()
                                .fill(textColor)
                                .frame(width: 6, height: 6)
                        }

                        Button(action: {
                            showingValuesToast = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                showingValuesToast = false
                            }
                        }) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 14))
                                .foregroundColor(textColor.opacity(0.7))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Spacer()

            // Days remaining counter on the right
            if let days = task.daysUntilDue {
                VStack(alignment: .center, spacing: 2) {
                    Text("Days rem:")
                        .font(.system(size: 11))
                        .foregroundColor(textColor.opacity(0.7))
                    Text("\(days)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(textColor)
                }
                .frame(minWidth: 60, alignment: .trailing)
                .padding(.top, 2)
            }
        }
        .padding(16)
        .background(backgroundColor)
        .cornerRadius(12)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .opacity(isPressed ? 0.8 : 1.0)
        .animation(.easeOut(duration: 0.15), value: isPressed)
        .onTapGesture {
            showingEditSheet = true
        }
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(action: {
                completeTaskWithUndo()
            }) {
                Label("Complete", systemImage: "checkmark")
            }
            .tint(.green)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            if !task.isAppointment {
                Button(action: {
                    dataManager.snoozeTask(task, days: 1)
                }) {
                    Label("Snooze", systemImage: "clock.arrow.circlepath")
                }
                .tint(.blue)
            }
        }
        .overlay(
            Group {
                // Undo Toast
                if showingUndoToast {
                    VStack {
                        Spacer()
                        HStack {
                            Text("Task marked complete")
                                .font(.system(size: 14))
                                .foregroundColor(.white)

                            Spacer()

                            Button(action: undoTaskCompletion) {
                                Text("UNDO")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.black.opacity(0.9))
                        .cornerRadius(8)
                        .padding(.horizontal)
                        .padding(.bottom, 80)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.3), value: showingUndoToast)
                }

                // Values info toast
                if showingValuesToast {
                    VStack {
                        Spacer()
                        Text(valueNames)
                            .font(.system(size: 13))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color(uiColor: .secondarySystemBackground).opacity(0.95))
                            .cornerRadius(8)
                            .padding(.bottom, 8)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.3), value: showingValuesToast)
                }
            }
        )
        .onDisappear {
            undoTimer?.invalidate()
        }
        .sheet(isPresented: $showingEditSheet) {
            EditTaskView(task: task)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabelText)
        .accessibilityValue(task.isCompleted ? "Completed" : "Not completed")
        .accessibilityHint("Double tap to edit. Swipe right to complete. \(task.isAppointment ? "" : "Swipe left to snooze.")")
    }

    var accessibilityLabelText: String {
        var label = "\(task.isAppointment ? "Appointment" : "Task"), \(task.title), \(dueDateText)"
        if let location = task.location, !location.isEmpty {
            label += ", Location: \(location)"
        }
        if let days = task.daysUntilDue {
            label += ", \(days) days remaining"
        } else if isOverdue {
            label += ", Overdue"
        }
        return label
    }

    var dueDateText: String {
        guard let dueDate = task.dueDate else { return "" }
        let calendar = Calendar.current

        // Time formatter for appointments
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        let timeString = task.isAppointment ? " at \(timeFormatter.string(from: dueDate))" : ""

        let prefix = task.isAppointment ? "Appt:" : "Want done by:"

        if calendar.isDateInToday(dueDate) {
            return "\(prefix) Today\(timeString)"
        } else if calendar.isDateInTomorrow(dueDate) {
            return "\(prefix) Tomorrow\(timeString)"
        } else if let days = task.daysUntilDue, days < 7 {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return "\(prefix) \(formatter.string(from: dueDate))\(timeString)"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return "\(prefix) \(formatter.string(from: dueDate))\(timeString)"
        }
    }

    // MARK: - Undo Helper Methods
    func completeTaskWithUndo() {
        completedTaskSnapshot = task
        dataManager.completeTask(task)

        // Success haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        showUndoToast()
    }

    func showUndoToast() {
        // Cancel existing timer
        undoTimer?.invalidate()

        withAnimation {
            showingUndoToast = true
        }

        // Auto-dismiss after 5 seconds
        undoTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
            withAnimation {
                showingUndoToast = false
            }
            completedTaskSnapshot = nil
        }
    }

    func undoTaskCompletion() {
        undoTimer?.invalidate()

        withAnimation {
            showingUndoToast = false
        }

        // Restore the task back to active tasks
        if let snapshot = completedTaskSnapshot {
            dataManager.uncompleteTask(snapshot)
            completedTaskSnapshot = nil
        }
    }
}

// MARK: - Values View (Tab 3)
struct ValuesView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var locationManager: LocationManager
    @State private var searchText = ""
    @State private var showingAddCustomValue = false
    @State private var showingSearch = false

    var activeValues: [Value] {
        dataManager.values.filter { $0.isActive }.sorted { $0.name < $1.name }
    }

    var inactiveValues: [Value] {
        let filtered = dataManager.values.filter { !$0.isActive }
        if searchText.isEmpty {
            return filtered.sorted { $0.name < $1.name }
        } else {
            return filtered.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }.sorted { $0.name < $1.name }
        }
    }

    // Group inactive values by first letter
    var groupedInactiveValues: [(String, [Value])] {
        let grouped = Dictionary(grouping: inactiveValues) { value in
            String(value.name.prefix(1)).uppercased()
        }
        return grouped.sorted { $0.key < $1.key }.map { ($0.key, $0.value.sorted { $0.name < $1.name }) }
    }

    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)

            VStack(spacing: 0) {
                // Custom Header
                HStack {
                    Text(".my values")
                        .font(.custom("Georgia-Bold", size: 23))
                        .foregroundColor(.black)
                        .padding(.leading, 12)

                    Spacer()

                    HStack(spacing: 16) {
                        // Search button
                        if !dataManager.values.isEmpty {
                            Button(action: {
                                showingSearch.toggle()
                            }) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.black)
                                    .padding(8)
                                    .background(Circle().fill(Color(uiColor: .systemGray5)))
                            }
                        }

                        // Add button
                        Button(action: {
                            showingAddCustomValue = true
                        }) {
                            Image(systemName: "plus")
                                .foregroundColor(.black)
                                .padding(8)
                                .background(Circle().fill(Color(uiColor: .systemGray5)))
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 12)
                .background(Color(uiColor: .secondarySystemBackground))

                List {
                    // Active Values Section
                    if !activeValues.isEmpty {
                        Section(header: Text("I'm focussing on these (\(activeValues.count)) values:")) {
                            ForEach(activeValues) { value in
                                ValueRow(value: value, isActive: true)
                            }
                        }
                    }

                    // All Values Section (A-Z)
                    if !searchText.isEmpty {
                        // When searching, show flat list
                        Section(header: Text("Values to consider:")) {
                            ForEach(inactiveValues) { value in
                                ValueRow(value: value, isActive: false)
                            }
                        }
                    } else {
                        // When not searching, show grouped by letter
                        Section(header: Text("Values to consider:")) {
                            ForEach(groupedInactiveValues, id: \.0) { letter, values in
                                Section(header: Text(letter).font(.system(size: 20)).foregroundColor(.black)) {
                                    ForEach(values) { value in
                                        ValueRow(value: value, isActive: false)
                                    }
                                }
                            }
                        }
                    }

                    // Empty state
                    if dataManager.values.isEmpty {
                        Section {
                            VStack(spacing: 12) {
                                Image(systemName: "star.circle")
                                    .font(.system(size: 48))
                                    .foregroundColor(.gray)
                                Text("No active values yet")
                                    .font(.system(size: 20))
                                Text("Tap + to browse all values and activate the ones that matter to you")
                                    .font(.system(size: 15))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 20)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddCustomValue) {
            AddCustomValueView()
        }
        .sheet(isPresented: $showingSearch) {
            SearchValuesView(searchText: $searchText)
        }
    }
}

struct ValueRow: View {
    @EnvironmentObject var dataManager: DataManager
    let value: Value
    let isActive: Bool
    @State private var showingDefinition = false

    var body: some View {
        HStack {
            // Value name - tap to see definition
            Button(action: {
                showingDefinition = true
            }) {
                Text(value.name)
                    .font(.system(size: 17))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            Spacer()

            // Activation toggle
            Button(action: {
                dataManager.toggleValueActive(value)
            }) {
                Image(systemName: value.isActive ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(value.isActive ? .black : .gray)
                    .scaleEffect(value.isActive ? 1.0 : 0.95)
                    .animation(.spring(response: 0.25, dampingFraction: 0.6), value: value.isActive)
            }
            .buttonStyle(.plain)
        }
        .sheet(isPresented: $showingDefinition) {
            ValueDetailView(value: value)
        }
    }
}

struct ValueDetailView: View {
    @Environment(\.dismiss) var dismiss
    let value: Value

    var body: some View {
        ZStack {
            // Background
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Close button
                HStack {
                    Spacer()
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.gray.opacity(0.5))
                    }
                    .padding(.top, 20)
                    .padding(.trailing, 20)
                }

                // Content card
                VStack(alignment: .leading, spacing: 24) {
                    // Value name
                    Text(value.name)
                        .font(.custom("Georgia", size: 36))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    // Decorative line
                    Rectangle()
                        .fill(Color.black)
                        .frame(height: 2)
                        .frame(maxWidth: 60)

                    // Definition
                    Text(value.definition)
                        .font(.custom("Georgia", size: 18))
                        .foregroundColor(.primary.opacity(0.8))
                        .lineSpacing(8)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer()
                }
                .padding(32)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .background(value.color.opacity(0.15))
                .cornerRadius(20)
                .shadow(color: Color.primary.opacity(0.1), radius: 20, x: 0, y: 10)
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .padding(.bottom, 60)
            }
        }
    }
}

// MARK: - History View (Tab 4)
// MARK: - Time Range Filter
enum TimeRange: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case year = "Year"
    case all = "All Time"
}

struct HistoryView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var locationManager: LocationManager
    @State private var selectedTimeRange: TimeRange = .month

    // Filter history entries based on selected time range
    var filteredHistoryEntries: [HistoryEntry] {
        let calendar = Calendar.current
        let now = Date()

        switch selectedTimeRange {
        case .week:
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
            return dataManager.historyEntries.filter { $0.date >= weekAgo }
        case .month:
            let monthAgo = calendar.date(byAdding: .month, value: -1, to: now) ?? now
            return dataManager.historyEntries.filter { $0.date >= monthAgo }
        case .year:
            let yearAgo = calendar.date(byAdding: .year, value: -1, to: now) ?? now
            return dataManager.historyEntries.filter { $0.date >= yearAgo }
        case .all:
            return dataManager.historyEntries
        }
    }

    // Group completed tasks by month (filter out entries with only routines)
    var groupedTasks: [(monthYear: String, tasks: [(task: Task, date: Date)])] {
        _ = Calendar.current
        var tasksByMonth: [String: [(task: Task, date: Date)]] = [:]

        // Collect all completed tasks from filtered history
        for entry in filteredHistoryEntries {
            // Only process entries that have completed tasks
            guard !entry.completedTaskIds.isEmpty else { continue }

            for taskId in entry.completedTaskIds {
                if let task = dataManager.tasks.first(where: { $0.id == taskId }) {
                    let monthFormatter = DateFormatter()
                    monthFormatter.dateFormat = "MMMM yyyy"
                    let monthYear = monthFormatter.string(from: entry.date)

                    tasksByMonth[monthYear, default: []].append((task: task, date: entry.date))
                }
            }
        }

        // Convert to sorted array (most recent months first)
        return tasksByMonth.map { (monthYear, tasks) in
            (monthYear: monthYear, tasks: tasks.sorted { $0.date > $1.date })
        }.sorted { month1, month2 in
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            let date1 = formatter.date(from: month1.monthYear) ?? Date.distantPast
            let date2 = formatter.date(from: month2.monthYear) ?? Date.distantPast
            return date1 > date2
        }
    }

    var valueAnalytics: [(valueName: String, daysServed: Int)] {
        var valueDaysMap: [UUID: Set<Date>] = [:]

        // Collect unique dates for each value from filtered entries
        for entry in filteredHistoryEntries {
            let calendar = Calendar.current
            let normalizedDate = calendar.startOfDay(for: entry.date)

            // Check completed tasks
            for taskId in entry.completedTaskIds {
                if let task = dataManager.tasks.first(where: { $0.id == taskId }) {
                    for valueId in task.valueIds {
                        valueDaysMap[valueId, default: Set()].insert(normalizedDate)
                    }
                }
            }

            // Check completed routines
            for routineId in entry.completedRoutineIds {
                if let routine = dataManager.routineItems.first(where: { $0.id == routineId }) {
                    for valueId in routine.valueIds {
                        valueDaysMap[valueId, default: Set()].insert(normalizedDate)
                    }
                }
            }
        }

        // Convert to sorted array
        return valueDaysMap.compactMap { (valueId, dates) in
            if let value = dataManager.getValue(by: valueId) {
                return (valueName: value.name, daysServed: dates.count)
            }
            return nil
        }.sorted { $0.daysServed > $1.daysServed }
    }

    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)

            VStack(spacing: 0) {
                // Custom Header with Time Range Filter
                VStack(spacing: 8) {
                    HStack {
                        Text(".analysis")
                            .font(.custom("Georgia-Bold", size: 23))
                            .foregroundColor(.black)
                            .padding(.leading, 12)

                        Spacer()
                    }

                    // Time Range Picker
                    Picker("Time Range", selection: $selectedTimeRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 12)
                }
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 12)
                .background(Color(uiColor: .secondarySystemBackground))

                if valueAnalytics.isEmpty && groupedTasks.isEmpty {
                    // Empty State
                    VStack(spacing: 20) {
                        Image(systemName: "chart.bar")
                            .font(.system(size: 72))
                            .foregroundColor(.gray.opacity(0.3))

                        Text("No data yet")
                            .font(.system(size: 22))
                            .fontWeight(.medium)
                            .foregroundColor(.gray)

                        Text("Complete tasks and routines to see your progress")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                } else {
                    List {
                        // Section 1: Values I Served
                        if !valueAnalytics.isEmpty {
                            Section(header: Text("Values I Served")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                            .textCase(nil)) {
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(valueAnalytics, id: \.valueName) { item in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.valueName)
                                            .font(.system(size: 14))
                                            .foregroundColor(.primary)

                                        HStack(spacing: 8) {
                                            // Bar
                                            let maxDays = max(valueAnalytics.first?.daysServed ?? 1, 1)
                                            let barWidth = min(CGFloat(item.daysServed) / CGFloat(maxDays), 1.0)

                                            Rectangle()
                                                .fill(Color(red: 34/255, green: 139/255, blue: 34/255))
                                                .frame(width: max(barWidth * 200, 0), height: 20)
                                                .cornerRadius(4)

                                            // Days count
                                            Text("\(item.daysServed) day\(item.daysServed == 1 ? "" : "s")")
                                                .font(.system(size: 12))
                                                .foregroundColor(.gray)
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }

                    // Section 2: Completed Tasks
                    if !groupedTasks.isEmpty {
                        Section(header: Text("Completed Tasks")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                            .textCase(nil)) {
                            ForEach(groupedTasks, id: \.monthYear) { monthGroup in
                                DisclosureGroup(monthGroup.monthYear) {
                                    ForEach(monthGroup.tasks, id: \.task.id) { taskItem in
                                        CompletedTaskRow(task: taskItem.task, completionDate: taskItem.date)
                                    }
                                }
                            }
                        }
                    }
                    }
                }
            }
        }
    }
}

// MARK: - Completed Task Row
struct CompletedTaskRow: View {
    @EnvironmentObject var dataManager: DataManager
    let task: Task
    let completionDate: Date

    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: completionDate)
    }

    var valueNames: String {
        let names = task.valueIds.compactMap { valueId in
            dataManager.getValue(by: valueId)?.name
        }
        return names.isEmpty ? "" : "Serves: " + names.joined(separator: ", ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(task.title)
                .font(.system(size: 15))
                .foregroundColor(.primary)
                .strikethrough()

            HStack {
                Text(dateString)
                    .font(.system(size: 13))
                    .foregroundColor(.gray)

                if !valueNames.isEmpty {
                    Text("•")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)

                    Text(valueNames)
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct HistoryEntryRow: View {
    @EnvironmentObject var dataManager: DataManager
    let entry: HistoryEntry
    @State private var showingDeleteConfirmation = false

    var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd"
        return formatter.string(from: entry.date)
    }

    var body: some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 8) {
                // Completed Routines
                if !entry.completedRoutineIds.isEmpty {
                    ForEach(entry.completedRoutineIds, id: \.self) { routineId in
                        if let routine = dataManager.routineItems.first(where: { $0.id == routineId }) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(routine.title)
                                    .font(.system(size: 14))
                                    .foregroundColor(.primary)
                                    .strikethrough(true, color: .secondary)

                                // Associated values
                                if !routine.valueIds.isEmpty {
                                    let valueNames = routine.valueIds.compactMap { valueId in
                                        dataManager.getValue(by: valueId)?.name
                                    }
                                    Text("Values: " + valueNames.joined(separator: ", "))
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.leading, 12)
                        }
                    }
                }

                // Completed Tasks
                if !entry.completedTaskIds.isEmpty {
                    ForEach(entry.completedTaskIds, id: \.self) { taskId in
                        if let task = dataManager.tasks.first(where: { $0.id == taskId }) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(task.title)
                                    .font(.system(size: 14))
                                    .foregroundColor(.primary)
                                    .strikethrough(true, color: .secondary)

                                // Associated values
                                if !task.valueIds.isEmpty {
                                    let valueNames = task.valueIds.compactMap { valueId in
                                        dataManager.getValue(by: valueId)?.name
                                    }
                                    Text("Values: " + valueNames.joined(separator: ", "))
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.leading, 12)
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        } label: {
            HStack {
                Text(dayNumber)
                    .font(.system(size: 16))
                    .foregroundColor(.primary)

                VStack(alignment: .leading, spacing: 2) {
                    if !entry.completedRoutineIds.isEmpty {
                        Text("\(entry.completedRoutineIds.count) routine items")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    if !entry.completedTaskIds.isEmpty {
                        Text("\(entry.completedTaskIds.count) tasks completed")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                }

                Spacer()
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                showingDeleteConfirmation = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .alert("Delete Entry?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                dataManager.deleteHistoryEntry(entry)
            }
        } message: {
            Text("This will permanently delete this history entry. This cannot be undone.")
        }
    }
}

// MARK: - Settings View (Tab 5)
struct SettingsView: View {
    @EnvironmentObject var dataManager: DataManager
    @AppStorage("dailyCheckInEnabled") private var dailyCheckInEnabled = false
    @AppStorage("dailyCheckInHour") private var dailyCheckInHour = 20 // 8 PM default
    @AppStorage("dailyCheckInMinute") private var dailyCheckInMinute = 0
    @AppStorage("weekStartDay") private var weekStartDay = 1 // 1=Sunday, 2=Monday, ..., 7=Saturday

    @State private var showingClearHistoryAlert = false
    @State private var showingHelpGuide = false

    var checkInTime: Date {
        var components = DateComponents()
        components.hour = dailyCheckInHour
        components.minute = dailyCheckInMinute
        return Calendar.current.date(from: components) ?? Date()
    }

    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Custom header matching other pages
            HStack {
                Text(".settings")
                    .font(.custom("Georgia-Bold", size: 23))
                    .foregroundColor(.black)
                    .padding(.leading, 12)

                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 16)
            .padding(.bottom, 12)
            .background(Color(uiColor: .secondarySystemBackground))

            Form {
                // Notifications Section
                Section(header: Text("Notifications")) {
                    HStack {
                        Text("Daily Check-In")
                        Spacer()
                        Toggle("", isOn: $dailyCheckInEnabled)
                            .labelsHidden()
                            .tint(.black)
                            .onChange(of: dailyCheckInEnabled) { newValue in
                                if newValue {
                                    scheduleDailyCheckIn()
                                } else {
                                    cancelDailyCheckIn()
                                }
                            }
                    }

                    if dailyCheckInEnabled {
                        DatePicker("Time", selection: Binding(
                            get: { checkInTime },
                            set: { newDate in
                                let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                                dailyCheckInHour = components.hour ?? 20
                                dailyCheckInMinute = components.minute ?? 0
                                scheduleDailyCheckIn()
                            }
                        ), displayedComponents: .hourAndMinute)
                        .datePickerStyle(.compact)

                        Text("You'll be reminded to log your day's activities at this time")
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                    }
                }

                // Display Section
                Section(header: Text("Display")) {
                    Picker("Week Starts On", selection: $weekStartDay) {
                        Text("Sunday").tag(1)
                        Text("Monday").tag(2)
                        Text("Tuesday").tag(3)
                        Text("Wednesday").tag(4)
                        Text("Thursday").tag(5)
                        Text("Friday").tag(6)
                        Text("Saturday").tag(7)
                    }
                }

                // Data Section
                Section(header: Text("Data")) {
                    Button(action: {
                        showingClearHistoryAlert = true
                    }) {
                        Text("Clear History")
                            .foregroundColor(.red)
                    }
                }

                // Help Section
                Section(header: Text("Help")) {
                    Button(action: {
                        showingHelpGuide = true
                    }) {
                        HStack {
                            Text("User Guide")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "book.fill")
                                .foregroundColor(.black)
                        }
                    }
                }

                // About Section
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(appVersion)
                            .foregroundColor(.gray)
                    }
                }
            }
            .sheet(isPresented: $showingHelpGuide) {
                HelpGuideView()
            }
            .alert("Clear History", isPresented: $showingClearHistoryAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    dataManager.clearHistory()
                }
            } message: {
                Text("This will permanently delete all history entries. This action cannot be undone.")
            }
        }
    }

    private func scheduleDailyCheckIn() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["daily-checkin"])

        let content = UNMutableNotificationContent()
        content.title = "Daily Check-In"
        content.body = "How did your day go? Log your activities and see your progress."
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = dailyCheckInHour
        dateComponents.minute = dailyCheckInMinute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "daily-checkin", content: content, trigger: trigger)

        center.add(request) { error in
            if let error = error {
                #if DEBUG
                print("Error scheduling daily check-in: \(error)")
                #endif
            } else {
                #if DEBUG
                print("✓ Scheduled daily check-in at \(dailyCheckInHour):\(String(format: "%02d", dailyCheckInMinute))")
                #endif
            }
        }
    }

    private func cancelDailyCheckIn() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily-checkin"])
        #if DEBUG
        print("✗ Cancelled daily check-in notification")
        #endif
    }
}

// MARK: - Add Task View
struct AddTaskView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: DataManager

    @State private var title = ""
    @State private var dueDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date()) ?? Date()
    @State private var selectedValueIds: Set<UUID> = []
    @State private var isAppointment = false
    @State private var location = ""
    @State private var showLocationField = false
    @State private var isRecurring = false
    @State private var recurringFrequency: RecurringFrequency = .none
    @State private var reminders: [Reminder] = []
    @State private var showReminderPicker = false
    @State private var selectedReminderMinutes: Int? = nil
    @State private var customReminderDate = Date()

    var body: some View {
        NavigationView {
            Form {
                // Title field and appointment toggle
                Section {
                    TextField(isAppointment ? "Appointment details" : "What needs to be done?", text: $title)
                        .font(.system(size: 17))

                    HStack {
                        Text("Is this an appt.?")
                        Spacer()
                        Toggle("", isOn: $isAppointment)
                            .labelsHidden()
                            .tint(.black)
                    }
                }

                Section(header: Text(isAppointment ? "When is the appt?" : "When do you want this done by?")) {
                    // Date picker - collapsible dropdown with time
                    DatePicker("Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                }

                if isAppointment {
                    Section {
                        if showLocationField {
                            LocationSearchField(location: $location)
                        } else {
                            Button(action: {
                                showLocationField = true
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle")
                                        .foregroundColor(.primary)
                                    Text("Add a location")
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                    }
                }

                Section(header: Text("Important Values")) {
                    ForEach(dataManager.activeValues) { value in
                        Button(action: {
                            if selectedValueIds.contains(value.id) {
                                selectedValueIds.remove(value.id)
                            } else {
                                selectedValueIds.insert(value.id)
                            }
                        }) {
                            HStack {
                                Text(value.name)
                                    .foregroundColor(.primary)
                                Spacer()
                                if selectedValueIds.contains(value.id) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.primary)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                Section {
                    Toggle("Recurring", isOn: $isRecurring)
                        .tint(.black)

                    if isRecurring {
                        Picker("Frequency", selection: $recurringFrequency) {
                            ForEach(RecurringFrequency.allCases.filter { $0 != .none }, id: \.self) { freq in
                                Text(freq.rawValue).tag(freq)
                            }
                        }
                    }
                }

                // Reminders Section
                Section {
                    HStack {
                        Text("Reminders")
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { !reminders.isEmpty || showReminderPicker },
                            set: { newValue in
                                if newValue {
                                    showReminderPicker = true
                                } else {
                                    showReminderPicker = false
                                    reminders.removeAll()
                                }
                            }
                        ))
                        .labelsHidden()
                        .tint(.black)
                    }

                    if !reminders.isEmpty {
                        ForEach(reminders) { reminder in
                            HStack {
                                Image(systemName: "bell.fill")
                                    .foregroundColor(.primary)
                                    .font(.system(size: 14))
                                Text(reminderDisplayText(reminder))
                                    .font(.system(size: 15))
                                Spacer()
                            }
                        }
                        .onDelete { indexSet in
                            reminders.remove(atOffsets: indexSet)
                        }
                    }

                    if showReminderPicker {
                        if isAppointment {
                            // Appointment reminders (time-based)
                            Picker("When", selection: $selectedReminderMinutes) {
                                Text("At time of appointment").tag(0 as Int?)
                                Text("5 minutes before").tag(5 as Int?)
                                Text("15 minutes before").tag(15 as Int?)
                                Text("30 minutes before").tag(30 as Int?)
                                Text("1 hour before").tag(60 as Int?)
                                Text("1 day before at 9 AM").tag(1380 as Int?) // 23 hours before (assuming 9 AM appt)
                                Text("Custom").tag(-1 as Int?)
                            }
                            .pickerStyle(.menu)

                            if selectedReminderMinutes == -1 {
                                DatePicker("Custom time", selection: $customReminderDate, displayedComponents: [.date, .hourAndMinute])
                                    .datePickerStyle(.compact)
                            }
                        } else {
                            // Task reminders (day-based)
                            Picker("When", selection: $selectedReminderMinutes) {
                                Text("On day of task at 9 AM").tag(0 as Int?)
                                Text("1 day before at 9 AM").tag(1440 as Int?)
                                Text("2 days before at 9 AM").tag(2880 as Int?)
                                Text("1 week before at 9 AM").tag(10080 as Int?)
                                Text("Custom").tag(-1 as Int?)
                            }
                            .pickerStyle(.menu)

                            if selectedReminderMinutes == -1 {
                                DatePicker("Custom time", selection: $customReminderDate, displayedComponents: [.date, .hourAndMinute])
                                    .datePickerStyle(.compact)
                            }
                        }

                        HStack {
                            Button("Cancel") {
                                showReminderPicker = false
                                selectedReminderMinutes = nil
                                if reminders.isEmpty {
                                    // If no reminders exist, keep toggle off
                                }
                            }
                            .foregroundColor(.red)

                            Spacer()

                            Button("Add") {
                                addReminder()
                            }
                            .foregroundColor(.primary)
                            .disabled(selectedReminderMinutes == nil)
                        }

                        if !reminders.isEmpty {
                            Button(action: {
                                showReminderPicker = true
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle")
                                        .foregroundColor(.primary)
                                    Text("Add Another")
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.primary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addTask()
                        dismiss()
                    }
                    .foregroundColor(.primary)
                    .disabled(title.isEmpty)
                }
            }
        }
    }

    private func addTask() {
        let task = Task(
            title: title,
            dueDate: dueDate,
            valueIds: Array(selectedValueIds),
            isAppointment: isAppointment,
            location: location.isEmpty ? nil : location,
            isRecurring: isRecurring,
            recurringFrequency: isRecurring ? recurringFrequency : .none,
            reminders: reminders
        )
        dataManager.addTask(task)
    }

    private func addReminder() {
        if selectedReminderMinutes == -1 {
            // Custom reminder
            let reminder = Reminder(customDate: customReminderDate)
            reminders.append(reminder)
        } else if let minutes = selectedReminderMinutes {
            // Preset reminder
            let reminder = Reminder(minutesBefore: minutes)
            reminders.append(reminder)
        }
        showReminderPicker = false
        selectedReminderMinutes = nil
    }

    private func reminderDisplayText(_ reminder: Reminder) -> String {
        if let customDate = reminder.customDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return formatter.string(from: customDate)
        } else if let minutes = reminder.minutesBefore {
            if isAppointment {
                switch minutes {
                case 0: return "At time of appointment"
                case 5: return "5 minutes before"
                case 15: return "15 minutes before"
                case 30: return "30 minutes before"
                case 60: return "1 hour before"
                case 1380: return "1 day before at 9 AM"
                default: return "\(minutes) minutes before"
                }
            } else {
                switch minutes {
                case 0: return "On day of task at 9 AM"
                case 1440: return "1 day before at 9 AM"
                case 2880: return "2 days before at 9 AM"
                case 10080: return "1 week before at 9 AM"
                default: return "\(minutes / 1440) days before at 9 AM"
                }
            }
        }
        return "Unknown"
    }
}

// MARK: - Edit Task View
struct EditTaskView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: DataManager
    let task: Task

    @State private var title: String
    @State private var dueDate: Date
    @State private var selectedValueIds: Set<UUID>
    @State private var isAppointment: Bool
    @State private var location: String
    @State private var showLocationField: Bool
    @State private var isRecurring: Bool
    @State private var recurringFrequency: RecurringFrequency
    @State private var reminders: [Reminder]
    @State private var showReminderPicker = false
    @State private var selectedReminderMinutes: Int? = nil
    @State private var customReminderDate = Date()

    init(task: Task) {
        self.task = task
        _title = State(initialValue: task.title)
        _selectedValueIds = State(initialValue: Set(task.valueIds))
        _isAppointment = State(initialValue: task.isAppointment)
        _location = State(initialValue: task.location ?? "")
        _showLocationField = State(initialValue: task.location != nil)
        _isRecurring = State(initialValue: task.isRecurring)
        _recurringFrequency = State(initialValue: task.recurringFrequency)
        _dueDate = State(initialValue: task.dueDate ?? Date())
        _reminders = State(initialValue: task.reminders)
    }

    var body: some View {
        NavigationView {
            Form {
                // Title field and appointment toggle
                Section {
                    TextField(isAppointment ? "Appointment details" : "What needs to be done?", text: $title)
                        .font(.system(size: 17))

                    HStack {
                        Text("Is this an appt.?")
                        Spacer()
                        Toggle("", isOn: $isAppointment)
                            .labelsHidden()
                            .tint(.black)
                    }
                }

                Section(header: Text(isAppointment ? "When is the appt?" : "When do you want this done by?")) {
                    // Date picker - collapsible dropdown with time
                    DatePicker("Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                }

                if isAppointment {
                    Section {
                        if showLocationField {
                            LocationSearchField(location: $location)
                        } else {
                            Button(action: {
                                showLocationField = true
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle")
                                        .foregroundColor(.primary)
                                    Text("Add a location")
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                    }
                }

                Section(header: Text("Important Values")) {
                    ForEach(dataManager.activeValues) { value in
                        Button(action: {
                            if selectedValueIds.contains(value.id) {
                                selectedValueIds.remove(value.id)
                            } else {
                                selectedValueIds.insert(value.id)
                            }
                        }) {
                            HStack {
                                Text(value.name)
                                    .foregroundColor(.primary)
                                Spacer()
                                if selectedValueIds.contains(value.id) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.primary)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                Section {
                    Toggle("Recurring", isOn: $isRecurring)
                        .tint(.black)

                    if isRecurring {
                        Picker("Frequency", selection: $recurringFrequency) {
                            ForEach(RecurringFrequency.allCases.filter { $0 != .none }, id: \.self) { freq in
                                Text(freq.rawValue).tag(freq)
                            }
                        }
                    }
                }

                // Reminders Section
                Section {
                    HStack {
                        Text("Reminders")
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { !reminders.isEmpty || showReminderPicker },
                            set: { newValue in
                                if newValue {
                                    showReminderPicker = true
                                } else {
                                    showReminderPicker = false
                                    reminders.removeAll()
                                }
                            }
                        ))
                        .labelsHidden()
                        .tint(.black)
                    }

                    if !reminders.isEmpty {
                        ForEach(reminders) { reminder in
                            HStack {
                                Image(systemName: "bell.fill")
                                    .foregroundColor(.primary)
                                    .font(.system(size: 14))
                                Text(reminderDisplayText(reminder))
                                    .font(.system(size: 15))
                                Spacer()
                            }
                        }
                        .onDelete { indexSet in
                            reminders.remove(atOffsets: indexSet)
                        }
                    }

                    if showReminderPicker {
                        if isAppointment {
                            // Appointment reminders (time-based)
                            Picker("When", selection: $selectedReminderMinutes) {
                                Text("At time of appointment").tag(0 as Int?)
                                Text("5 minutes before").tag(5 as Int?)
                                Text("15 minutes before").tag(15 as Int?)
                                Text("30 minutes before").tag(30 as Int?)
                                Text("1 hour before").tag(60 as Int?)
                                Text("1 day before at 9 AM").tag(1380 as Int?)
                                Text("Custom").tag(-1 as Int?)
                            }
                            .pickerStyle(.menu)

                            if selectedReminderMinutes == -1 {
                                DatePicker("Custom time", selection: $customReminderDate, displayedComponents: [.date, .hourAndMinute])
                                    .datePickerStyle(.compact)
                            }
                        } else {
                            // Task reminders (day-based)
                            Picker("When", selection: $selectedReminderMinutes) {
                                Text("On day of task at 9 AM").tag(0 as Int?)
                                Text("1 day before at 9 AM").tag(1440 as Int?)
                                Text("2 days before at 9 AM").tag(2880 as Int?)
                                Text("1 week before at 9 AM").tag(10080 as Int?)
                                Text("Custom").tag(-1 as Int?)
                            }
                            .pickerStyle(.menu)

                            if selectedReminderMinutes == -1 {
                                DatePicker("Custom time", selection: $customReminderDate, displayedComponents: [.date, .hourAndMinute])
                                    .datePickerStyle(.compact)
                            }
                        }

                        HStack {
                            Button("Cancel") {
                                showReminderPicker = false
                                selectedReminderMinutes = nil
                                if reminders.isEmpty {
                                    // If no reminders exist, keep toggle off
                                }
                            }
                            .foregroundColor(.red)

                            Spacer()

                            Button("Add") {
                                addReminder()
                            }
                            .foregroundColor(.primary)
                            .disabled(selectedReminderMinutes == nil)
                        }

                        if !reminders.isEmpty {
                            Button(action: {
                                showReminderPicker = true
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle")
                                        .foregroundColor(.primary)
                                    Text("Add Another")
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                    }
                }

                // Delete button at very bottom
                Section {
                    Button(role: .destructive, action: {
                        dataManager.deleteTask(task)
                        dismiss()
                    }) {
                        HStack {
                            Spacer()
                            Text("Delete Task")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.primary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        updateTask()
                        dismiss()
                    }
                    .foregroundColor(.primary)
                    .disabled(title.isEmpty)
                }
            }
        }
    }

    private func updateTask() {
        var updatedTask = task  // Start with original task to preserve all properties

        // Update only the fields that changed
        updatedTask.title = title
        updatedTask.dueDate = dueDate
        updatedTask.valueIds = Array(selectedValueIds)
        updatedTask.isAppointment = isAppointment
        updatedTask.location = location.isEmpty ? nil : location
        updatedTask.isRecurring = isRecurring
        updatedTask.recurringFrequency = isRecurring ? recurringFrequency : .none
        updatedTask.reminders = reminders

        dataManager.updateTask(updatedTask)
    }

    private func addReminder() {
        if selectedReminderMinutes == -1 {
            // Custom reminder
            let reminder = Reminder(customDate: customReminderDate)
            reminders.append(reminder)
        } else if let minutes = selectedReminderMinutes {
            // Preset reminder
            let reminder = Reminder(minutesBefore: minutes)
            reminders.append(reminder)
        }
        showReminderPicker = false
        selectedReminderMinutes = nil
    }

    private func reminderDisplayText(_ reminder: Reminder) -> String {
        if let customDate = reminder.customDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return formatter.string(from: customDate)
        } else if let minutes = reminder.minutesBefore {
            if isAppointment {
                switch minutes {
                case 0: return "At time of appointment"
                case 5: return "5 minutes before"
                case 15: return "15 minutes before"
                case 30: return "30 minutes before"
                case 60: return "1 hour before"
                case 1380: return "1 day before at 9 AM"
                default: return "\(minutes) minutes before"
                }
            } else {
                switch minutes {
                case 0: return "On day of task at 9 AM"
                case 1440: return "1 day before at 9 AM"
                case 2880: return "2 days before at 9 AM"
                case 10080: return "1 week before at 9 AM"
                default: return "\(minutes / 1440) days before at 9 AM"
                }
            }
        }
        return "Unknown"
    }
}

// MARK: - Add Routine Item View
struct AddRoutineItemView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: DataManager

    @State private var title = ""
    @State private var startTime = Date()
    @State private var durationHours: Int = 1
    @State private var durationMinutes: Int = 0
    @State private var showingStartTimePicker = false
    @State private var showingDurationPicker = false
    @State private var selectedIcon = ""
    @State private var selectedValueIds: Set<UUID> = []
    @State private var notificationEnabled = false
    @State private var selectedDays: Set<Int> = [0, 1, 2, 3, 4, 5, 6] // Default: all days selected

    let commonIcons = [
        // Blank option
        "",

        // Health & Wellness (11)
        "heart.fill", "bed.double.fill", "dumbbell.fill", "figure.walk", "figure.run",
        "figure.yoga", "pill.fill", "drop.fill", "leaf.fill", "sparkles",
        "cross.fill",

        // Food & Drink (8)
        "cup.and.saucer.fill", "fork.knife", "waterbottle.fill", "takeoutbag.and.cup.and.straw.fill",
        "carrot.fill", "fish.fill", "birthday.cake.fill", "wineglass.fill",

        // Activities & Hobbies (10)
        "book.fill", "pencil", "paintbrush.fill", "music.note", "gamecontroller.fill",
        "camera.fill", "photo.fill", "tv.fill", "guitars.fill", "sportscourt.fill",

        // Time & Productivity (10)
        "clock.fill", "alarm.fill", "calendar", "checkmark.circle.fill", "list.bullet",
        "checklist", "square.and.pencil", "folder.fill", "doc.fill", "chart.bar.fill",

        // People & Communication (6)
        "person.fill", "person.2.fill", "phone.fill", "envelope.fill", "message.fill",
        "bubble.left.fill",

        // Home & Living (7)
        "house.fill", "lamp.desk.fill", "sofa.fill", "shower.fill", "toilet.fill",
        "washer.fill", "trash.fill",

        // Nature & Weather (7)
        "sun.max.fill", "moon.fill", "moon.stars.fill", "cloud.fill", "cloud.rain.fill",
        "flame.fill", "tree.fill",

        // Transportation (6)
        "car.fill", "bicycle", "bus.fill", "airplane", "train.side.front.car",
        "shoeprints.fill",

        // Technology (5)
        "laptopcomputer", "iphone", "headphones", "wifi",
        "applewatch",

        // Symbols (1)
        "star.fill"
    ]

    var startTimeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: startTime)
    }

    var durationString: String {
        if durationHours == 0 && durationMinutes == 0 {
            return "Not set"
        }
        var parts: [String] = []
        if durationHours > 0 {
            parts.append("\(durationHours) hr")
        }
        if durationMinutes > 0 {
            parts.append("\(durationMinutes) min")
        }
        return parts.joined(separator: " ")
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Routine item", text: $title)
                        .font(.system(size: 17))
                }

                Section(header: Text("Time")) {
                    Button(action: {
                        withAnimation {
                            showingStartTimePicker.toggle()
                        }
                    }) {
                        HStack {
                            Text("Start Time")
                                .foregroundColor(.primary)
                            Spacer()
                            Text(startTimeString)
                                .foregroundColor(.secondary)
                            Image(systemName: showingStartTimePicker ? "chevron.up" : "chevron.down")
                                .foregroundColor(.gray)
                                .font(.system(size: 14))
                        }
                    }
                    .buttonStyle(.plain)

                    if showingStartTimePicker {
                        DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .frame(height: 120)
                    }

                    Button(action: {
                        withAnimation {
                            showingDurationPicker.toggle()
                        }
                    }) {
                        HStack {
                            Text("How long?")
                                .foregroundColor(.primary)
                            Spacer()
                            Text(durationString)
                                .foregroundColor(.secondary)
                            Image(systemName: showingDurationPicker ? "chevron.up" : "chevron.down")
                                .foregroundColor(.gray)
                                .font(.system(size: 14))
                        }
                    }
                    .buttonStyle(.plain)

                    if showingDurationPicker {
                        HStack(spacing: 0) {
                            Picker("", selection: $durationHours) {
                                ForEach(0..<24) { hour in
                                    Text("\(hour)").tag(hour)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 80, height: 120)
                            .clipped()

                            Text("hr")
                                .foregroundColor(.primary)
                                .padding(.horizontal, 8)

                            Picker("", selection: $durationMinutes) {
                                ForEach([0, 15, 30, 45], id: \.self) { minute in
                                    Text("\(minute)").tag(minute)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 80, height: 120)
                            .clipped()

                            Text("min")
                                .foregroundColor(.primary)
                                .padding(.horizontal, 8)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }

                Section(header: Text("Active Days")) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 6) {
                        ForEach(0..<7) { day in
                            let dayName = ["S", "M", "T", "W", "T", "F", "S"][day]
                            Button(action: {
                                if selectedDays.contains(day) {
                                    selectedDays.remove(day)
                                } else {
                                    selectedDays.insert(day)
                                }
                            }) {
                                Text(dayName)
                                    .font(.system(size: 16))
                                    .foregroundColor(selectedDays.contains(day) ? .white : .black)
                                    .frame(width: 40, height: 40)
                                    .background(selectedDays.contains(day) ? Color.black : Color.gray.opacity(0.2))
                                    .cornerRadius(20)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section {
                    Toggle("Enable Notifications", isOn: $notificationEnabled)
                        .tint(.black)
                        .onChange(of: notificationEnabled) { newValue in
                            if newValue {
                                // Request notification permission when user enables notifications
                                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                                    if !granted {
                                        // If permission denied, turn toggle back off
                                        DispatchQueue.main.async {
                                            notificationEnabled = false
                                        }
                                    }
                                }
                            }
                        }
                }

                Section {
                    DisclosureGroup {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 16) {
                            ForEach(commonIcons, id: \.self) { icon in
                                Button(action: {
                                    selectedIcon = icon
                                }) {
                                    Group {
                                        if icon.isEmpty {
                                            // Show blank square for "no icon" option
                                            Rectangle()
                                                .fill(Color.clear)
                                        } else {
                                            Image(systemName: icon)
                                                .font(.system(size: 24))
                                                .foregroundColor(selectedIcon == icon ? .white : .black)
                                        }
                                    }
                                    .frame(width: 50, height: 50)
                                    .background(selectedIcon == icon ? Color.black : Color.gray.opacity(0.2))
                                    .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 8)
                    } label: {
                        HStack {
                            Text("Icon")
                            Spacer()
                            Image(systemName: selectedIcon)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section {
                    DisclosureGroup("Important Values") {
                        ForEach(dataManager.activeValues.sorted { $0.name < $1.name }) { value in
                            Button(action: {
                                if selectedValueIds.contains(value.id) {
                                    selectedValueIds.remove(value.id)
                                } else {
                                    selectedValueIds.insert(value.id)
                                }
                            }) {
                                HStack {
                                    Text(value.name)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    if selectedValueIds.contains(value.id) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.primary)
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle("New Routine Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.primary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addRoutineItem()
                        dismiss()
                    }
                    .foregroundColor(.primary)
                    .disabled(title.isEmpty || selectedDays.isEmpty)
                }
            }
        }
    }

    private func addRoutineItem() {
        let calendar = Calendar.current

        // Calculate endTime from startTime + duration
        let totalMinutes = (durationHours * 60) + durationMinutes
        guard let endTime = calendar.date(byAdding: .minute, value: totalMinutes, to: startTime) else { return }

        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"

        let startTimeString = formatter.string(from: startTime)
        let endTimeString = formatter.string(from: endTime)
        let timeString = "\(startTimeString) - \(endTimeString)"

        let notifHour = notificationEnabled ? calendar.component(.hour, from: startTime) : nil
        let notifMinute = notificationEnabled ? calendar.component(.minute, from: startTime) : nil

        let item = RoutineItem(
            title: title,
            time: timeString,
            icon: selectedIcon,
            valueIds: Array(selectedValueIds),
            notificationEnabled: notificationEnabled,
            notificationHour: notifHour,
            notificationMinute: notifMinute,
            startTime: startTime,
            endTime: endTime,
            activeDays: selectedDays.isEmpty ? nil : Array(selectedDays).sorted()
        )
        dataManager.addRoutineItem(item)
    }
}

// MARK: - Edit Routine Item View
struct EditRoutineItemView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: DataManager
    let item: RoutineItem

    @State private var title: String
    @State private var startTime: Date
    @State private var durationHours: Int
    @State private var durationMinutes: Int
    @State private var showingStartTimePicker = false
    @State private var showingDurationPicker = false
    @State private var selectedIcon: String
    @State private var selectedValueIds: Set<UUID>
    @State private var notificationEnabled: Bool
    @State private var selectedDays: Set<Int>

    let commonIcons = [
        // Blank option
        "",

        // Health & Wellness (11)
        "heart.fill", "bed.double.fill", "dumbbell.fill", "figure.walk", "figure.run",
        "figure.yoga", "pill.fill", "drop.fill", "leaf.fill", "sparkles",
        "cross.fill",

        // Food & Drink (8)
        "cup.and.saucer.fill", "fork.knife", "waterbottle.fill", "takeoutbag.and.cup.and.straw.fill",
        "carrot.fill", "fish.fill", "birthday.cake.fill", "wineglass.fill",

        // Activities & Hobbies (10)
        "book.fill", "pencil", "paintbrush.fill", "music.note", "gamecontroller.fill",
        "camera.fill", "photo.fill", "tv.fill", "guitars.fill", "sportscourt.fill",

        // Time & Productivity (10)
        "clock.fill", "alarm.fill", "calendar", "checkmark.circle.fill", "list.bullet",
        "checklist", "square.and.pencil", "folder.fill", "doc.fill", "chart.bar.fill",

        // People & Communication (6)
        "person.fill", "person.2.fill", "phone.fill", "envelope.fill", "message.fill",
        "bubble.left.fill",

        // Home & Living (7)
        "house.fill", "lamp.desk.fill", "sofa.fill", "shower.fill", "toilet.fill",
        "washer.fill", "trash.fill",

        // Nature & Weather (7)
        "sun.max.fill", "moon.fill", "moon.stars.fill", "cloud.fill", "cloud.rain.fill",
        "flame.fill", "tree.fill",

        // Transportation (6)
        "car.fill", "bicycle", "bus.fill", "airplane", "train.side.front.car",
        "shoeprints.fill",

        // Technology (5)
        "laptopcomputer", "iphone", "headphones", "wifi",
        "applewatch",

        // Symbols (1)
        "star.fill"
    ]

    init(item: RoutineItem) {
        self.item = item
        _title = State(initialValue: item.title)
        _selectedIcon = State(initialValue: item.icon)
        _selectedValueIds = State(initialValue: Set(item.valueIds))
        _notificationEnabled = State(initialValue: item.notificationEnabled)
        _startTime = State(initialValue: item.startTime ?? Date())
        _selectedDays = State(initialValue: Set(item.activeDays ?? []))

        // Calculate duration from existing start/end times
        if let start = item.startTime, let end = item.endTime {
            let duration = Calendar.current.dateComponents([.hour, .minute], from: start, to: end)
            _durationHours = State(initialValue: duration.hour ?? 1)
            _durationMinutes = State(initialValue: duration.minute ?? 0)
        } else {
            _durationHours = State(initialValue: 1)
            _durationMinutes = State(initialValue: 0)
        }
    }

    var startTimeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: startTime)
    }

    var durationString: String {
        if durationHours == 0 && durationMinutes == 0 {
            return "Not set"
        }
        var parts: [String] = []
        if durationHours > 0 {
            parts.append("\(durationHours) hr")
        }
        if durationMinutes > 0 {
            parts.append("\(durationMinutes) min")
        }
        return parts.joined(separator: " ")
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Routine item", text: $title)
                        .font(.system(size: 17))
                }

                Section(header: Text("Time")) {
                    Button(action: {
                        withAnimation {
                            showingStartTimePicker.toggle()
                        }
                    }) {
                        HStack {
                            Text("Start Time")
                                .foregroundColor(.primary)
                            Spacer()
                            Text(startTimeString)
                                .foregroundColor(.secondary)
                            Image(systemName: showingStartTimePicker ? "chevron.up" : "chevron.down")
                                .foregroundColor(.gray)
                                .font(.system(size: 14))
                        }
                    }
                    .buttonStyle(.plain)

                    if showingStartTimePicker {
                        DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .frame(height: 120)
                    }

                    Button(action: {
                        withAnimation {
                            showingDurationPicker.toggle()
                        }
                    }) {
                        HStack {
                            Text("How long?")
                                .foregroundColor(.primary)
                            Spacer()
                            Text(durationString)
                                .foregroundColor(.secondary)
                            Image(systemName: showingDurationPicker ? "chevron.up" : "chevron.down")
                                .foregroundColor(.gray)
                                .font(.system(size: 14))
                        }
                    }
                    .buttonStyle(.plain)

                    if showingDurationPicker {
                        HStack(spacing: 0) {
                            Picker("", selection: $durationHours) {
                                ForEach(0..<24) { hour in
                                    Text("\(hour)").tag(hour)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 80, height: 120)
                            .clipped()

                            Text("hr")
                                .foregroundColor(.primary)
                                .padding(.horizontal, 8)

                            Picker("", selection: $durationMinutes) {
                                ForEach([0, 15, 30, 45], id: \.self) { minute in
                                    Text("\(minute)").tag(minute)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 80, height: 120)
                            .clipped()

                            Text("min")
                                .foregroundColor(.primary)
                                .padding(.horizontal, 8)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }

                Section(header: Text("Active Days")) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 6) {
                        ForEach(0..<7) { day in
                            let dayName = ["S", "M", "T", "W", "T", "F", "S"][day]
                            Button(action: {
                                if selectedDays.contains(day) {
                                    selectedDays.remove(day)
                                } else {
                                    selectedDays.insert(day)
                                }
                            }) {
                                Text(dayName)
                                    .font(.system(size: 16))
                                    .foregroundColor(selectedDays.contains(day) ? .white : .black)
                                    .frame(width: 40, height: 40)
                                    .background(selectedDays.contains(day) ? Color.black : Color.gray.opacity(0.2))
                                    .cornerRadius(20)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section {
                    Toggle("Enable Notifications", isOn: $notificationEnabled)
                        .tint(.black)
                        .onChange(of: notificationEnabled) { newValue in
                            if newValue {
                                // Request notification permission when user enables notifications
                                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                                    if !granted {
                                        // If permission denied, turn toggle back off
                                        DispatchQueue.main.async {
                                            notificationEnabled = false
                                        }
                                    }
                                }
                            }
                        }
                }

                Section {
                    DisclosureGroup {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 16) {
                            ForEach(commonIcons, id: \.self) { icon in
                                Button(action: {
                                    selectedIcon = icon
                                }) {
                                    Group {
                                        if icon.isEmpty {
                                            // Show blank square for "no icon" option
                                            Rectangle()
                                                .fill(Color.clear)
                                        } else {
                                            Image(systemName: icon)
                                                .font(.system(size: 24))
                                                .foregroundColor(selectedIcon == icon ? .white : .black)
                                        }
                                    }
                                    .frame(width: 50, height: 50)
                                    .background(selectedIcon == icon ? Color.black : Color.gray.opacity(0.2))
                                    .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 8)
                    } label: {
                        HStack {
                            Text("Icon")
                            Spacer()
                            Image(systemName: selectedIcon)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section {
                    DisclosureGroup("Important Values") {
                        ForEach(dataManager.activeValues.sorted { $0.name < $1.name }) { value in
                            Button(action: {
                                if selectedValueIds.contains(value.id) {
                                    selectedValueIds.remove(value.id)
                                } else {
                                    selectedValueIds.insert(value.id)
                                }
                            }) {
                                HStack {
                                    Text(value.name)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    if selectedValueIds.contains(value.id) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.primary)
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Delete button at very bottom
                Section {
                    Button(role: .destructive, action: {
                        dataManager.deleteRoutineItem(item)
                        dismiss()
                    }) {
                        HStack {
                            Spacer()
                            Text("Delete Routine Item")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Edit Routine Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.primary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        updateRoutineItem()
                        dismiss()
                    }
                    .foregroundColor(.primary)
                    .disabled(title.isEmpty || selectedDays.isEmpty)
                }
            }
        }
    }

    private func updateRoutineItem() {
        let calendar = Calendar.current

        // Calculate endTime from startTime + duration
        let totalMinutes = (durationHours * 60) + durationMinutes
        guard let endTime = calendar.date(byAdding: .minute, value: totalMinutes, to: startTime) else { return }

        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"

        let startTimeString = formatter.string(from: startTime)
        let endTimeString = formatter.string(from: endTime)
        let timeString = "\(startTimeString) - \(endTimeString)"

        let notifHour = notificationEnabled ? calendar.component(.hour, from: startTime) : nil
        let notifMinute = notificationEnabled ? calendar.component(.minute, from: startTime) : nil

        let updatedItem = RoutineItem(
            id: item.id,
            title: title,
            time: timeString,
            icon: selectedIcon,
            valueIds: Array(selectedValueIds),
            notificationEnabled: notificationEnabled,
            notificationHour: notifHour,
            notificationMinute: notifMinute,
            startTime: startTime,
            endTime: endTime,
            activeDays: selectedDays.isEmpty ? nil : Array(selectedDays).sorted()
        )
        dataManager.updateRoutineItem(updatedItem)
    }
}

// MARK: - Search Values View
struct SearchValuesView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: DataManager
    @Binding var searchText: String
    @FocusState private var isSearchFocused: Bool

    var filteredValues: [Value] {
        if searchText.isEmpty {
            return dataManager.values.sorted { $0.name < $1.name }
        } else {
            return dataManager.values.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }.sorted { $0.name < $1.name }
        }
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(filteredValues) { value in
                    ValueRow(value: value, isActive: value.isActive)
                }
            }
            .navigationTitle("Search Values")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.primary)
                }
            }
        }
        .onAppear {
            isSearchFocused = true
        }
    }
}

// MARK: - Add Custom Value View
struct AddCustomValueView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: DataManager

    @State private var name = ""
    @State private var definition = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Value Name")) {
                    TextField("e.g., Mindfulness", text: $name)
                        .font(.system(size: 17))
                }

                Section(header: Text("Definition")) {
                    TextEditor(text: $definition)
                        .frame(minHeight: 100)
                        .font(.system(size: 15))
                }
            }
            .navigationTitle("New Custom Value")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.primary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        dataManager.addCustomValue(name: name, definition: definition)
                        dismiss()
                    }
                    .foregroundColor(.primary)
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

// MARK: - Location Search Field with Autocomplete
class LocationSearchCompleter: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var searchQuery = ""
    @Published var searchResults: [MKLocalSearchCompletion] = []

    private var completer: MKLocalSearchCompleter

    override init() {
        completer = MKLocalSearchCompleter()
        super.init()
        completer.delegate = self
        completer.resultTypes = .address
    }

    func updateSearch(_ query: String) {
        searchQuery = query
        if query.isEmpty {
            searchResults = []
        } else {
            completer.queryFragment = query
        }
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        searchResults = completer.results
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        #if DEBUG
        print("Location search error: \(error.localizedDescription)")
        #endif
    }
}

struct LocationSearchField: View {
    @Binding var location: String
    @StateObject private var searchCompleter = LocationSearchCompleter()
    @State private var showSuggestions = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "location.fill")
                    .foregroundColor(.gray)
                TextField("Location", text: $searchCompleter.searchQuery)
                    .font(.system(size: 17))
                    .onChange(of: searchCompleter.searchQuery) { newValue in
                        searchCompleter.updateSearch(newValue)
                        showSuggestions = !newValue.isEmpty
                        location = newValue
                    }
                    .onTapGesture {
                        if !searchCompleter.searchQuery.isEmpty {
                            showSuggestions = true
                        }
                    }
            }

            if showSuggestions && !searchCompleter.searchResults.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(searchCompleter.searchResults, id: \.self) { result in
                        Button(action: {
                            let fullAddress = "\(result.title), \(result.subtitle)"
                            searchCompleter.searchQuery = fullAddress
                            location = fullAddress
                            showSuggestions = false
                        }) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(result.title)
                                    .font(.system(size: 15))
                                    .foregroundColor(.primary)
                                if !result.subtitle.isEmpty {
                                    Text(result.subtitle)
                                        .font(.system(size: 13))
                                        .foregroundColor(.gray)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                        }
                        .buttonStyle(.plain)

                        if result != searchCompleter.searchResults.last {
                            Divider()
                        }
                    }
                }
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                .padding(.top, 8)
            }
        }
        .onAppear {
            searchCompleter.searchQuery = location
        }
    }
}

// MARK: - Share Sheet Helper
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
