import Foundation

public enum InsightsEngine {
    public static func compute(tasks: [Task], dateProvider: DateProviding, calendar: Calendar = .current) -> Insights {
        let today = dateProvider.today(calendar: calendar)
        let todayString = DateCodec.formatDate(today)

        let allCount = max(tasks.count, 1)
        let completedCount = tasks.filter(\.completed).count
        let completionRate = Double(completedCount) / Double(allCount)

        let priorityTasks = tasks.filter { $0.priority != .none }
        let highTasks = tasks.filter { $0.priority == .high }.count
        let priorityBalance: Double
        if priorityTasks.isEmpty {
            priorityBalance = 1
        } else {
            priorityBalance = 1 - min(abs(Double(highTasks) / Double(priorityTasks.count) - 0.33), 1)
        }

        let allocatedTasks = tasks.filter { ($0.timeAllocated ?? 0) > 0 }
        let allocatedComplete = allocatedTasks.filter(\.completed).count
        let timeUsage = allocatedTasks.isEmpty ? 1 : Double(allocatedComplete) / Double(allocatedTasks.count)

        let flow = Int(((completionRate * 40) + (priorityBalance * 10) + (timeUsage * 20) + 30).rounded())

        let todayHigh = tasks.filter { !$0.completed && $0.priority == .high && ($0.inToday || $0.due.date == todayString) }
        let highWithoutMeetings = todayHigh.filter { !$0.tags.contains("Meetings") }
        let focusRatio = todayHigh.isEmpty ? 100 : Int((Double(highWithoutMeetings.count) / Double(todayHigh.count) * 100).rounded())

        let completedToday = tasks.filter { $0.completedDate == todayString }.count
        let weekAgo = calendar.date(byAdding: .day, value: -6, to: today) ?? today
        let completedWeek = tasks.filter {
            guard let done = $0.completedDate, let doneDate = DateCodec.parseDate(done) else { return false }
            return doneDate >= weekAgo && doneDate <= today
        }.count

        let timeSavedMinutes = tasks.reduce(0) { partial, task in
            guard task.completed, let alloc = task.timeAllocated else { return partial }
            return partial + max(alloc, 0)
        }
        let timeSavedTasks = tasks.filter { $0.completed && ($0.timeAllocated ?? 0) > 0 }.count

        return Insights(
            flowScore: min(max(flow, 0), 100),
            streak: computeStreak(tasks: tasks, today: today, calendar: calendar),
            focusRatio: min(max(focusRatio, 0), 100),
            completedToday: completedToday,
            completedWeek: completedWeek,
            timeSavedHours: Double(timeSavedMinutes) / 60,
            timeSavedTaskCount: timeSavedTasks
        )
    }

    private static func computeStreak(tasks: [Task], today: Date, calendar: Calendar) -> Int {
        let completions = Set(tasks.compactMap(\.completedDate))
        var streak = 0
        var cursor = today
        while true {
            let key = DateCodec.formatDate(cursor)
            if completions.contains(key) {
                streak += 1
                guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
                cursor = previous
            } else {
                break
            }
        }
        return streak
    }
}
