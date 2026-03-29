import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "sun.max") }

            TasksView()
                .tabItem { Label("Tasks", systemImage: "checklist") }

            ProjectsView()
                .tabItem { Label("Projects", systemImage: "folder") }

            ChatView()
                .tabItem { Label("Chat", systemImage: "bubble.left.and.bubble.right") }

            FocusView()
                .tabItem { Label("Focus", systemImage: "timer") }

            InsightsView()
                .tabItem { Label("Insights", systemImage: "chart.line.uptrend.xyaxis") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .overlay(alignment: .bottomTrailing) {
            FloatingTimerWidget()
                .padding()
        }
    }
}
