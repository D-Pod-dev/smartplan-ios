import Foundation

public struct UserSession: Sendable, Equatable {
    public var userID: String
    public var isAnonymous: Bool
    public var email: String?

    public init(userID: String, isAnonymous: Bool, email: String?) {
        self.userID = userID
        self.isAnonymous = isAnonymous
        self.email = email
    }
}

public protocol CloudStore: Sendable {
    func fetchTasks(userID: String) async throws -> [Task]
    func replaceTasks(userID: String, tasks: [Task]) async throws

    func fetchProjects(userID: String) async throws -> [Project]
    func upsertProjects(userID: String, projects: [Project]) async throws

    func fetchConversations(userID: String) async throws -> [Conversation]
    func upsertConversations(userID: String, conversations: [Conversation]) async throws
}

public protocol LocalStore: Sendable {
    func loadTasks() async throws -> [Task]
    func saveTasks(_ tasks: [Task]) async throws

    func loadProjects() async throws -> [Project]
    func saveProjects(_ projects: [Project]) async throws

    func loadConversations() async throws -> [Conversation]
    func saveConversations(_ conversations: [Conversation]) async throws
}

public actor SyncCoordinator {
    private let cloud: CloudStore
    private let local: LocalStore
    private let debounceNanoseconds: UInt64

    public init(cloud: CloudStore, local: LocalStore, debounceSeconds: Double = 1.0) {
        self.cloud = cloud
        self.local = local
        self.debounceNanoseconds = UInt64(max(debounceSeconds, 0) * 1_000_000_000)
    }

    public func bootstrap(session: UserSession) async throws {
        let remoteTasks = try await cloud.fetchTasks(userID: session.userID)
        let remoteProjects = try await cloud.fetchProjects(userID: session.userID)
        let remoteConversations = try await cloud.fetchConversations(userID: session.userID)

        let localTasks = try await local.loadTasks()
        let localProjects = try await local.loadProjects()
        let localConversations = try await local.loadConversations()

        if remoteTasks.isEmpty && remoteProjects.isEmpty && remoteConversations.isEmpty {
            if !localTasks.isEmpty || !localProjects.isEmpty || !localConversations.isEmpty {
                try await cloud.replaceTasks(userID: session.userID, tasks: localTasks)
                try await cloud.upsertProjects(userID: session.userID, projects: localProjects)
                try await cloud.upsertConversations(userID: session.userID, conversations: localConversations)
            }
        } else {
            try await local.saveTasks(remoteTasks)
            try await local.saveProjects(remoteProjects)
            try await local.saveConversations(remoteConversations)
        }
    }

    public func syncTasksImmediate(session: UserSession, tasks: [Task]) async throws {
        try await local.saveTasks(tasks)
        try await cloud.replaceTasks(userID: session.userID, tasks: tasks)
    }

    public func syncProjectsDebounced(session: UserSession, projects: [Project]) async throws {
        try await local.saveProjects(projects)
        try await _Concurrency.Task<Never, Never>.sleep(nanoseconds: debounceNanoseconds)
        try await cloud.upsertProjects(userID: session.userID, projects: projects)
    }

    public func syncConversationsDebounced(session: UserSession, conversations: [Conversation]) async throws {
        try await local.saveConversations(conversations)
        try await _Concurrency.Task<Never, Never>.sleep(nanoseconds: debounceNanoseconds)
        try await cloud.upsertConversations(userID: session.userID, conversations: conversations)
    }
}
