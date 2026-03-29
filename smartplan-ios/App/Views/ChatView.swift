import SwiftUI
import SmartPlanCore

struct ChatView: View {
    @EnvironmentObject private var store: AppStore
    @State private var input = ""

    var body: some View {
        NavigationSplitView {
            List(selection: $store.currentConversationID) {
                ForEach(store.conversations, id: \.id) { convo in
                    Text(convo.title)
                        .tag(Optional(convo.id))
                }
                .onDelete { offsets in
                    offsets.map { store.conversations[$0].id }.forEach(store.deleteConversation)
                }
            }
            .toolbar {
                Button {
                    store.addConversation()
                } label: {
                    Image(systemName: "plus")
                }
            }
        } detail: {
            VStack {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        ForEach(currentMessages.indices, id: \.self) { idx in
                            let msg = currentMessages[idx]
                            HStack {
                                if msg.role == "assistant" { Spacer(minLength: 40) }
                                Text(msg.content)
                                    .padding(10)
                                    .background(msg.role == "user" ? Color.blue.opacity(0.15) : Color.gray.opacity(0.15))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                if msg.role == "user" { Spacer(minLength: 40) }
                            }
                        }
                    }
                    .padding()
                }
                HStack {
                    TextField("Ask SmartPlan", text: $input)
                        .textFieldStyle(.roundedBorder)
                    Button("Send") {
                        guard !input.isEmpty else { return }
                        store.sendChat(prompt: input)
                        input = ""
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
            .navigationTitle("Assistant")
        }
    }

    private var currentMessages: [ChatMessage] {
        guard let id = store.currentConversationID,
              let convo = store.conversations.first(where: { $0.id == id }) else {
            return []
        }
        return convo.messages
    }
}
