import SwiftUI

struct FocusView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                VStack(spacing: 6) {
                    Text("\(store.focusSecondsRemaining / 60):\(String(format: "%02d", store.focusSecondsRemaining % 60))")
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                    Text(currentTaskTitle)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Button("Start") { store.startFocus() }
                    Button("Pause") { store.pauseFocus() }
                    Button("Stop") { store.stopFocus() }
                }
                .buttonStyle(.borderedProminent)

                List {
                    Section("Queue") {
                        ForEach(store.focusQueue, id: \.self) { id in
                            Text(store.tasks.first(where: { $0.id == id })?.title ?? "Unknown")
                        }
                    }
                    Section("Eligible Tasks") {
                        ForEach(store.tasks.filter { ($0.timeAllocated ?? 0) > 0 }, id: \.id) { task in
                            HStack {
                                Text(task.title)
                                Spacer()
                                Button("Queue") { store.enqueueTask(task.id) }
                            }
                        }
                    }
                }
            }
            .padding()
            .navigationTitle("Focus")
        }
    }

    private var currentTaskTitle: String {
        guard let id = store.focusCurrentTaskID else { return "No active task" }
        return store.tasks.first(where: { $0.id == id })?.title ?? "No active task"
    }
}
