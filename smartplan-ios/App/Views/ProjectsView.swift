import SwiftUI
import SmartPlanCore

struct ProjectsView: View {
    @EnvironmentObject private var store: AppStore
    @State private var title = ""
    @State private var dueDate = DateCodec.formatDate(Date())
    @State private var priority: Priority = .none
    @State private var amount = "1"
    @State private var unit = "pages"
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 10) {
                createProjectRow
                List {
                    ForEach(store.projects, id: \.id) { project in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(project.title).font(.headline)
                            Text("Objective: \(project.objective.amount.formatted()) \(project.objective.unit)")
                                .font(.caption)
                            Text("Progress: \(project.progress.formatted())")
                                .font(.caption)
                            if let generated = ProjectEngine.autoTask(for: project, dateProvider: SystemDateProvider()) {
                                Text(generated.timeAllocated != nil
                                     ? "Daily workload: \(generated.timeAllocated ?? 0) min/day"
                                     : "Daily workload: \(Int(generated.objective.amount ?? 0)) \(generated.objective.unit ?? "")/day")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete { offsets in
                        offsets.map { store.projects[$0].id }.forEach(store.deleteProject)
                    }
                }
            }
            .navigationTitle("Projects")
        }
    }

    private var createProjectRow: some View {
        VStack(spacing: 8) {
            TextField("Project title", text: $title).textFieldStyle(.roundedBorder)
            HStack {
                TextField("Due YYYY-MM-DD", text: $dueDate).textFieldStyle(.roundedBorder)
                Picker("Priority", selection: $priority) {
                    ForEach(Priority.allCases, id: \.rawValue) { p in Text(p.rawValue).tag(p) }
                }
                .pickerStyle(.menu)
            }
            HStack {
                TextField("Amount", text: $amount).textFieldStyle(.roundedBorder)
                TextField("Unit", text: $unit).textFieldStyle(.roundedBorder)
                TextField("Notes", text: $notes).textFieldStyle(.roundedBorder)
                Button("Create") {
                    store.createProject(
                        title: title,
                        dueDate: dueDate,
                        priority: priority,
                        amount: Double(amount) ?? 0,
                        unit: unit,
                        notes: notes
                    )
                    title = ""
                    notes = ""
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(.horizontal)
    }
}
