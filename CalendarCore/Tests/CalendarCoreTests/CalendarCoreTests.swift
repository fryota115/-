import Foundation
import XCTest
@testable import CalendarCore

final class CalendarCoreTests: XCTestCase {
    private let tokyo = CalendarDateMath(timeZone: TimeZone(identifier: "Asia/Tokyo")!)

    func testMonthGridIncludesAdjacentDatesAndLeapDay() {
        let weeks = tokyo.monthWeeks(containing: date(2024, 2, 29))
        XCTAssertEqual(weeks.count, 5)
        XCTAssertTrue(weeks.allSatisfy { $0.count == 7 })
        XCTAssertEqual(weeks.first?.first, date(2024, 1, 29))
        XCTAssertEqual(weeks.last?.last, date(2024, 3, 3))
        XCTAssertTrue(weeks.flatMap { $0 }.contains(date(2024, 2, 29)))

        let sixWeekMonth = tokyo.monthWeeks(containing: date(2026, 8, 1))
        XCTAssertEqual(sixWeekMonth.count, 6)
        XCTAssertEqual(sixWeekMonth.last?.last, date(2026, 9, 6))
    }

    func testChangingStartOfWeekKeepsTheDateInAFullWeek() {
        let selection = date(2026, 11, 22)
        let sunday = CalendarDateMath(timeZone: tokyo.calendar.timeZone, firstWeekday: 1)
        XCTAssertEqual(tokyo.week(containing: selection).last, selection)
        XCTAssertEqual(sunday.week(containing: selection).first, selection)
        XCTAssertEqual(sunday.monthWeeks(containing: selection).first?.first, date(2026, 11, 1))
    }

    func testPageNavigationClampsMonthAndCrossesYear() {
        XCTAssertEqual(tokyo.move(date(2024, 1, 31), by: 1, in: .month), date(2024, 2, 29))
        XCTAssertEqual(tokyo.move(date(2025, 1, 31), by: 1, in: .month), date(2025, 2, 28))
        XCTAssertEqual(tokyo.move(date(2026, 12, 31), by: 1, in: .day), date(2027, 1, 1))
        XCTAssertEqual(tokyo.move(date(2026, 12, 31), by: 1, in: .week), date(2027, 1, 7))
        XCTAssertEqual(tokyo.move(date(2027, 1, 31), by: -1, in: .month), date(2026, 12, 31))
    }

    func testDayBoundariesUseTheSpecifiedTimeZone() {
        let dateInTokyo = date(2026, 11, 19, hour: 3)
        let utc = CalendarDateMath(timeZone: TimeZone(secondsFromGMT: 0)!)
        XCTAssertEqual(tokyo.calendar.component(.day, from: dateInTokyo), 19)
        XCTAssertEqual(utc.calendar.component(.day, from: dateInTokyo), 18)
        XCTAssertNotEqual(tokyo.startOfDay(dateInTokyo), utc.startOfDay(dateInTokyo))
    }

    func testMidnightEndDoesNotAppearOnFollowingDay() {
        let event = item("test", date(2026, 11, 19, hour: 23), date(2026, 11, 20))
        XCTAssertTrue(event.overlaps(tokyo.day(containing: date(2026, 11, 19))))
        XCTAssertFalse(event.overlaps(tokyo.day(containing: date(2026, 11, 20))))
        let point = date(2026, 11, 19, hour: 23, minute: 30)
        XCTAssertFalse(event.overlaps(point..<point))
    }

    func testMonthBandContinuesAcrossWeekAndMonthBoundary() throws {
        let trip = item("trip", date(2026, 12, 31), date(2027, 1, 6), allDay: true)
        let weeks = tokyo.monthWeeks(containing: date(2027, 1, 1))
        let first = MonthWeekLayout(days: weeks[0], events: [trip], rowCount: 3, dates: tokyo)
        let next = MonthWeekLayout(days: weeks[1], events: [trip], rowCount: 3, dates: tokyo)
        let firstSegment = try XCTUnwrap(first.entries.first)
        let nextSegment = try XCTUnwrap(next.entries.first)
        XCTAssertTrue(firstSegment.isBand)
        XCTAssertEqual(firstSegment.columns, 3..<7)
        XCTAssertFalse(firstSegment.continuesFromPreviousWeek)
        XCTAssertTrue(firstSegment.continuesIntoNextWeek)
        XCTAssertEqual(nextSegment.columns, 0..<2)
        XCTAssertTrue(nextSegment.continuesFromPreviousWeek)
        XCTAssertFalse(nextSegment.continuesIntoNextWeek)
    }

