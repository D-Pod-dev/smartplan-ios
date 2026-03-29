import Foundation
import Combine
import SwiftUI
import SmartPlanCore

typealias SPTask = SmartPlanCore.Task
typealias SPProject = SmartPlanCore.Project
typealias SPConversation = SmartPlanCore.Conversation

@MainActor
final class AppStore: ObservableObject {
    @Published var tasks: [SPTask] = []
    @Published var projects: [SPProject] = []
    @Published var conversations: [SPConversation] = []
    @Published var currentConversationID: String?
    @Published var sortKey: SortKey = .default
    @Published var reverseSort = false
    @Published var filterKey: FilterKey = .all
    @Published var showBacklog = false
    @Published var focusQueue: [Int] = []
    @Published var focusSecondsRemaining: Int = 0
    @Published var focusRunning = false
    @Published var focusCurrentTaskID: Int?
    @Published var authSession: UserSession?
    @Published var notificationsEnabled = false

    private let persistence = PersistenceController()
    private let dateProvider: DateProviding
    private let config: AppConfig
    private let cloudStore: SupabaseCloudStore
    private let localStore: SwiftDataLocalStore
    private let sync: SyncCoordinator
    private var timer: Timer?

    init(dateProvider: DateProviding = SystemDateProvider(), config: AppConfig = .placeholder()) {
        self.dateProvider = dateProvider
        self.config = config
        self.cloudStore = SupabaseCloudStore(config: config)
        self.localStore = SwiftDataLocalStore(persistence: persistence)
        self.sync = SyncCoordinator(cloud: cloudStore, local: localStore)
        loadLocal()
        if conversations.isEmpty {
            let starter = SPConversation(title: "New conversation")
            conversations = [starter]
            currentConversationID = starter.id
            persistConversationsLocalOnly()
        }
    }

    var visibleTasks: [SPTask] {
        let source = showBacklog
            ? TaskEngine.todayTasks(tasks, dateProvider: dateProvider, backlogMode: true)
            : TaskEngine.todayTasks(tasks, dateProvider: dateProvider, backlogMode: false)
        let filtered = TaskEngine.filterTasks(source, filter: filterKey)
        return TaskEngine.sortTasks(filtered, sort: sortKey, reverse: reverseSort)
    }

    var allTasksSorted: [SPTask] {
        let filtered = TaskEngine.filterTasks(tasks, filter: filterKey)
        return TaskEngine.sortTasks(filtered, sort: sortKey, reverse: reverseSort)
    }

    var insights: Insights {
        InsightsEngine.compute(tasks: tasks, dateProvider: dateProvider)
    }

    var backlogCount: Int {
        TaskEngine.todayTasks(tasks, dateProvider: dateProvider, backlogMode: true).count
    }

    func createTask(
        title: String,
        dueDate: String,
        priority: Priority,
        timeAllocated: Int?,
        tags: [String]
    ) {
        let task = SPTask(
            id: Int.random(in: 1_000_000...9_999_999),
            title: title,
            due: TaskDue(date: dueDate, time: ""),
            priority: priority,
            tags: tags,
            timeAllocated: timeAllocated,
            inToday: false
        )
        tasks.append(TaskEngine.normalizedTaskForCreate(task, dateProvider: dateProvider))
        tasksChangedImmediateSync()
    }

