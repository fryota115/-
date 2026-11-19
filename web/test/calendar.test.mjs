import assert from "node:assert/strict";
import test from "node:test";
import { eventsOn, monthWeeks, move, plusDays, seed, validEvent, weekDays, weekLayout } from "../dist/calendar.mjs";

const item = (id, startDate, endDate, allDay = true, endTime = "00:00") =>
  ({ id, title: id, calendar: "personal", startDate, endDate, allDay, startTime: "22:00", endTime });

test("leap day, month clamp, and December rollover", () => {
  assert.equal(move("2024-01-31", 1, "month"), "2024-02-29");
  assert.equal(move("2025-01-31", 1, "month"), "2025-02-28");
  assert.equal(move("2026-12-31", 1, "day"), "2027-01-01");
  assert.equal(move("2026-12-31", 1, "week"), "2027-01-07");
  assert.equal(plusDays("2024-03-09", 2), "2024-03-11");
});

test("week starts and month grid boundaries", () => {
  assert.equal(weekDays("2026-11-22", 1).at(-1), "2026-11-22");
  assert.equal(weekDays("2026-11-22", 0)[0], "2026-11-22");
  assert.equal(monthWeeks("2026-08-01", 1).length, 6);
  assert.equal(monthWeeks("2026-08-01", 1).at(-1).at(-1), "2026-09-06");
});

test("timed midnight excludes the next day; all-day end is included", () => {
  const timed = item("late", "2026-11-19", "2026-11-20", false);
  const allDay = item("trip", "2026-11-19", "2026-11-20");
  assert.equal(eventsOn([timed], "2026-11-19").length, 1);
  assert.equal(eventsOn([timed], "2026-11-20").length, 0);
  assert.equal(eventsOn([allDay], "2026-11-20").length, 1);
});

test("multi-day events span rows and report crowded cells", () => {
  const days = weekDays("2026-11-18", 1);
  const trip = item("trip", "2026-11-15", "2026-11-19");
  const other = item("other", "2026-11-18", "2026-11-18");
  const result = weekLayout(days, [other, trip], 1);
  assert.equal(result.entries[0].event.id, "trip");
  assert.equal(result.entries[0].firstColumn, 0);
  assert.equal(result.entries[0].lastColumn, 3);
  assert.equal(result.overflow[2], 1);
});

test("editor validation handles bad dates, times, and calendar identifiers", () => {
  const day = item("valid", "2024-02-29", "2024-02-29", false, "23:00");
  assert.equal(validEvent(day), true);
  assert.equal(validEvent({ ...day, endDate: "2024-02-30" }), false);
  assert.equal(validEvent({ ...day, endTime: "21:30" }), false);
  assert.equal(validEvent({ ...day, calendar: "__proto__" }), false);
  assert.equal(validEvent({ ...day, title: " " }), false);
});

test("the starter events are valid and marked as samples", () => {
  const { events } = seed("2026-11-19");
  assert.ok(eventsOn(events, "2026-11-19").length >= 3);
  assert.ok(events.every((event) => event.sample && validEvent(event)));
});
