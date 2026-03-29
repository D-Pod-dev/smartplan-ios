import Foundation

public struct AppConfig: Sendable {
    public var supabaseURL: String
    public var supabaseAnonKey: String
    public var groqBaseURL: String
    public var groqAPIKey: String
    public var groqModel: String

    public init(
        supabaseURL: String,
        supabaseAnonKey: String,
        groqBaseURL: String,
        groqAPIKey: String,
        groqModel: String
    ) {
        self.supabaseURL = supabaseURL
        self.supabaseAnonKey = supabaseAnonKey
        self.groqBaseURL = groqBaseURL
        self.groqAPIKey = groqAPIKey
        self.groqModel = groqModel
    }

    public static func placeholder() -> AppConfig {
        AppConfig(
            supabaseURL: "__SUPABASE_URL__",
            supabaseAnonKey: "__SUPABASE_ANON_KEY__",
            groqBaseURL: "__GROQ_BASE_URL__",
            groqAPIKey: "__GROQ_API_KEY__",
            groqModel: "llama-3.3-70b-versatile"
        )
    }

    public var hasPlaceholders: Bool {
        [supabaseURL, supabaseAnonKey, groqBaseURL, groqAPIKey].contains { $0.contains("__") }
    }
}
