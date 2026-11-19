import CalendarCore
import Foundation
import SwiftUI

enum PlannerStyle {
    static let paper = Color(red: 0.99, green: 0.99, blue: 0.98)
    static let margin = Color(red: 0.95, green: 0.95, blue: 0.94)
    static let rule = Color(red: 0.84, green: 0.85, blue: 0.83)
    static let ink = Color(red: 0.14, green: 0.17, blue: 0.16)
    static let secondaryInk = Color(red: 0.33, green: 0.36, blue: 0.36)
    static let blue = Color(red: 0.15, green: 0.34, blue: 0.60)
    static let red = Color(red: 0.66, green: 0.19, blue: 0.22)
    static let selection = Color(red: 0.90, green: 0.94, blue: 0.97)
    static let pageInset: CGFloat = 14

    static func dayInk(weekday: Int, holiday: Bool = false) -> Color {
        if holiday || weekday == 1 { return red }
        if weekday == 7 { return blue }
        return ink
    }

    static func eventInk(_ tint: CalendarTint) -> Color {
        switch tint {
        case .indigo: return blue
        case .pine: return Color(red: 0.15, green: 0.39, blue: 0.30)
        case .ochre: return Color(red: 0.52, green: 0.32, blue: 0.12)
        case .plum: return Color(red: 0.48, green: 0.29, blue: 0.55)
        case .red: return red
        }
    }
}

enum EventTextSize: String, CaseIterable, Identifiable, Hashable {
    case small = "小"
    case standard = "標準"
    case large = "大"

    var id: Self { self }

    var factor: CGFloat {
        switch self {
        case .small: return 0.9
        case .standard: return 1
        case .large: return 1.18
        }
    }
}

enum PlannerDateText {
    static let weekdays = ["日", "月", "火", "水", "木", "金", "土"]

    static func month(_ date: Date, calendar: Calendar) -> String {
        "\(calendar.component(.year, from: date))年\(calendar.component(.month, from: date))月"
    }

    static func abbreviated(_ date: Date, calendar: Calendar) -> String {
        "\(calendar.component(.month, from: date))/\(calendar.component(.day, from: date))"
    }

    static func day(_ date: Date, calendar: Calendar) -> String {
        let weekday = weekdays[calendar.component(.weekday, from: date) - 1]
        return "\(calendar.component(.month, from: date))月\(calendar.component(.day, from: date))日（\(weekday)）"
    }

    static func fullDate(_ date: Date, calendar: Calendar) -> String {
        "\(calendar.component(.year, from: date))年\(day(date, calendar: calendar))"
    }

    static func time(_ date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        return String(format: "%02d:%02d", components.hour ?? 0, components.minute ?? 0)
    }
}

struct DateNumber: View {
    let value: Int
    let isToday: Bool
    var ink: Color = PlannerStyle.ink

    var body: some View {
        Text(value, format: .number)
            .fontWeight(isToday ? .bold : .semibold)
            .monospacedDigit()
            .foregroundStyle(ink)
            .padding(.bottom, 3)
            .background(alignment: .bottom) {
                if isToday {
                    Rectangle().fill(PlannerStyle.blue).frame(height: 2)
                }
            }
    }
}

struct AgendaRow: View {
    let event: CalendarEvent
    let date: Date
    let calendar: Calendar
    let textSize: EventTextSize
    let action: () -> Void

    @ScaledMetric(relativeTo: .subheadline) private var titleSize: CGFloat = 14

    private var timeLabel: String {
        if event.isAllDay { return "終日" }
        if event.start < calendar.startOfDay(for: date) { return "継続" }
        return PlannerDateText.time(event.start, calendar: calendar)
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                RoundedRectangle(cornerRadius: 1)
                    .fill(PlannerStyle.eventInk(event.calendar.tint))
                    .frame(width: 3, height: 15)
                    .accessibilityHidden(true)
                Text(timeLabel)
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(PlannerStyle.secondaryInk)
                Text(event.title)
                    .font(.system(size: titleSize * textSize.factor, weight: .medium))
                    .foregroundStyle(PlannerStyle.ink)
                    .lineLimit(2)
                Spacer(minLength: 0)
            }
            .padding(.vertical, 5)
            .frame(minHeight: 32)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(timeLabel)、\(event.title)、\(event.calendar.name)"))
    }
}
