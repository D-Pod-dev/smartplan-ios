import XCTest
@testable import SmartPlanCore

final class TaskEngineTests: XCTestCase {
    func testPrioritySortHasDueDateSecondary() {
        let now = Date()
        let t1 = Task(id: 1, title: "A", due: TaskDue(date: "2026-03-22", time: ""), priority: .high, createdAt: now, updatedAt: now)
        let t2 = Task(id: 2, title: "B", due: TaskDue(date: "2026-03-21", time: ""), priority: .high, createdAt: now, updatedAt: now)
        let sorted = TaskEngine.sortTasks([t1, t2], sort: .priority, reverse: false)
        XCTAssertEqual(sorted.first?.id, 2)
    }

    func testDailyRecurrenceCreatesNextOccurrence() {
        let task = Task(
            id: 1,
            title: "Habit",
            due: TaskDue(date: "2026-03-21", time: ""),
            recurrence: RecurrenceRule(type: .daily)
        )
        let provider = OverrideDateProvider(override: DateCodec.parseDate("2026-03-21"))
        let result = TaskEngine.completion(task: task, completedAmount: nil, dateProvider: provider)
        XCTAssertTrue(result.updatedTask.completed)
        XCTAssertEqual(result.nextOccurrence?.due.date, "2026-03-22")
    }
}
