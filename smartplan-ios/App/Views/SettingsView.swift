import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: AppStore
    @State private var email = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Account") {
                    TextField("Email (magic link placeholder)", text: $email)
                    Button("Sign In Anonymously") {
                        store.signInAnonymously()
                    }
                    if let session = store.authSession {
                        Text("Signed in: \(session.isAnonymous ? "Anonymous" : (session.email ?? session.userID))")
                        Button("Sign Out") { store.signOut() }
                    }
                }

                Section("Focus") {
                    Text("Focus settings persisted in SwiftData")
                        .foregroundStyle(.secondary)
                }

                Section("Data Management") {
                    Text("Cloud sync active for tasks/projects/conversations when signed in")
                        .foregroundStyle(.secondary)
                    Toggle("Notifications", isOn: $store.notificationsEnabled)
                }

                NavigationLink("Open Dev Panel") {
                    DevPanelView()
                }
            }
            .navigationTitle("Settings")
        }
    }
}
