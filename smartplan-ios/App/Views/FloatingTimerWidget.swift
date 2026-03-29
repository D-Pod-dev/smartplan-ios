import SwiftUI

struct FloatingTimerWidget: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        if store.focusRunning || store.focusSecondsRemaining > 0 {
            HStack(spacing: 8) {
                Image(systemName: store.focusRunning ? "timer.circle.fill" : "timer.circle")
                Text("\(store.focusSecondsRemaining / 60):\(String(format: "%02d", store.focusSecondsRemaining % 60))")
                    .monospacedDigit()
                Button(store.focusRunning ? "Pause" : "Resume") {
                    if store.focusRunning { store.pauseFocus() } else { store.startFocus() }
                }
            }
            .font(.caption)
            .padding(10)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .shadow(radius: 6)
        }
    }
}
