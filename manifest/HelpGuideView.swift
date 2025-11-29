import SwiftUI

struct HelpGuideView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedSection: HelpSection? = nil

    var body: some View {
        NavigationView {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 8) {
                        Image("stones")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 50)
                            .padding(.top, 20)

                        Text(".manifest")
                            .font(.custom("Georgia-Bold", size: 28))
                            .foregroundColor(.black)

                        Text("User Guide")
                            .font(.custom("Georgia", size: 18))
                            .foregroundColor(.secondary)
                            .padding(.bottom, 12)
                    }

                    // Table of Contents
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(HelpSection.allCases) { section in
                                HelpSectionCard(section: section, selectedSection: $selectedSection)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 17))
                }
            }
        }
        .sheet(item: $selectedSection) { section in
            HelpSectionDetailView(section: section)
        }
    }
}

struct HelpSectionCard: View {
    let section: HelpSection
    @Binding var selectedSection: HelpSection?

    var body: some View {
        Button(action: {
            selectedSection = section
        }) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: section.icon)
                    .font(.system(size: 28))
                    .foregroundColor(.black)
                    .frame(width: 44, height: 44)

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(section.title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)

                    Text(section.subtitle)
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(Color(uiColor: .systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }
}

struct HelpSectionDetailView: View {
    @Environment(\.dismiss) var dismiss
    let section: HelpSection

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        Image(systemName: section.icon)
                            .font(.system(size: 44))
                            .foregroundColor(.black)

                        Text(section.title)
                            .font(.custom("Georgia-Bold", size: 28))
                            .foregroundColor(.black)

                        Text(section.subtitle)
                            .font(.system(size: 17))
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 8)

                    // Content
                    VStack(alignment: .leading, spacing: 20) {
                        ForEach(section.content, id: \.self) { item in
                            HelpContentItem(text: item)
                        }
                    }
                }
                .padding(24)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct HelpContentItem: View {
    let text: String

    var body: some View {
        if text.hasPrefix("**") && text.hasSuffix("**") {
            // Header
            Text(text.replacingOccurrences(of: "**", with: ""))
                .font(.system(size: 19, weight: .semibold))
                .foregroundColor(.primary)
                .padding(.top, 4)
        } else if text.hasPrefix("• ") {
            // Bullet point
            HStack(alignment: .top, spacing: 8) {
                Text("•")
                    .font(.system(size: 17))
                    .foregroundColor(.secondary)

                Text(text.replacingOccurrences(of: "• ", with: ""))
                    .font(.system(size: 17))
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } else {
            // Regular paragraph
            Text(text)
                .font(.system(size: 17))
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

enum HelpSection: String, CaseIterable, Identifiable {
    case smartList = "Smart Task List"
    case routine = "My Routine"
    case values = "My Values"
    case analysis = "Analysis"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .smartList: return "checklist"
        case .routine: return "sun.haze.fill"
        case .values: return "v.circle"
        case .analysis: return "chart.bar.xaxis"
        }
    }

    var title: String {
        switch self {
        case .smartList: return ".to do list"
        case .routine: return ".my routine"
        case .values: return ".my values"
        case .analysis: return ".analysis"
        }
    }

    var subtitle: String {
        switch self {
        case .smartList: return "Understand the color-coded smart task system"
        case .routine: return "Create and manage your daily schedule"
        case .values: return "Define what matters most to you"
        case .analysis: return "Track which values you serve"
        }
    }

    var content: [String] {
        switch self {
        case .smartList:
            return [
                "**What is the Smart Task List?**",
                "The .to do list uses an intelligent color-coding system to help you prioritize tasks based on urgency and importance.",
                "",
                "**Color System**",
                "• Red: Due today or overdue — highest priority",
                "• Orange: Due tomorrow — plan ahead",
                "• Yellow: Due within a week — keep on radar",
                "• Green: Due later or no due date — no rush",
                "",
                "**Task Types**",
                "• Tasks: General to-dos with optional due dates",
                "• Appointments: Time-specific events with exact times",
                "",
                "**Smart Features**",
                "• Tap a task to mark it complete",
                "• Swipe left to edit or delete",
                "• Tasks automatically update color as dates approach",
                "• Completed tasks move to your .analysis view",
                "",
                "**Adding Tasks**",
                "• Tap the + button to create a new task",
                "• Set a due date for automatic color coding",
                "• Toggle 'Appointment' for time-specific events",
                "• Assign values to track what matters",
                "• Add location for address suggestions"
            ]

        case .routine:
            return [
                "**What is My Routine?**",
                ".my routine helps you design your ideal daily schedule with time blocks that reflect your priorities.",
                "",
                "**Creating Routine Items**",
                "• Tap + to add a new routine item",
                "• Set the time you want to perform this activity",
                "• Assign values that this activity serves",
                "• Enable notifications for gentle reminders",
                "",
                "**Sunrise & Sunset Colors**",
                "If you've enabled location access, the background gradient changes throughout the day to match the natural light at your location—from sunrise to sunset.",
                "",
                "**Notifications**",
                "• Enable 'Remind me' for any routine item",
                "• Receive notifications at your scheduled times",
                "• Manage notification permissions in Settings",
                "",
                "**Tips**",
                "• Start with 3-5 key activities",
                "• Be realistic about timing",
                "• Assign values to see patterns in .analysis"
            ]

        case .values:
            return [
                "**What are Values?**",
                "Values are the core principles that guide your decisions and actions. .my values helps you define, activate, and align your daily tasks with what matters most.",
                "",
                "**Activating Values**",
                "• Browse the complete library of values",
                "• Tap to view detailed descriptions",
                "• Activate 3-5 that resonate most with you",
                "• Active values appear throughout the app",
                "",
                "**Using Values**",
                "• Assign values to tasks and routine items",
                "• See which values you're serving in .analysis",
                "• Deactivate values that no longer serve you",
                "",
                "**Value Categories**",
                "The library includes values across:",
                "• Personal growth",
                "• Relationships",
                "• Health & wellbeing",
                "• Work & achievement",
                "• Creativity & expression",
                "",
                "**Why Limit Active Values?**",
                "Focusing on 3-5 core values helps you make clearer decisions and avoid overwhelm. You can change them anytime."
            ]

        case .analysis:
            return [
                "**What is Analysis?**",
                ".analysis shows which values you're actively serving through your completed tasks and routines, helping you see if you're living in alignment with what matters most.",
                "",
                "**Understanding the Chart**",
                "• Each bar represents one of your active values",
                "• Bar height shows how many tasks served that value",
                "• Only completed tasks are counted",
                "• Data updates as you complete tasks",
                "",
                "**Time Filters**",
                "• This week: Focus on recent activity",
                "• This month: See monthly patterns",
                "• This year: Track long-term trends",
                "• All time: View your complete history",
                "",
                "**Completed Tasks History**",
                "• View all tasks you've completed",
                "• Organized by month",
                "• See which values each task served",
                "",
                "**Using Insights**",
                "• Notice which values you naturally serve",
                "• Identify values that need more attention",
                "• Adjust your routine to align with priorities",
                "• Deactivate values you're not actually serving"
            ]
        }
    }
}
