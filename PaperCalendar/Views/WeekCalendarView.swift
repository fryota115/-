import CalendarCore
import SwiftUI

struct WeekCalendarView: View {
    let days: [Date]
    let selection: Date
    let today: Date
    let dates: CalendarDateMath
    let events: [CalendarEvent]
    let textSize: EventTextSize
    let onSelect: (Date) -> Void
    let onEvent: (CalendarEvent) -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .subheadline) private var dateWidth: CGFloat = 66

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(days, id: \.self) { day in
                    dayRow(day)
                    Divider()
                }
            }
            .padding(.horizontal, PlannerStyle.pageInset)
        }
        .id(days.first)
        .accessibilityIdentifier("calendar.week")
    }

    private func dayRow(_ day: Date) -> some View {
        let dayEvents = events.filter { $0.overlaps(dates.day(containing: day)) }
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 0))
            : AnyLayout(HStackLayout(alignment: .top, spacing: 10))
        return layout {
            dateButton(day, holiday: dayEvents.contains { $0.calendar.isHoliday })
                .frame(width: dynamicTypeSize.isAccessibilitySize ? nil : dateWidth)
            VStack(alignment: .leading, spacing: 0) {
                if dayEvents.isEmpty {
                    Text("予定なし")
                        .font(.footnote)
                        .foregroundStyle(PlannerStyle.secondaryInk)
                        .padding(.vertical, 8)
                }
                ForEach(dayEvents) { event in
                    AgendaRow(event: event, date: day, calendar: dates.calendar, textSize: textSize) {
                        onEvent(event)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 3)
            .padding(.leading, dynamicTypeSize.isAccessibilitySize ? 8 : 0)
        }
        .background(day == selection ? PlannerStyle.selection : Color.clear)
    }

    private func dateButton(_ day: Date, holiday: Bool) -> some View {
        let calendar = dates.calendar
        let weekday = calendar.component(.weekday, from: day)
        let ink = PlannerStyle.dayInk(weekday: weekday, holiday: holiday)
        return Button { onSelect(day) } label: {
            HStack(spacing: 4) {
                DateNumber(value: calendar.component(.day, from: day), isToday: day == today, ink: ink)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 0) {
                    Text("\(calendar.component(.month, from: day))月").font(.caption2)
                    Text(PlannerDateText.weekdays[weekday - 1]).font(.caption2.weight(.semibold))
                }
                .foregroundStyle(ink)
            }
            .padding(.horizontal, 6)
            .frame(maxWidth: .infinity, minHeight: 47, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(PlannerDateText.fullDate(day, calendar: calendar)))
        .accessibilityValue(day == today ? Text("今日") : Text(""))
        .accessibilityAddTraits(day == selection ? [.isSelected] : [])
    }
}
