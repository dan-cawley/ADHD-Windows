import Foundation

enum GameplayEngineRegressionTests {
    static func run() -> [String] {
        var failures: [String] = []
        let calendar = Calendar(identifier: .gregorian)

        func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
            if !condition() {
                failures.append(message)
            }
        }

        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"

        func date(_ value: String) -> Date {
            formatter.date(from: value)!
        }

        func allDayKeys(
            in component: Calendar.Component,
            containing value: Date
        ) -> [String] {
            guard let interval = calendar.dateInterval(of: component, for: value) else {
                return []
            }
            var keys: [String] = []
            var cursor = calendar.startOfDay(for: interval.start)
            while cursor < interval.end {
                keys.append(formatter.string(from: cursor))
                guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else {
                    break
                }
                cursor = next
            }
            return keys
        }

        func lastDay(
            in component: Calendar.Component,
            containing value: Date
        ) -> Date {
            let interval = calendar.dateInterval(of: component, for: value)!
            return calendar.date(byAdding: .day, value: -1, to: interval.end)!
        }

        expect(GameplayEngine.nextStreakRewardAt(totalCompletions: 0) == 6, "Reward cadence should start at 6.")
        expect(GameplayEngine.nextStreakRewardAt(totalCompletions: 6) == 12, "Reward cadence should advance by 6.")

        expect(
            GameplayEngine.streakWasCompletedInCurrentCadence(
                date("2026-03-15"),
                rule: .daily,
                now: date("2026-03-15"),
                calendar: calendar
            ),
            "Daily cadence should treat same day as already completed."
        )

        expect(
            GameplayEngine.streakContinues(
                from: date("2026-03-14"),
                rule: .daily,
                now: date("2026-03-15"),
                calendar: calendar
            ),
            "Daily cadence should continue from the previous day."
        )

        expect(
            GameplayEngine.streakContinues(
                from: date("2026-03-08"),
                rule: .weekly,
                now: date("2026-03-15"),
                calendar: calendar
            ),
            "Weekly cadence should continue from the previous week."
        )

        expect(
            GameplayEngine.streakContinues(
                from: date("2026-02-15"),
                rule: .monthly,
                now: date("2026-03-15"),
                calendar: calendar
            ),
            "Monthly cadence should continue from the previous month."
        )

        expect(GameplayEngine.streakEggMilestoneReached(currentStreak: 21, rule: .daily), "Daily egg milestone should trigger at 21.")
        expect(GameplayEngine.streakEggMilestoneReached(currentStreak: 8, rule: .weekly), "Weekly egg milestone should trigger at 8.")
        expect(GameplayEngine.streakEggMilestoneReached(currentStreak: 4, rule: .monthly), "Monthly egg milestone should trigger at 4.")

        let completedWeekDate = date("2026-03-15")
        let completeWeek = Set(allDayKeys(in: .weekOfYear, containing: completedWeekDate))
        expect(
            GameplayEngine.consistencyStreakAchieved(
                rule: .weekly,
                on: completedWeekDate,
                completedDayKeys: completeWeek,
                calendar: calendar,
                dayKey: { formatter.string(from: $0) }
            ),
            "Weekly consistency streak should require every day of the completed week."
        )

        let incompleteWeek = Set(completeWeek.dropFirst())
        expect(
            !GameplayEngine.consistencyStreakAchieved(
                rule: .weekly,
                on: completedWeekDate,
                completedDayKeys: incompleteWeek,
                calendar: calendar,
                dayKey: { formatter.string(from: $0) }
            ),
            "Weekly consistency streak should fail when a day is missing."
        )

        let completedMonthDate = lastDay(in: .month, containing: date("2026-03-15"))
        let completeMonth = Set(allDayKeys(in: .month, containing: completedMonthDate))
        expect(
            GameplayEngine.consistencyStreakAchieved(
                rule: .monthly,
                on: completedMonthDate,
                completedDayKeys: completeMonth,
                calendar: calendar,
                dayKey: { formatter.string(from: $0) }
            ),
            "Monthly consistency streak should require every day of the completed month."
        )

        expect(
            !GameplayEngine.consistencyStreakAchieved(
                rule: .monthly,
                on: date("2026-03-30"),
                completedDayKeys: completeMonth,
                calendar: calendar,
                dayKey: { formatter.string(from: $0) }
            ),
            "Monthly consistency streak should not trigger before the month is complete."
        )

        return failures
    }
}
