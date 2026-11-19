import Foundation

public struct MockCalendarEventSource: CalendarEventSource {
    private static let work = CalendarLabel(name: "仕事", tint: .indigo)
    private static let personal = CalendarLabel(name: "自分", tint: .pine)
    private static let family = CalendarLabel(name: "家族", tint: .ochre)
    private static let outings = CalendarLabel(name: "おでかけ", tint: .plum)
    private static let holidays = CalendarLabel(name: "祝日（サンプル）", tint: .red, isHoliday: true)

    private let entries: [CalendarEvent]

    public init(anchor: Date = .now, dates: CalendarDateMath = CalendarDateMath()) {
        var events: [CalendarEvent] = []
        let today = dates.startOfDay(anchor)
        let calendar = dates.calendar

        func addTimed(
            _ title: String, day: Date, hour: Int, minute: Int = 0, duration: Int,
            calendar label: CalendarLabel, location: String = "", notes: String = ""
        ) {
            guard let start = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day),
                  let end = calendar.date(byAdding: .minute, value: duration, to: start) else { return }
            events.append(CalendarEvent(
                id: "mock-\(events.count)", title: title, start: start, end: end,
                isAllDay: false, calendar: label, location: location, notes: notes
            ))
        }

        func addAllDay(_ title: String, start: Date, days: Int, calendar label: CalendarLabel) {
            events.append(CalendarEvent(
                id: "mock-\(events.count)", title: title, start: start, end: dates.addingDays(days, to: start),
                isAllDay: true, calendar: label
            ))
        }

        for offset in -48...48 {
            let day = dates.addingDays(offset, to: today)
            switch calendar.component(.weekday, from: day) {
            case 2:
                addTimed("週初めの打ち合わせ", day: day, hour: 9, duration: 45, calendar: Self.work)
            case 3:
                addTimed("資料レビュー", day: day, hour: 14, duration: 60, calendar: Self.work)
                addTimed("夕方の散歩", day: day, hour: 17, minute: 30, duration: 45, calendar: Self.personal)
            case 4:
                addTimed("ランチ", day: day, hour: 12, duration: 60, calendar: Self.personal)
            case 5:
                addTimed("定例ミーティング", day: day, hour: 10, duration: 60, calendar: Self.work)
            case 6:
                addTimed("週次の振り返り", day: day, hour: 16, duration: 45, calendar: Self.work)
            case 7 where offset.isMultiple(of: 2):
                addTimed("図書館に寄る", day: day, hour: 11, duration: 75, calendar: Self.outings)
            case 1 where offset.isMultiple(of: 2):
                addTimed("家族と夕食", day: day, hour: 18, duration: 90, calendar: Self.family)
            default:
                break
            }
        }

        addAllDay("読書の記録", start: today, days: 1, calendar: Self.personal)
        addTimed("手帖を整理する", day: today, hour: 10, minute: 30, duration: 60,
                 calendar: Self.personal, notes: "今週の予定と持ち物を確認する。")
        addTimed("買い物", day: today, hour: 18, duration: 45, calendar: Self.family, location: "駅前")

        if let month = calendar.dateInterval(of: .month, for: today) {
            addAllDay("小旅行", start: dates.addingDays(9, to: month.start), days: 4, calendar: Self.outings)
            addAllDay("展示会", start: dates.addingDays(10, to: month.start), days: 3, calendar: Self.work)
            addAllDay("帰省", start: dates.addingDays(-2, to: month.end), days: 4, calendar: Self.family)
        }

        let year = calendar.component(.year, from: today)
        let sampleHolidays = [(1, 1, "元日"), (5, 3, "憲法記念日"), (5, 5, "こどもの日"),
                              (11, 3, "文化の日"), (11, 23, "勤労感謝の日")]
        for (month, day, name) in sampleHolidays {
            if let date = calendar.date(from: DateComponents(year: year, month: month, day: day)) {
                addAllDay(name, start: dates.startOfDay(date), days: 1, calendar: Self.holidays)
            }
        }

        entries = events
    }

    public func events(in range: Range<Date>) -> [CalendarEvent] {
        entries.filter { $0.overlaps(range) }
    }
}
