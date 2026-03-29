import SwiftUI
import SmartPlanCore

struct TasksView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Picker("Filter", selection: $store.filterKey) {
                        ForEach(FilterKey.allCases, id: \.rawValue) { key in
                            Text(key.rawValue).tag(key)
                        }
                    }
                    .pickerStyle(.segmented)

                    Toggle("Reverse", isOn: $store.reverseSort)
                        .toggleStyle(.switch)
                        .frame(maxWidth: 120)
                }
                .padding()

                List(store.allTasksSorted, id: \.id) { task in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(task.title)
                            Text(task.priority.rawValue)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if task.completed {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(.green)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        store.toggleTaskCompletion(task.id)
                    }
                }
            }
            .navigationTitle("Tasks")
        }
    }
}
