import CalendarCore
import SwiftUI

struct DayCalendarView: View {
    let date: Date
    let today: Date
    let dates: CalendarDateMath
    let events: [CalendarEvent]
    let textSize: EventTextSize
    let onEvent: (CalendarEvent) -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .subheadline) private var baseHourHeight: CGFloat = 54
    @ScaledMetric(relativeTo: .caption2) private var timeWidth: CGFloat = 44
    @ScaledMetric(relativeTo: .subheadline) private var titleSize: CGFloat = 13

    private var hourHeight: CGFloat { baseHourHeight * textSize.factor }
    private var dayLayout: DayTimelineLayout { DayTimelineLayout(range: dates.day(containing: date), events: events) }
    private var allDayEvents: [CalendarEvent] { events.filter(\.isAllDay) }
    private var keepAllDayVisible: Bool { !dynamicTypeSize.isAccessibilitySize && allDayEvents.count <= 2 }

    var body: some View {
        VStack(spacing: 0) {
            if date == today {
                HStack {
                    Text("今日")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(PlannerStyle.blue)
                    Spacer()
                }
                .padding(.horizontal, PlannerStyle.pageInset)
                .padding(.vertical, 4)
                .background(PlannerStyle.selection)
            }
            if keepAllDayVisible {
                allDay.padding(.horizontal, PlannerStyle.pageInset)
            }
            ScrollViewReader { scroll in
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        if !keepAllDayVisible { allDay }
                        if dynamicTypeSize.isAccessibilitySize {
                            accessibleSchedule
                        } else {
                            timeline(dayLayout)
                        }
                    }
                    .padding(.horizontal, PlannerStyle.pageInset)
                }
                .task(id: date) {
                    guard keepAllDayVisible else { return }
                    await Task.yield()
                    guard !Task.isCancelled else { return }
                    let start = dayLayout.entries.first?.visibleStart
                    let hour = start.map { dates.calendar.component(.hour, from: $0) } ?? 7
                    let firstHour = dayLayout.hours.first { dates.calendar.component(.hour, from: $0) >= min(hour, 7) }
                    if let firstHour {
                        scroll.scrollTo(firstHour, anchor: .top)
                    }
                }
            }
            .id(date)
        }
        .accessibilityIdentifier("calendar.day")
    }

    private var allDay: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("終日")
                .font(.caption.weight(.semibold))
                .foregroundStyle(PlannerStyle.secondaryInk)
                .accessibilityAddTraits(.isHeader)
            if allDayEvents.isEmpty {
                Text("予定なし")
                    .font(.caption2)
                    .foregroundStyle(PlannerStyle.secondaryInk)
                    .padding(.top, 4)
            }
            ForEach(allDayEvents) { event in
                AgendaRow(event: event, date: date, calendar: dates.calendar, textSize: textSize) {
                    onEvent(event)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 7)
    }

    private var accessibleSchedule: some View {
        let timed = events.filter { !$0.isAllDay }
        return VStack(alignment: .leading, spacing: 0) {
            Divider()
            Text("時間指定")
                .font(.caption.weight(.semibold))
                .padding(.vertical, 7)
                .accessibilityAddTraits(.isHeader)
            if timed.isEmpty {
                Text("予定なし").font(.footnote).padding(.bottom, 8)
            }
            ForEach(timed) { event in
                AgendaRow(event: event, date: date, calendar: dates.calendar, textSize: textSize) {
                    onEvent(event)
                }
            }
        }
    }

    private func timeline(_ layout: DayTimelineLayout) -> some View {
        let height = offset(at: layout.range.upperBound, from: layout.range.lowerBound)
        return GeometryReader { geometry in
            let eventArea = max(0, geometry.size.width - timeWidth)
            ZStack(alignment: .topLeading) {
                VStack(spacing: 0) {
                    ForEach(layout.hours, id: \.self) { hour in
                        let remaining = height - offset(at: hour, from: layout.range.lowerBound)
                        hourRule(hour)
                            .frame(height: min(hourHeight, remaining), alignment: .top)
                            .id(hour)
                    }
                }
                ForEach(layout.entries) { entry in
                    let columnWidth = eventArea / CGFloat(entry.columnCount)
                    let width = max(0, columnWidth - 2)
                    let top = offset(at: entry.visibleStart, from: layout.range.lowerBound)
                    let bottom = offset(at: entry.visibleEnd, from: layout.range.lowerBound)
                    let entryHeight = max(1, bottom - top)
                    timedBlock(entry.event, compact: entryHeight < titleSize * textSize.factor * 2.6)
                        .frame(width: width, height: entryHeight)
                        .position(x: timeWidth + CGFloat(entry.column) * columnWidth + width / 2,
                                  y: top + entryHeight / 2)
                }
            }
        }
        .frame(height: height)
        .overlay(alignment: .bottom) {
            Rectangle().fill(PlannerStyle.rule).frame(height: 1).allowsHitTesting(false)
        }
    }

    private func hourRule(_ hour: Date) -> some View {
        HStack(alignment: .top, spacing: 0) {
            Text(PlannerDateText.time(hour, calendar: dates.calendar))
                .font(.caption2.monospacedDigit())
                .foregroundStyle(PlannerStyle.secondaryInk)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(width: timeWidth - 5, alignment: .trailing)
                .padding(.trailing, 5)
            Rectangle().fill(PlannerStyle.rule).frame(height: 1)
        }
        .accessibilityHidden(true)
    }

    private func timedBlock(_ event: CalendarEvent, compact: Bool) -> some View {
        let ink = PlannerStyle.eventInk(event.calendar.tint)
        let range = "\(PlannerDateText.time(event.start, calendar: dates.calendar))–\(PlannerDateText.time(event.end, calendar: dates.calendar))"
        return Button { onEvent(event) } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.system(size: titleSize * textSize.factor, weight: .semibold))
                    .lineLimit(1)
                if !compact {
                    Text(range).font(.caption2.monospacedDigit()).lineLimit(1)
                }
            }
            .padding(.horizontal, 6)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .foregroundStyle(ink)
            .background(ink.opacity(0.12))
            .overlay(alignment: .leading) {
                Rectangle().fill(ink).frame(width: 3)
            }
            .clipped()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("\(event.title)、\(range)、\(event.calendar.name)"))
    }

    private func offset(at date: Date, from start: Date) -> CGFloat {
        CGFloat(date.timeIntervalSince(start) / 3600) * hourHeight
    }
}
