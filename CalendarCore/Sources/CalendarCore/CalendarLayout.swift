import Foundation

public struct MonthEntry: Identifiable {
    public let event: CalendarEvent
    public let columns: Range<Int>
    public let row: Int
    public let isBand: Bool
    public let continuesFromPreviousWeek: Bool
    public let continuesIntoNextWeek: Bool

    public var id: String { event.id }
}

public struct MonthWeekLayout {
    public let entries: [MonthEntry]
    public let hiddenCounts: [Int]

    public init(days: [Date], events: [CalendarEvent], rowCount: Int, dates: CalendarDateMath) {
        var slots = Array(repeating: Array(repeating: false, count: days.count), count: max(0, rowCount))
        var hidden = Array(repeating: 0, count: days.count)
        var placed: [MonthEntry] = []
        guard let start = days.first, let last = days.last else {
            entries = []
            hiddenCounts = hidden
            return
        }
        let end = dates.addingDays(1, to: last)
        let dayRanges = days.map { dates.day(containing: $0) }
        let visible = events.filter { $0.overlaps(start..<end) }.sorted(by: CalendarEvent.ordered)
        let bands = visible.filter { $0.end > dates.day(containing: $0.start).upperBound }
        let bandIDs = Set(bands.map(\.id))
        let singleDayEvents = visible.filter { !bandIDs.contains($0.id) }

        for event in bands + singleDayEvents {
            let occupied = dayRanges.indices.filter { event.overlaps(dayRanges[$0]) }
            guard let first = occupied.first, let last = occupied.last else { continue }
            let columns = first..<(last + 1)
            guard let row = slots.indices.first(where: { row in
                columns.allSatisfy { !slots[row][$0] }
            }) else {
                for column in columns { hidden[column] += 1 }
                continue
            }
            for column in columns { slots[row][column] = true }
            placed.append(MonthEntry(
                event: event, columns: columns, row: row, isBand: bandIDs.contains(event.id),
                continuesFromPreviousWeek: event.start < start, continuesIntoNextWeek: event.end > end
            ))
        }
        entries = placed
        hiddenCounts = hidden
    }
}

public struct TimedEntry: Identifiable {
    public let event: CalendarEvent
    public let visibleStart: Date
    public let visibleEnd: Date
    public let column: Int
    public let columnCount: Int

    public var id: String { event.id }
}

public struct DayTimelineLayout {
    public let range: Range<Date>
    public let entries: [TimedEntry]

    public var hours: [Date] {
        guard !range.isEmpty else { return [] }
        return Array(sequence(first: range.lowerBound) { date in
            let next = date.addingTimeInterval(3600)
            return next < range.upperBound ? next : nil
        })
    }

    public init(range: Range<Date>, events: [CalendarEvent]) {
        self.range = range
        let timedEvents = events.filter { !$0.isAllDay && $0.overlaps(range) }.sorted(by: CalendarEvent.ordered)
        var placements: [TimedEntry] = []
        var cluster: [(event: CalendarEvent, start: Date, end: Date, column: Int)] = []
        var columnEnds: [Date] = []

        func finishCluster() {
            placements += cluster.map {
                TimedEntry(event: $0.event, visibleStart: $0.start, visibleEnd: $0.end,
                           column: $0.column, columnCount: columnEnds.count)
            }
            cluster.removeAll()
            columnEnds.removeAll()
        }

        for event in timedEvents {
            let start = max(event.start, range.lowerBound)
            let end = min(event.end, range.upperBound)
            if let lastEnd = columnEnds.max(), lastEnd <= start {
                finishCluster()
            }
            let column: Int
            if let reusable = columnEnds.firstIndex(where: { $0 <= start }) {
                column = reusable
                columnEnds[column] = end
            } else {
                column = columnEnds.count
                columnEnds.append(end)
            }
            cluster.append((event, start, end, column))
        }
        finishCluster()
        entries = placements
    }
}
