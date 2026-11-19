import Foundation

public enum CalendarTint: Hashable {
    case indigo
    case pine
    case ochre
    case plum
    case red
}

public struct CalendarLabel: Hashable {
    public let name: String
    public let tint: CalendarTint
    public let isHoliday: Bool

    public init(name: String, tint: CalendarTint, isHoliday: Bool = false) {
        self.name = name
        self.tint = tint
        self.isHoliday = isHoliday
    }
}

public struct CalendarEvent: Identifiable, Hashable {
    public let id: String
    public let title: String
    public let start: Date
    public let end: Date
    public let isAllDay: Bool
    public let calendar: CalendarLabel
    public let location: String
    public let notes: String

    public init(
        id: String, title: String, start: Date, end: Date, isAllDay: Bool,
        calendar: CalendarLabel, location: String = "", notes: String = ""
    ) {
        self.id = id
        self.title = title
        self.start = start
        self.end = end
        self.isAllDay = isAllDay
        self.calendar = calendar
        self.location = location
        self.notes = notes
    }

    public func overlaps(_ range: Range<Date>) -> Bool {
        !range.isEmpty && start < end && start < range.upperBound && end > range.lowerBound
    }

    public static func ordered(_ lhs: Self, _ rhs: Self) -> Bool {
        if lhs.isAllDay != rhs.isAllDay { return lhs.isAllDay }
        if lhs.start != rhs.start { return lhs.start < rhs.start }
        if lhs.end != rhs.end { return lhs.end > rhs.end }
        return lhs.id < rhs.id
    }
}

public protocol CalendarEventSource {
    func events(in range: Range<Date>) -> [CalendarEvent]
}
