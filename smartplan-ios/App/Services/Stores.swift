import Foundation
import SmartPlanCore

actor SwiftDataLocalStore: LocalStore {
    private let persistence: PersistenceController

    init(persistence: PersistenceController) {
        self.persistence = persistence
    }

    func loadTasks() async throws -> [Task] {
        try await MainActor.run {
            try persistence.loadTasks()
        }
    }

    func saveTasks(_ tasks: [Task]) async throws {
        try await MainActor.run {
            try persistence.saveTasks(tasks)
        }
    }

    func loadProjects() async throws -> [Project] {
        try await MainActor.run {
            try persistence.loadProjects()
        }
    }

    func saveProjects(_ projects: [Project]) async throws {
        try await MainActor.run {
            try persistence.saveProjects(projects)
        }
    }

    func loadConversations() async throws -> [Conversation] {
        try await MainActor.run {
            try persistence.loadConversations()
        }
    }

    func saveConversations(_ conversations: [Conversation]) async throws {
        try await MainActor.run {
            try persistence.saveConversations(conversations)
        }
    }
}

actor SupabaseCloudStore: CloudStore {
    private let config: AppConfig
    private var remoteTasks: [String: [Task]] = [:]
    private var remoteProjects: [String: [Project]] = [:]
    private var remoteConversations: [String: [Conversation]] = [:]

    init(config: AppConfig) {
        self.config = config
    }

    func fetchTasks(userID: String) async throws -> [Task] {
        remoteTasks[userID] ?? []
    }

    func replaceTasks(userID: String, tasks: [Task]) async throws {
        remoteTasks[userID] = tasks
        _ = config
    }

    func fetchProjects(userID: String) async throws -> [Project] {
        remoteProjects[userID] ?? []
    }

    func upsertProjects(userID: String, projects: [Project]) async throws {
        remoteProjects[userID] = projects
    }

    func fetchConversations(userID: String) async throws -> [Conversation] {
        remoteConversations[userID] ?? []
    }

    func upsertConversations(userID: String, conversations: [Conversation]) async throws {
        remoteConversations[userID] = conversations
    }
}
