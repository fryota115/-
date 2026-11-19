import Foundation

public enum CalendarPage: String, CaseIterable, Hashable {
    case day
    case week
    case month
}

public struct CalendarDateMath {
    public let calendar: Calendar

    public init(timeZone: TimeZone = .current, firstWeekday: Int = 2) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "ja_JP")
        calendar.timeZone = timeZone
        calendar.firstWeekday = firstWeekday
        self.calendar = calendar
    }

    public func startOfDay(_ date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    public func addingDays(_ count: Int, to date: Date) -> Date {
        startOfDay(calendar.date(byAdding: .day, value: count, to: startOfDay(date)) ?? date)
    }

    public func day(containing date: Date) -> Range<Date> {
        startOfDay(date)..<addingDays(1, to: date)
    }

    public func startOfWeek(_ date: Date) -> Date {
        let offset = (calendar.component(.weekday, from: date) - calendar.firstWeekday + 7) % 7
        return addingDays(-offset, to: date)
    }

    public func week(containing date: Date) -> [Date] {
        let start = startOfWeek(date)
        return (0..<7).map { addingDays($0, to: start) }
    }

    public func monthWeeks(containing date: Date) -> [[Date]] {
        guard let month = calendar.dateInterval(of: .month, for: date) else { return [] }
        var start = startOfWeek(month.start)
        var weeks: [[Date]] = []
        while start < month.end {
            weeks.append((0..<7).map { addingDays($0, to: start) })
            let next = addingDays(7, to: start)
            guard next > start else { break }
            start = next
        }
        return weeks
    }

    public func move(_ date: Date, by pages: Int, in page: CalendarPage) -> Date {
        switch page {
        case .day:
            return addingDays(pages, to: date)
        case .week:
            return addingDays(pages * 7, to: date)
        case .month:
            guard let source = calendar.dateInterval(of: .month, for: date),
                  let next = calendar.date(byAdding: .month, value: pages, to: source.start),
                  let days = calendar.range(of: .day, in: .month, for: next) else {
                return startOfDay(date)
            }
            let dayNumber = min(calendar.component(.day, from: date), days.count)
            return addingDays(dayNumber - 1, to: next)
        }
    }
}
