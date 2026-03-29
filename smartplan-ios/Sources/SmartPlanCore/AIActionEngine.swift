import Foundation

public enum AIActionType: String, Codable, Sendable {
    case create
    case update
    case complete
    case delete
}

public struct AIAction: Codable, Sendable {
    public var id: String
    public var type: AIActionType
    public var taskId: Int?
    public var payload: [String: String]

    public init(id: String = UUID().uuidString, type: AIActionType, taskId: Int? = nil, payload: [String: String] = [:]) {
        self.id = id
        self.type = type
        self.taskId = taskId
        self.payload = payload
    }
}

public struct AIActionResult: Sendable {
    public var tasks: [Task]
    public var requiresApproval: Bool
    public var blockedReason: String?

    public init(tasks: [Task], requiresApproval: Bool = false, blockedReason: String? = nil) {
        self.tasks = tasks
        self.requiresApproval = requiresApproval
        self.blockedReason = blockedReason
    }
}

public enum AIActionEngine {
    public static func apply(action: AIAction, to tasks: [Task], dateProvider: DateProviding) -> AIActionResult {
        switch action.type {
        case .create:
            var all = tasks
            let newTask = Task(
                id: Int.random(in: 1_000_000...9_999_999),
                title: action.payload["title"] ?? "Untitled task",
                due: TaskDue(date: action.payload["dueDate"] ?? "", time: action.payload["dueTime"] ?? ""),
                priority: Priority(rawValue: action.payload["priority"] ?? "None") ?? .none,
                tags: action.payload["tags"]?.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) } ?? [],
                completed: false,
                timeAllocated: Int(action.payload["timeAllocated"] ?? ""),
                objective: TaskObjective(amount: Double(action.payload["objectiveAmount"] ?? ""), unit: action.payload["objectiveUnit"], notes: action.payload["objectiveNotes"]),
                inToday: false,
                createdAt: dateProvider.now(),
                updatedAt: dateProvider.now()
            )
            all.append(TaskEngine.normalizedTaskForCreate(newTask, dateProvider: dateProvider))
            return AIActionResult(tasks: all)
        case .update:
            guard let id = action.taskId, let index = tasks.firstIndex(where: { $0.id == id }) else {
                return AIActionResult(tasks: tasks, blockedReason: "Task not found")
            }
            var all = tasks
            var task = all[index]
            if let title = action.payload["title"] { task.title = title }
            if let due = action.payload["dueDate"] { task.due.date = due }
            if let time = action.payload["dueTime"] { task.due.time = time }
            if let priority = action.payload["priority"], let p = Priority(rawValue: priority) { task.priority = p }
            task.updatedAt = dateProvider.now()
            all[index] = task
            return AIActionResult(tasks: all)
        case .complete:
            guard let id = action.taskId, let index = tasks.firstIndex(where: { $0.id == id }) else {
                return AIActionResult(tasks: tasks, blockedReason: "Task not found")
            }
            var all = tasks
            var task = all[index]
            task.completed = true
            task.completedDate = DateCodec.formatDate(dateProvider.today(calendar: .current))
            task.updatedAt = dateProvider.now()
            all[index] = task
            return AIActionResult(tasks: all)
        case .delete:
            return AIActionResult(tasks: tasks, requiresApproval: true, blockedReason: "Delete requires approval")
        }
    }

    public static func approveDelete(action: AIAction, tasks: [Task]) -> [Task] {
        guard let id = action.taskId else { return tasks }
        return tasks.filter { $0.id != id }
    }
}