    func updateTask(_ task: SPTask) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index] = task
        tasks[index].updatedAt = dateProvider.now()
        tasksChangedImmediateSync()
    }

    func deleteTask(id: Int) {
        tasks.removeAll { $0.id == id }
        tasksChangedImmediateSync()
    }

    func toggleTaskCompletion(_ id: Int) {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        let task = tasks[index]
        if task.completed {
            var copy = task
            copy.completed = false
            copy.completedDate = nil
            copy.updatedAt = dateProvider.now()
            tasks[index] = copy
        } else {
            let result = TaskEngine.completion(task: task, completedAmount: nil, dateProvider: dateProvider)
            tasks[index] = result.updatedTask
            if let next = result.nextOccurrence {
                tasks.append(next)
            }
            if let projectId = task.projectId,
               let pIndex = projects.firstIndex(where: { $0.id == projectId }) {
                let amount = task.objective.amount ?? Double(task.timeAllocated ?? 0)
                projects[pIndex] = ProjectEngine.applyProgress(project: projects[pIndex], amount: amount, isUndo: false)
            }
        }
        tasksChangedImmediateSync()
    }

    func createProject(title: String, dueDate: String?, priority: Priority, amount: Double, unit: String, notes: String) {
        let project = SPProject(
            title: title,
            dueDate: dueDate,
            priority: priority,
            tags: [],
            objective: ProjectObjective(amount: amount, unit: unit, notes: notes),
            progress: 0
        )
        projects.append(project)
        upsertProjectAutoTask(project)
        projectsChangedDebouncedSync()
    }

    func deleteProject(id: String) {
        projects.removeAll { $0.id == id }
        tasks.removeAll { $0.projectId == id }
        projectsChangedDebouncedSync()
        tasksChangedImmediateSync()
    }

    func upsertProjectAutoTask(_ project: SPProject) {
        guard let generated = ProjectEngine.autoTask(for: project, dateProvider: dateProvider) else { return }
        if let idx = tasks.firstIndex(where: { $0.projectId == project.id }) {
            var existing = tasks[idx]
            existing.title = generated.title
            existing.priority = generated.priority
            existing.tags = generated.tags
            existing.objective = generated.objective
            existing.timeAllocated = generated.timeAllocated
            existing.updatedAt = dateProvider.now()
            tasks[idx] = existing
        } else {
            tasks.append(generated)
        }
    }

    func sendChat(prompt: String) {
        guard let id = currentConversationID,
              let idx = conversations.firstIndex(where: { $0.id == id }) else { return }
        conversations[idx].messages.append(ChatMessage(role: "user", content: prompt))

        let snapshot = tasks.map { task in
            "#\(task.id) \(task.title) due:\(task.due.date) priority:\(task.priority.rawValue) completed:\(task.completed)"
        }.joined(separator: "\n")
        let assistantText = "I reviewed your tasks and prepared actionable updates.\n\n<smartplan_actions>{\"actions\":[{\"type\":\"create\",\"title\":\"Plan tomorrow\"}]}</smartplan_actions>\n\nSnapshot:\n\(snapshot.prefix(200))"
        conversations[idx].messages.append(ChatMessage(role: "assistant", content: assistantText))
        conversations[idx].updatedAt = dateProvider.now()
        parseAndApplyActions(from: assistantText)
        conversationsChangedDebouncedSync()
    }

    func addConversation() {
        let newConversation = SPConversation(title: "Conversation \(conversations.count + 1)")
        conversations.insert(newConversation, at: 0)
        currentConversationID = newConversation.id
        conversationsChangedDebouncedSync()
    }

    func deleteConversation(id: String) {
        conversations.removeAll { $0.id == id }
        if currentConversationID == id {
            currentConversationID = conversations.first?.id
        }
        conversationsChangedDebouncedSync()
    }

    func startFocus() {
        guard focusCurrentTaskID != nil || !focusQueue.isEmpty else {
            focusCurrentTaskID = focusQueue.first
            return
        }
        if focusCurrentTaskID == nil {
            focusCurrentTaskID = focusQueue.first
        }
        if focusSecondsRemaining == 0,
           let current = focusCurrentTaskID,
           let task = tasks.first(where: { $0.id == current }) {
            focusSecondsRemaining = max((task.timeAllocated ?? 25) * 60, 60)
        }
        focusRunning = true
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            _Concurrency.Task { @MainActor in
                self?.tickFocus()
            }
        }
    }

    func pauseFocus() {
        focusRunning = false
        timer?.invalidate()
    }

    func stopFocus() {
        focusRunning = false
        focusSecondsRemaining = 0
        focusCurrentTaskID = nil
        timer?.invalidate()
    }

    func enqueueTask(_ id: Int) {
        if !focusQueue.contains(id) {
            focusQueue.append(id)
            if focusCurrentTaskID == nil { focusCurrentTaskID = id }
        }
    }

    func signInAnonymously() {
        authSession = UserSession(userID: UUID().uuidString, isAnonymous: true, email: nil)
        _Concurrency.Task {
            try? await sync.bootstrap(session: authSession!)
        }
    }

    func signOut() {
        authSession = nil
    }

    private func tickFocus() {
        guard focusRunning else { return }
        guard focusSecondsRemaining > 0 else {
            focusRunning = false
            timer?.invalidate()
            if let current = focusCurrentTaskID {
                toggleTaskCompletion(current)
                focusQueue.removeAll { $0 == current }
                focusCurrentTaskID = focusQueue.first
                focusSecondsRemaining = 0
            }
            return
        }
        focusSecondsRemaining -= 1
    }

    private func parseAndApplyActions(from assistantText: String) {
        guard let start = assistantText.range(of: "<smartplan_actions>"),
              let end = assistantText.range(of: "</smartplan_actions>") else { return }
        let payload = String(assistantText[start.upperBound..<end.lowerBound])
        guard let data = payload.data(using: .utf8) else { return }
        struct Envelope: Codable { let actions: [ActionPayload] }
        struct ActionPayload: Codable {
            let type: String
            let taskId: Int?
            let title: String?
            let dueDate: String?
        }
        guard let decoded = try? JSONDecoder().decode(Envelope.self, from: data) else { return }
        for action in decoded.actions {
            let engineAction = AIAction(
                type: AIActionType(rawValue: action.type) ?? .create,
                taskId: action.taskId,
                payload: ["title": action.title ?? "Untitled task", "dueDate": action.dueDate ?? ""]
            )
            let result = AIActionEngine.apply(action: engineAction, to: tasks, dateProvider: dateProvider)
            if !result.requiresApproval {
                tasks = result.tasks
            }
        }
        tasksChangedImmediateSync()
    }

    private func loadLocal() {
        tasks = (try? persistence.loadTasks()) ?? []
        projects = (try? persistence.loadProjects()) ?? []
        conversations = (try? persistence.loadConversations()) ?? []
        let settings = persistence.loadSettings()
        notificationsEnabled = false
        if let overrideISO = settings.dateOverrideISO,
           let overrideDate = DateCodec.parseDate(overrideISO) {
            _ = overrideDate
        }
    }

    private func tasksChangedImmediateSync() {
        try? persistence.saveTasks(tasks)
        guard let session = authSession else { return }
        _Concurrency.Task {
            try? await sync.syncTasksImmediate(session: session, tasks: tasks)
        }
    }

    private func projectsChangedDebouncedSync() {
        try? persistence.saveProjects(projects)
        guard let session = authSession else { return }
        _Concurrency.Task {
            try? await sync.syncProjectsDebounced(session: session, projects: projects)
        }
    }

    private func conversationsChangedDebouncedSync() {
        try? persistence.saveConversations(conversations)
        guard let session = authSession else { return }
        _Concurrency.Task {
            try? await sync.syncConversationsDebounced(session: session, conversations: conversations)
        }
    }

    private func persistConversationsLocalOnly() {
        try? persistence.saveConversations(conversations)
    }
}
