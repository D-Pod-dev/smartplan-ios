import Foundation

public enum TaskEngine {
    public static func normalizedTaskForCreate(
        _ task: Task,
        dateProvider: DateProviding,
        calendar: Calendar = .current
    ) -> Task {
        var copy = task
        let today = dateProvider.today(calendar: calendar)

        if let dueDate = DateCodec.parseDate(copy.due.date) {
            let dayDiff = calendar.dateComponents([.day], from: today, to: calendar.startOfDay(for: dueDate)).day ?? 0
            if dayDiff <= 1 {
                copy.inToday = true
            }
        }

        if copy.recurrence.type != .none,
           let dueDate = DateCodec.parseDate(copy.due.date),
           dueDate < today {
            copy.due.date = DateCodec.formatDate(today)
            copy.inToday = true
        }

        if copy.recurrence.type == .weekly || (copy.recurrence.type == .custom && copy.recurrence.unit == .week) {
            if copy.recurrence.daysOfWeek.isEmpty {
                copy.recurrence.daysOfWeek = [calendar.component(.weekday, from: today)]
            }
            if let date = firstWeeklyOccurrence(task: copy, from: today, calendar: calendar) {
                copy.due.date = DateCodec.formatDate(date)
            }
        }

        return copy
    }

    public static func completion(
        task: Task,
        completedAmount: Double?,
        dateProvider: DateProviding,
        calendar: Calendar = .current
    ) -> (updatedTask: Task, nextOccurrence: Task?) {
        var done = task
        done.completed = true
        done.completedDate = DateCodec.formatDate(dateProvider.today(calendar: calendar))
        done.updatedAt = dateProvider.now()

        guard task.recurrence.type != .none else {
            return (done, nil)
        }

        let amount = completedAmount ?? done.objective.amount
        let _ = amount
        var next = task
        next.id = Int.random(in: 1_000_000...9_999_999)
        next.completed = false
        next.completedDate = nil
        next.createdAt = dateProvider.now()
        next.updatedAt = dateProvider.now()
        next.due.date = nextOccurrenceDate(from: task, calendar: calendar).map(DateCodec.formatDate) ?? task.due.date
        next.inToday = true
        return (done, next)
    }

    public static func nextOccurrenceDate(from task: Task, calendar: Calendar = .current) -> Date? {
        let base = DateCodec.parseDate(task.due.date) ?? calendar.startOfDay(for: Date())
        switch task.recurrence.type {
        case .none:
            return nil
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: base)
        case .weekly:
            return nextWeeklyDate(from: base, daysOfWeek: task.recurrence.daysOfWeek, weekStep: 1, calendar: calendar)
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: base)
        case .custom:
            let interval = max(task.recurrence.interval ?? 1, 1)
            switch task.recurrence.unit {
            case .day:
                return calendar.date(byAdding: .day, value: interval, to: base)
            case .week:
                return nextWeeklyDate(from: base, daysOfWeek: task.recurrence.daysOfWeek, weekStep: interval, calendar: calendar)
            case .month:
                return calendar.date(byAdding: .month, value: interval, to: base)
            }
        }
    }

    public static func sortTasks(_ tasks: [Task], sort: SortKey, reverse: Bool) -> [Task] {
        let sorted: [Task]
        switch sort {
        case .default:
            sorted = tasks.sorted { $0.createdAt < $1.createdAt }
        case .priority:
            sorted = tasks.sorted { lhs, rhs in
                let primary = priorityRank(lhs.priority) < priorityRank(rhs.priority)
                if priorityRank(lhs.priority) == priorityRank(rhs.priority) {
                    return dueDateSort(lhs.due.date, rhs.due.date)
                }
                return primary
            }
        case .dueDate:
            sorted = tasks.sorted { lhs, rhs in
                if lhs.due.date == rhs.due.date {
                    return priorityRank(lhs.priority) < priorityRank(rhs.priority)
                }
                return dueDateSort(lhs.due.date, rhs.due.date)
            }
        case .timeAllocated:
            sorted = tasks.sorted { lhs, rhs in
                let l = lhs.timeAllocated ?? -1
                let r = rhs.timeAllocated ?? -1
                if l == r {
                    return dueDateSort(lhs.due.date, rhs.due.date)
                }
                return l > r
            }
        case .title:
            sorted = tasks.sorted { lhs, rhs in
                if lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedSame {
                    return dueDateSort(lhs.due.date, rhs.due.date)
                }
                return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
            }
        }
        return reverse ? Array(sorted.reversed()) : sorted
    }

    public static func filterTasks(_ tasks: [Task], filter: FilterKey) -> [Task] {
        switch filter {
        case .all:
            return tasks
        case .incomplete:
            return tasks.filter { !$0.completed }
        case .complete:
            return tasks.filter(\.completed)
        }
    }

    public static func todayTasks(_ tasks: [Task], dateProvider: DateProviding, backlogMode: Bool, calendar: Calendar = .current) -> [Task] {
        let todayString = DateCodec.formatDate(dateProvider.today(calendar: calendar))
        if backlogMode {
            return tasks.filter { task in
                guard !task.completed else { return false }
                if let due = DateCodec.parseDate(task.due.date) {
                    return due < dateProvider.today(calendar: calendar)
                }
                return !task.inToday
            }
        }

        return tasks.filter { task in
            if task.completed {
                return task.completedDate == todayString
            }
            return task.inToday || task.due.date == todayString
        }
    }

    private static func firstWeeklyOccurrence(task: Task, from today: Date, calendar: Calendar) -> Date? {
        let start = DateCodec.parseDate(task.due.date) ?? today
        let candidates = (0..<14).compactMap { offset -> Date? in
            calendar.date(byAdding: .day, value: offset, to: start)
        }
        let set = Set(task.recurrence.daysOfWeek)
        return candidates.first { candidate in
            let weekday = calendar.component(.weekday, from: candidate)
            return set.contains(weekday) && candidate >= today
        }
    }

    private static func dueDateSort(_ lhs: String, _ rhs: String) -> Bool {
        switch (DateCodec.parseDate(lhs), DateCodec.parseDate(rhs)) {
        case let (l?, r?): return l < r
        case (_?, nil): return true
        case (nil, _?): return false
        case (nil, nil): return false
        }
    }

    private static func priorityRank(_ priority: Priority) -> Int {
        switch priority {
        case .high: return 0
        case .medium: return 1
        case .low: return 2
        case .none: return 3
        }
    }

    private static func nextWeeklyDate(from base: Date, daysOfWeek: [Int], weekStep: Int, calendar: Calendar) -> Date? {
        let set = Set(daysOfWeek)
        guard !set.isEmpty else { return calendar.date(byAdding: .day, value: 7 * weekStep, to: base) }
        for offset in 1..<(7 * weekStep + 8) {
            guard let candidate = calendar.date(byAdding: .day, value: offset, to: base) else { continue }
            let weekday = calendar.component(.weekday, from: candidate)
            if set.contains(weekday) {
                return candidate
            }
        }
        return calendar.date(byAdding: .day, value: 7 * weekStep, to: base)
    }
}
