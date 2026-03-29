import Foundation

public enum Priority: String, Codable, CaseIterable, Sendable {
    case high = "High"
    case medium = "Medium"
    case low = "Low"
    case none = "None"
}

public enum RecurrenceType: String, Codable, Sendable {
    case none = "None"
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case custom = "Custom"
}

public enum RecurrenceUnit: String, Codable, Sendable {
    case day
    case week
    case month
}

public struct TaskObjective: Codable, Equatable, Sendable {
    public var amount: Double?
    public var unit: String?
    public var notes: String?

    public init(amount: Double? = nil, unit: String? = nil, notes: String? = nil) {
        self.amount = amount
        self.unit = unit
        self.notes = notes
    }
}

public struct RecurrenceRule: Codable, Equatable, Sendable {
    public var type: RecurrenceType
    public var interval: Int?
    public var unit: RecurrenceUnit
    public var daysOfWeek: [Int]

    public init(
        type: RecurrenceType = .none,
        interval: Int? = nil,
        unit: RecurrenceUnit = .day,
        daysOfWeek: [Int] = []
    ) {
        self.type = type
        self.interval = interval
        self.unit = unit
        self.daysOfWeek = daysOfWeek
    }
}

public struct TaskDue: Codable, Equatable, Sendable {
    public var date: String
    public var time: String

    public init(date: String = "", time: String = "") {
        self.date = date
        self.time = time
    }
}

public struct Task: Identifiable, Codable, Equatable, Sendable {
    public var id: Int
    public var title: String
    public var due: TaskDue
    public var priority: Priority
    public var tags: [String]
    public var completed: Bool
    public var completedDate: String?
    public var timeAllocated: Int?
    public var objective: TaskObjective
    public var projectId: String?
    public var recurrence: RecurrenceRule
    public var inToday: Bool
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: Int,
        title: String,
        due: TaskDue = TaskDue(),
        priority: Priority = .none,
        tags: [String] = [],
        completed: Bool = false,
        completedDate: String? = nil,
        timeAllocated: Int? = nil,
        objective: TaskObjective = TaskObjective(),
        projectId: String? = nil,
        recurrence: RecurrenceRule = RecurrenceRule(),
        inToday: Bool = false,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.title = title.isEmpty ? "Untitled task" : title
        self.due = due
        self.priority = priority
        self.tags = tags
        self.completed = completed
        self.completedDate = completedDate
        self.timeAllocated = timeAllocated
        self.objective = objective
        self.projectId = projectId
        self.recurrence = recurrence
        self.inToday = inToday
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct ProjectObjective: Codable, Equatable, Sendable {
    public var amount: Double
    public var unit: String
    public var notes: String

    public init(amount: Double, unit: String, notes: String = "") {
        self.amount = amount
        self.unit = unit
        self.notes = notes
    }
}

public struct Project: Identifiable, Codable, Equatable, Sendable {
    public var id: String
    public var title: String
    public var dueDate: String?
    public var priority: Priority
    public var tags: [String]
    public var objective: ProjectObjective
    public var progress: Double
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: String = UUID().uuidString,
        title: String,
        dueDate: String? = nil,
        priority: Priority = .none,
        tags: [String] = [],
        objective: ProjectObjective,
        progress: Double = 0,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.title = title.isEmpty ? "Untitled Project" : title
        self.dueDate = dueDate
        self.priority = priority
        self.tags = tags
        self.objective = objective
        self.progress = max(progress, 0)
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct ChatMessage: Codable, Equatable, Sendable {
    public var role: String
    public var content: String

    public init(role: String, content: String) {
        self.role = role
        self.content = content
    }
}

public struct Conversation: Identifiable, Codable, Equatable, Sendable {
    public var id: String
    public var title: String
    public var messages: [ChatMessage]
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: String = UUID().uuidString,
        title: String,
        messages: [ChatMessage] = [],
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.messages = messages
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public enum SortKey: String, CaseIterable, Sendable {
    case `default` = "Default"
    case priority = "Priority"
    case dueDate = "Due Date"
    case timeAllocated = "Time Allocated"
    case title = "Title"
}

public enum FilterKey: String, CaseIterable, Sendable {
    case all = "All"
    case incomplete = "Incomplete"
    case complete = "Complete"
}

public struct Insights: Codable, Equatable, Sendable {
    public var flowScore: Int
    public var streak: Int
    public var focusRatio: Int
    public var completedToday: Int
    public var completedWeek: Int
    public var timeSavedHours: Double
    public var timeSavedTaskCount: Int

    public init(
        flowScore: Int,
        streak: Int,
        focusRatio: Int,
        completedToday: Int,
        completedWeek: Int,
        timeSavedHours: Double,
        timeSavedTaskCount: Int
    ) {
        self.flowScore = flowScore
        self.streak = streak
        self.focusRatio = focusRatio
        self.completedToday = completedToday
        self.completedWeek = completedWeek
        self.timeSavedHours = timeSavedHours
        self.timeSavedTaskCount = timeSavedTaskCount
    }
}
