import Foundation
import SwiftData
import SmartPlanCore

@MainActor
final class PersistenceController {
    let container: ModelContainer
    let context: ModelContext

    init() {
        let schema = Schema([TaskEntity.self, ProjectEntity.self, ConversationEntity.self, AppSettingsEntity.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        container = try! ModelContainer(for: schema, configurations: [config])
        context = ModelContext(container)
        ensureSettings()
    }

    func loadTasks() throws -> [Task] {
        let descriptor = FetchDescriptor<TaskEntity>(sortBy: [SortDescriptor(\.createdAt)])
        return try context.fetch(descriptor).map { $0.toDomain() }
    }

    func saveTasks(_ tasks: [Task]) throws {
        let existing = try context.fetch(FetchDescriptor<TaskEntity>())
        for row in existing { context.delete(row) }
        for task in tasks { context.insert(TaskEntity(task: task)) }
        try context.save()
    }

    func loadProjects() throws -> [Project] {
        let descriptor = FetchDescriptor<ProjectEntity>(sortBy: [SortDescriptor(\.createdAt)])
        return try context.fetch(descriptor).map { $0.toDomain() }
    }

    func saveProjects(_ projects: [Project]) throws {
        let existing = try context.fetch(FetchDescriptor<ProjectEntity>())
        for row in existing { context.delete(row) }
        for project in projects { context.insert(ProjectEntity(project: project)) }
        try context.save()
    }

    func loadConversations() throws -> [Conversation] {
        let descriptor = FetchDescriptor<ConversationEntity>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)])
        return try context.fetch(descriptor).map { $0.toDomain() }
    }

    func saveConversations(_ conversations: [Conversation]) throws {
        let existing = try context.fetch(FetchDescriptor<ConversationEntity>())
        for row in existing { context.delete(row) }
        for c in conversations { context.insert(ConversationEntity(conversation: c)) }
        try context.save()
    }

    func loadSettings() -> AppSettingsEntity {
        if let first = try? context.fetch(FetchDescriptor<AppSettingsEntity>()).first {
            return first
        }
        let settings = AppSettingsEntity()
        context.insert(settings)
        try? context.save()
        return settings
    }

    func saveSettings() {
        try? context.save()
    }

    private func ensureSettings() {
        if (try? context.fetch(FetchDescriptor<AppSettingsEntity>()).isEmpty) == true {
            let settings = AppSettingsEntity()
            context.insert(settings)
            try? context.save()
        }
    }
}
