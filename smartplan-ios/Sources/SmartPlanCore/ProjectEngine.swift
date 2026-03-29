import Foundation

public enum ProjectEngine {
    public static func autoTask(for project: Project, dateProvider: DateProviding, calendar: Calendar = .current) -> Task? {
        guard
            let dueDateString = project.dueDate,
            let dueDate = DateCodec.parseDate(dueDateString)
        else {
            return nil
        }

        let today = dateProvider.today(calendar: calendar)
        let end = calendar.startOfDay(for: dueDate)
        let daysLeft = max((calendar.dateComponents([.day], from: today, to: end).day ?? 0) + 1, 1)
        let remaining = max(project.objective.amount - project.progress, 0)
        let daily = Int(ceil(remaining / Double(daysLeft)))

        var task = Task(
            id: Int.random(in: 1_000_000...9_999_999),
            title: "Work on '\(project.title)'",
            due: TaskDue(date: DateCodec.formatDate(today), time: ""),
            priority: project.priority,
            tags: mergedTags(project.tags),
            completed: false,
            timeAllocated: nil,
            objective: TaskObjective(),
            projectId: project.id,
            recurrence: RecurrenceRule(type: .daily),
            inToday: true,
            createdAt: dateProvider.now(),
            updatedAt: dateProvider.now()
        )

        if isMinuteUnit(project.objective.unit) {
            task.timeAllocated = daily
        } else {
            task.objective.amount = Double(daily)
            task.objective.unit = project.objective.unit
            task.objective.notes = project.objective.notes
        }
        return task
    }

    public static func applyProgress(project: Project, amount: Double, isUndo: Bool) -> Project {
        var updated = project
        if isUndo {
            updated.progress = max(0, project.progress - amount)
        } else {
            updated.progress = max(0, project.progress + amount)
        }
        updated.updatedAt = .now
        return updated
    }

    private static func isMinuteUnit(_ unit: String) -> Bool {
        let normalized = unit.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return normalized == "minutes" || normalized == "minute" || normalized == "mins" || normalized == "min"
    }

    private static func mergedTags(_ tags: [String]) -> [String] {
        if tags.contains("Project") {
            return tags
        }
        return tags + ["Project"]
    }
}
