import SwiftUI
import SmartPlanCore

struct InsightsView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        NavigationStack {
            List {
                metric("Flow Score", "\(store.insights.flowScore)")
                metric("Streak", "\(store.insights.streak) days")
                metric("Focus Ratio", "\(store.insights.focusRatio)%")
                metric("Completed Today", "\(store.insights.completedToday)")
                metric("Completed This Week", "\(store.insights.completedWeek)")
                metric("Time Saved", "\(store.insights.timeSavedHours.formatted(.number.precision(.fractionLength(1))))h (\(store.insights.timeSavedTaskCount) tasks)")
            }
            .navigationTitle("Insights")
        }
    }

    private func metric(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}
