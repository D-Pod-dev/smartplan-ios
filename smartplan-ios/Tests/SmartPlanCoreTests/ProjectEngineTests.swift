import XCTest
@testable import SmartPlanCore

final class ProjectEngineTests: XCTestCase {
    func testMinuteObjectiveProducesTimeAllocationTask() {
        let provider = OverrideDateProvider(override: DateCodec.parseDate("2026-03-21"))
        let project = Project(
            id: "p1",
            title: "Essay",
            dueDate: "2026-03-23",
            priority: .high,
            tags: ["Writing"],
            objective: ProjectObjective(amount: 60, unit: "minutes", notes: ""),
            progress: 0
        )
        let generated = ProjectEngine.autoTask(for: project, dateProvider: provider)
        XCTAssertNotNil(generated)
        XCTAssertNotNil(generated?.timeAllocated)
        XCTAssertEqual(generated?.tags.contains("Project"), true)
    }
}
