import XCTest
@testable import SmartPlanCore

final class InsightsEngineTests: XCTestCase {
    func testInsightsComputesValidRanges() {
        let provider = OverrideDateProvider(override: DateCodec.parseDate("2026-03-21"))
        let tasks = [
            Task(id: 1, title: "A", due: TaskDue(date: "2026-03-21", time: ""), priority: .high, completed: true, completedDate: "2026-03-21", timeAllocated: 30),
            Task(id: 2, title: "B", due: TaskDue(date: "2026-03-21", time: ""), priority: .medium, completed: false, timeAllocated: 20)
        ]
        let insights = InsightsEngine.compute(tasks: tasks, dateProvider: provider)
        XCTAssertTrue((0...100).contains(insights.flowScore))
        XCTAssertTrue((0...100).contains(insights.focusRatio))
        XCTAssertEqual(insights.completedToday, 1)
    }
}
