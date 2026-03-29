import SwiftUI
import SmartPlanCore

struct TodayView: View {
    @EnvironmentObject private var store: AppStore
    @State private var title = ""
    @State private var dueDate = DateCodec.formatDate(Date())
    @State private var priority: Priority = .none
    @State private var timeAllocated = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                createRow
                controls
                List {
                    ForEach(store.visibleTasks, id: \.id) { task in
                        taskRow(task)
                    }
                    .onDelete { indexSet in
                        indexSet.compactMap { store.visibleTasks[safe: $0]?.id }.forEach(store.deleteTask)
                    }
                }
            }
            .navigationTitle("Today")
        }
    }

    private var createRow: some View {
        VStack(spacing: 8) {
            TextField("Add a task", text: $title)
                .textFieldStyle(.roundedBorder)
            HStack {
                TextField("YYYY-MM-DD", text: $dueDate)
                    .textFieldStyle(.roundedBorder)
                Picker("Priority", selection: $priority) {
                    ForEach(Priority.allCases, id: \.rawValue) { p in
                        Text(p.rawValue).tag(p)
                    }
                }
                .pickerStyle(.menu)
                TextField("Mins", text: $timeAllocated)
                    .frame(width: 70)
                    .textFieldStyle(.roundedBorder)
                Button("Add") {
                    store.createTask(
                        title: title,
                        dueDate: dueDate,
                        priority: priority,
                        timeAllocated: Int(timeAllocated),
                        tags: []
                    )
                    title = ""
                    timeAllocated = ""
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(.horizontal)
    }

    private var controls: some View {
        HStack {
            Toggle("Backlog", isOn: $store.showBacklog)
            Text("Backlog: \(store.backlogCount)")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Picker("Sort", selection: $store.sortKey) {
                ForEach(SortKey.allCases, id: \.rawValue) { s in
                    Text(s.rawValue).tag(s)
                }
            }
            .pickerStyle(.menu)
        }
        .padding(.horizontal)
    }

    private func taskRow(_ task: SPTask) -> some View {
        HStack {
            Button {
                store.toggleTaskCompletion(task.id)
            } label: {
                Image(systemName: task.completed ? "checkmark.circle.fill" : "circle")
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .strikethrough(task.completed)
                Text(task.due.date.isEmpty ? "No due date" : task.due.date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let mins = task.timeAllocated {
                Text("\(mins)m")
                    .font(.caption)
                    .padding(6)
                    .background(.thinMaterial)
                    .clipShape(Capsule())
            }
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
