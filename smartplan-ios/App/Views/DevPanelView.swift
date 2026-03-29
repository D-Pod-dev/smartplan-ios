import SwiftUI

struct DevPanelView: View {
    @State private var overrideDate = ""

    var body: some View {
        Form {
            Section("Date Override") {
                TextField("YYYY-MM-DD", text: $overrideDate)
                Text("Set a simulated current date for test scenarios.")
                    .foregroundStyle(.secondary)
                Button("Clear Override") {
                    overrideDate = ""
                }
            }
        }
        .navigationTitle("Dev Panel")
    }
}