    func testMonthReportsOverflowOnEachOccupiedDay() {
        let days = tokyo.week(containing: date(2026, 11, 16))
        let long = item("long", days[0], days[4], allDay: true)
        let short = item("short", days[1], days[3], allDay: true)
        let single = item("single", days[2], days[3], allDay: true)
        let layout = MonthWeekLayout(days: days, events: [single, long, short], rowCount: 1, dates: tokyo)
        XCTAssertEqual(layout.entries.map(\.id), ["long"])
        XCTAssertEqual(layout.hiddenCounts, [0, 1, 2, 0, 0, 0, 0])
    }

    func testTimedLayoutClipsToDayAndOnlyOverlapsUseExtraColumns() throws {
        let day = date(2026, 11, 19)
        let overnight = item("overnight", date(2026, 11, 18, hour: 22), date(2026, 11, 19, hour: 2))
        let overlap = item("overlap", date(2026, 11, 19, hour: 1), date(2026, 11, 19, hour: 3))
        let next = item("next", date(2026, 11, 19, hour: 3), date(2026, 11, 19, hour: 4))
        let allDay = item("allDay", day, date(2026, 11, 20), allDay: true)
        let layout = DayTimelineLayout(range: tokyo.day(containing: day), events: [overlap, next, allDay, overnight])
        XCTAssertEqual(layout.entries.map(\.event.id), ["overnight", "overlap", "next"])
        XCTAssertEqual(layout.entries.map(\.column), [0, 1, 0])
        XCTAssertEqual(layout.entries.map(\.columnCount), [2, 2, 1])
        XCTAssertEqual(try XCTUnwrap(layout.entries.first).visibleStart, day)
        XCTAssertEqual(layout.hours.count, 24)
    }

    func testTimelineHas23Or25HoursOnDaylightSavingTransition() {
        let newYork = CalendarDateMath(timeZone: TimeZone(identifier: "America/New_York")!)
        let spring = newYork.day(containing: date(2024, 3, 10, using: newYork))
        let fall = newYork.day(containing: date(2024, 11, 3, using: newYork))
        XCTAssertEqual(DayTimelineLayout(range: spring, events: []).hours.count, 23)
        let repeatedHours = DayTimelineLayout(range: fall, events: []).hours
        XCTAssertEqual(repeatedHours.count, 25)
        XCTAssertEqual(repeatedHours.filter { newYork.calendar.component(.hour, from: $0) == 1 }.count, 2)
    }

    func testMockSourceProducesSamplesWithoutLeakingOutsideRequestedRange() {
        let anchor = date(2026, 11, 19)
        let source = MockCalendarEventSource(anchor: anchor, dates: tokyo)
        let today = source.events(in: tokyo.day(containing: anchor))
        XCTAssertTrue(today.contains { $0.isAllDay })
        XCTAssertTrue(today.contains { !$0.isAllDay })
        XCTAssertTrue(today.allSatisfy { $0.overlaps(tokyo.day(containing: anchor)) })
        XCTAssertTrue(source.events(in: tokyo.day(containing: date(2026, 11, 23))).contains { $0.calendar.isHoliday })
        XCTAssertTrue(source.events(in: tokyo.day(containing: date(2030, 1, 1))).isEmpty)
    }

    private func date(
        _ year: Int, _ month: Int, _ day: Int, hour: Int = 0, minute: Int = 0,
        using dates: CalendarDateMath? = nil
    ) -> Date {
        (dates ?? tokyo).calendar.date(from: DateComponents(year: year, month: month, day: day,
                                                            hour: hour, minute: minute))!
    }

    private func item(_ id: String, _ start: Date, _ end: Date, allDay: Bool = false) -> CalendarEvent {
        CalendarEvent(id: id, title: id, start: start, end: end, isAllDay: allDay,
                      calendar: CalendarLabel(name: "テスト", tint: .indigo))
    }
}
