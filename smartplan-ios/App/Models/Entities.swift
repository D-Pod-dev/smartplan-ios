import Foundation
import SwiftData

@Model
final class TaskEntity {
    @Attribute(.unique) var id: Int
    var title: String
    var dueDate: String
    var dueTime: String
    var priority: String
    var tagsCSV: String
    var completed: Bool
    var completedDate: String?
    var timeAllocated: Int?
    var objectiveAmount: Double?
    var objectiveUnit: String?
    var objectiveNotes: String?
    var projectId: String?
    var recurrenceType: String
    var recurrenceInterval: Int?
    var recurrenceUnit: String
    var recurrenceDaysCSV: String
    var inToday: Bool
    var createdAt: Date
    var updatedAt: Date

    init(task: Task) {
        id = task.id
        title = task.title
        dueDate = task.due.date
        dueTime = task.due.time
        priority = task.priority.rawValue
        tagsCSV = task.tags.joined(separator: ",")
        completed = task.completed
        completedDate = task.completedDate
        timeAllocated = task.timeAllocated
        objectiveAmount = task.objective.amount
        objectiveUnit = task.objective.unit
        objectiveNotes = task.objective.notes
        projectId = task.projectId
        recurrenceType = task.recurrence.type.rawValue
        recurrenceInterval = task.recurrence.interval
        recurrenceUnit = task.recurrence.unit.rawValue
        recurrenceDaysCSV = task.recurrence.daysOfWeek.map(String.init).joined(separator: ",")
        inToday = task.inToday
        createdAt = task.createdAt
        updatedAt = task.updatedAt
    }

    func toDomain() -> Task {
        Task(
            id: id,
            title: title,
            due: TaskDue(date: dueDate, time: dueTime),
            priority: Priority(rawValue: priority) ?? .none,
            tags: tagsCSV.split(separator: ",").map { String($0) }.filter { !$0.isEmpty },
            completed: completed,
            completedDate: completedDate,
            timeAllocated: timeAllocated,
            objective: TaskObjective(amount: objectiveAmount, unit: objectiveUnit, notes: objectiveNotes),
            projectId: projectId,
            recurrence: RecurrenceRule(
                type: RecurrenceType(rawValue: recurrenceType) ?? .none,
                interval: recurrenceInterval,
                unit: RecurrenceUnit(rawValue: recurrenceUnit) ?? .day,
                daysOfWeek: recurrenceDaysCSV.split(separator: ",").compactMap { Int($0) }
            ),
            inToday: inToday,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

@Model
final class ProjectEntity {
    @Attribute(.unique) var id: String
    var title: String
    var dueDate: String?
    var priority: String
    var tagsCSV: String
    var objectiveAmount: Double
    var objectiveUnit: String
    var objectiveNotes: String
    var progress: Double
    var createdAt: Date
    var updatedAt: Date

    init(project: Project) {
        id = project.id
        title = project.title
        dueDate = project.dueDate
        priority = project.priority.rawValue
        tagsCSV = project.tags.joined(separator: ",")
        objectiveAmount = project.objective.amount
        objectiveUnit = project.objective.unit
        objectiveNotes = project.objective.notes
        progress = project.progress
        createdAt = project.createdAt
        updatedAt = project.updatedAt
    }

    func toDomain() -> Project {
        Project(
            id: id,
            title: title,
            dueDate: dueDate,
            priority: Priority(rawValue: priority) ?? .none,
            tags: tagsCSV.split(separator: ",").map { String($0) }.filter { !$0.isEmpty },
            objective: ProjectObjective(amount: objectiveAmount, unit: objectiveUnit, notes: objectiveNotes),
            progress: progress,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

@Model
final class ConversationEntity {
    @Attribute(.unique) var id: String
    var title: String
    var messagesJSON: String
    var createdAt: Date
    var updatedAt: Date

    init(conversation: Conversation) {
        id = conversation.id
        title = conversation.title
        let encoder = JSONEncoder()
        messagesJSON = String(data: (try? encoder.encode(conversation.messages)) ?? Data("[]".utf8), encoding: .utf8) ?? "[]"
        createdAt = conversation.createdAt
        updatedAt = conversation.updatedAt
    }

    func toDomain() -> Conversation {
        let decoder = JSONDecoder()
        let messages = (try? decoder.decode([ChatMessage].self, from: Data(messagesJSON.utf8))) ?? []
        return Conversation(id: id, title: title, messages: messages, createdAt: createdAt, updatedAt: updatedAt)
    }
}

@Model
final class AppSettingsEntity {
    var id: String
    var workDuration: Int
    var breakDuration: Int
    var enableBreaks: Bool
    var devPanelEnabled: Bool
    var dateOverrideISO: String?

    init(
        id: String = "settings",
        workDuration: Int = 25,
        breakDuration: Int = 5,
        enableBreaks: Bool = true,
        devPanelEnabled: Bool = false,
        dateOverrideISO: String? = nil
    ) {
        self.id = id
        self.workDuration = workDuration
        self.breakDuration = breakDuration
        self.enableBreaks = enableBreaks
        self.devPanelEnabled = devPanelEnabled
        self.dateOverrideISO = dateOverrideISO
    }
}
