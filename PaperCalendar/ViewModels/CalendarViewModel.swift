import CalendarCore
import Foundation
import Observation

enum PlannerTab: String, CaseIterable, Identifiable, Hashable {
    case day = "日"
    case week = "週"
    case month = "月"
    case tasks = "タスク"
    case more = "その他"

    var id: Self { self }

    var page: CalendarPage? {
        switch self {
        case .day: return .day
        case .week: return .week
        case .month: return .month
        case .tasks, .more: return nil
        }
    }

    var symbol: String {
        switch self {
        case .day: return "clock"
        case .week: return "list.bullet.rectangle"
        case .month: return "calendar"
        case .tasks: return "checklist"
        case .more: return "ellipsis"
        }
    }
}

enum PlannerSheet: Identifiable {
    case dateJump
    case event(CalendarEvent)
    case add(Date)

    var id: String {
        switch self {
        case .dateJump: return "dateJump"
        case .event(let event): return "event-\(event.id)"
        case .add: return "add"
        }
    }
}

@Observable
@MainActor
final class CalendarViewModel {
    private(set) var tab: PlannerTab = .month
    private(set) var selectedDate: Date
    private(set) var today: Date
    private(set) var dates: CalendarDateMath
    var sheet: PlannerSheet?

    private var lastCalendarTab: PlannerTab = .month
    private var source: any CalendarEventSource
    private let makeSource: (Date, CalendarDateMath) -> any CalendarEventSource

    init(
        now: Date = .now,
        dates: CalendarDateMath = CalendarDateMath(),
        makeSource: @escaping (Date, CalendarDateMath) -> any CalendarEventSource
    ) {
        let currentDay = dates.startOfDay(now)
        self.dates = dates
        self.makeSource = makeSource
        today = currentDay
        selectedDate = currentDay
        source = makeSource(now, dates)
    }

    var visibleWeeks: [[Date]] {
        switch tab.page {
        case .month: return dates.monthWeeks(containing: selectedDate)
        case .week: return [dates.week(containing: selectedDate)]
        case .day: return [[selectedDate]]
        case nil: return []
        }
    }

    var visibleEvents: [CalendarEvent] {
        let weeks = visibleWeeks
        guard let first = weeks.first?.first, let last = weeks.last?.last else { return [] }
        return source.events(in: first..<dates.addingDays(1, to: last)).sorted(by: CalendarEvent.ordered)
    }

    func selectTab(_ requested: PlannerTab) {
        if requested == tab, requested.page != nil {
            goToToday()
        }
        tab = requested
        if requested.page != nil { lastCalendarTab = requested }
    }

    func select(_ date: Date) {
        selectedDate = dates.startOfDay(date)
    }

    func step(by direction: Int) {
        guard let page = tab.page else { return }
        selectedDate = dates.move(selectedDate, by: direction, in: page)
    }

    func goToToday() {
        updateClock()
        jump(to: today)
    }

    func jump(to date: Date) {
        select(date)
        if tab.page == nil { tab = lastCalendarTab }
    }

    func setFirstWeekday(_ weekday: Int) {
        guard dates.calendar.firstWeekday != weekday else { return }
        dates = CalendarDateMath(timeZone: dates.calendar.timeZone, firstWeekday: weekday)
    }

    func updateClock(now: Date = .now, timeZone: TimeZone = .current) {
        let wasToday = selectedDate == today
        let zoneChanged = dates.calendar.timeZone != timeZone
        if zoneChanged {
            let localDate = dates.calendar.dateComponents([.year, .month, .day], from: selectedDate)
            dates = CalendarDateMath(timeZone: timeZone, firstWeekday: dates.calendar.firstWeekday)
            select(dates.calendar.date(from: localDate) ?? selectedDate)
        }
        let currentDay = dates.startOfDay(now)
        guard zoneChanged || currentDay != today else { return }
        today = currentDay
        if wasToday { selectedDate = today }
        source = makeSource(now, dates)
    }
}
