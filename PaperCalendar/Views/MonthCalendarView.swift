import CalendarCore
import SwiftUI

struct MonthCalendarView: View {
    let weeks: [[Date]]
    let selection: Date
    let today: Date
    let dates: CalendarDateMath
    let events: [CalendarEvent]
    let textSize: EventTextSize
    let onSelect: (Date) -> Void
    let onEvent: (CalendarEvent) -> Void

    private let visibleRows = 3
    private let gridInset: CGFloat = 8
    @ScaledMetric(relativeTo: .caption) private var dateHeight: CGFloat = 30
    @ScaledMetric(relativeTo: .caption2) private var baseRowHeight: CGFloat = 15
    @ScaledMetric(relativeTo: .caption2) private var baseEventSize: CGFloat = 10

    private var rowHeight: CGFloat { baseRowHeight * textSize.factor }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                if let firstWeek = weeks.first {
                    weekdayHeader(firstWeek)
                    ForEach(weeks, id: \.self) { days in
                        weekRow(days)
                    }
                    Rectangle().fill(PlannerStyle.rule).frame(height: 1)
                }
                selectedAgenda
            }
            .padding(.horizontal, gridInset)
        }
        .id(weeks.first?.first)
        .accessibilityIdentifier("calendar.month")
    }

    private func weekdayHeader(_ days: [Date]) -> some View {
        HStack(spacing: 0) {
            ForEach(days, id: \.self) { date in
                let weekday = dates.calendar.component(.weekday, from: date)
                Text(PlannerDateText.weekdays[weekday - 1])
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(PlannerStyle.dayInk(weekday: weekday))
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 6)
        .background(PlannerStyle.margin)
        .accessibilityHidden(true)
    }

    private func weekRow(_ days: [Date]) -> some View {
        let layout = MonthWeekLayout(days: days, events: events, rowCount: visibleRows, dates: dates)
        let height = dateHeight + rowHeight * CGFloat(visibleRows) + baseRowHeight + 4
        return GeometryReader { geometry in
            let columnWidth = geometry.size.width / CGFloat(days.count)
            ZStack(alignment: .topLeading) {
                HStack(spacing: 0) {
                    ForEach(days.indices, id: \.self) { index in
                        dayCell(days[index], hidden: layout.hiddenCounts[index])
                            .frame(width: columnWidth)
                    }
                }
                ForEach(layout.entries) { entry in
                    let start = columnWidth * CGFloat(entry.columns.lowerBound)
                    let leading: CGFloat = entry.continuesFromPreviousWeek ? 0 : 2
                    let trailing: CGFloat = entry.continuesIntoNextWeek ? 0 : 2
                    let width = max(0, CGFloat(entry.columns.count) * columnWidth - leading - trailing)
                    eventEntry(entry)
                        .frame(width: width, height: max(1, rowHeight - 1))
                        .position(x: start + leading + width / 2,
                                  y: dateHeight + rowHeight * (CGFloat(entry.row) + 0.5))
                }
            }
            .overlay(alignment: .top) {
                Rectangle().fill(PlannerStyle.rule).frame(height: 1).allowsHitTesting(false)
            }
        }
        .frame(height: height)
    }

    private func dayCell(_ day: Date, hidden: Int) -> some View {
        let calendar = dates.calendar
        let isSelected = day == selection
        let isToday = day == today
        let inMonth = calendar.isDate(day, equalTo: selection, toGranularity: .month)
        let weekday = calendar.component(.weekday, from: day)
        let holidays = events.filter { $0.calendar.isHoliday && $0.overlaps(dates.day(containing: day)) }
        let ink = PlannerStyle.dayInk(weekday: weekday, holiday: !holidays.isEmpty)
        return Button { onSelect(day) } label: {
            VStack(spacing: 0) {
                DateNumber(value: calendar.component(.day, from: day), isToday: isToday, ink: ink)
                    .font(.caption)
                    .opacity(inMonth ? 1 : 0.65)
                    .frame(maxWidth: .infinity, minHeight: dateHeight)
                Spacer(minLength: 0)
                if hidden > 0 {
                    Text("+\(hidden)")
                        .font(.caption2.monospacedDigit())
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .foregroundStyle(PlannerStyle.secondaryInk)
                        .padding(.bottom, 2)
                }
            }
            .frame(maxHeight: .infinity)
            .background(isSelected ? PlannerStyle.selection : (inMonth ? PlannerStyle.paper : PlannerStyle.margin))
            .overlay(alignment: .trailing) {
                Rectangle().fill(PlannerStyle.rule).frame(width: 1)
            }
            .overlay {
                if isSelected {
                    Rectangle().strokeBorder(PlannerStyle.blue.opacity(0.75), lineWidth: 1)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(PlannerDateText.fullDate(day, calendar: calendar)))
        .accessibilityValue(Text(
            ([isToday ? "今日" : "", hidden > 0 ? "ほか\(hidden)件" : ""] + holidays.map(\.title))
                .filter { !$0.isEmpty }.joined(separator: "、")
        ))
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private func eventEntry(_ entry: MonthEntry) -> some View {
        let ink = PlannerStyle.eventInk(entry.event.calendar.tint)
        return Button { onEvent(entry.event) } label: {
            HStack(spacing: 2) {
                if entry.continuesFromPreviousWeek {
                    Image(systemName: "chevron.left").accessibilityHidden(true)
                }
                Text(entry.event.title)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if entry.continuesIntoNextWeek {
                    Image(systemName: "chevron.right").accessibilityHidden(true)
                }
            }
            .font(.system(size: baseEventSize * textSize.factor, weight: .medium))
            .foregroundStyle(ink)
            .padding(.horizontal, 2)
            .frame(maxHeight: .infinity)
            .background(entry.isBand ? ink.opacity(0.14) : .clear)
            .clipped()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("\(entry.event.title)、\(entry.event.calendar.name)"))
    }

    private var selectedAgenda: some View {
        let dayEvents = events.filter { $0.overlaps(dates.day(containing: selection)) }
        return VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(PlannerDateText.day(selection, calendar: dates.calendar))
                    .font(.subheadline.weight(.semibold))
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Text("\(dayEvents.count)件").font(.caption).foregroundStyle(PlannerStyle.secondaryInk)
            }
            .padding(.vertical, 8)
            if dayEvents.isEmpty {
                Text("予定なし")
                    .font(.footnote)
                    .foregroundStyle(PlannerStyle.secondaryInk)
                    .padding(.vertical, 6)
            }
            ForEach(dayEvents) { event in
                Divider()
                AgendaRow(event: event, date: selection, calendar: dates.calendar, textSize: textSize) {
                    onEvent(event)
                }
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
    }
}
