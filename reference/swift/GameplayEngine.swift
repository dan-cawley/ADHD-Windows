import Foundation

enum GameplayEngine {
    static let streakRewardInterval = 6

    static func nextStreakRewardAt(totalCompletions: Int) -> Int {
        ((totalCompletions / streakRewardInterval) + 1) * streakRewardInterval
    }

    static func isAutomaticConsistencyStreak(_ rule: CadenceRule) -> Bool {
        switch rule {
        case .daily, .weekly, .monthly:
            return true
        case .weekday:
            return false
        }
    }

    static func isStreakCompletable(
        rule: CadenceRule,
        on date: Date,
        calendar: Calendar
    ) -> Bool {
        guard case .weekday(let weekday) = rule else {
            return true
        }
        return calendar.component(.weekday, from: date) == weekday
    }

    static func streakWasCompletedInCurrentCadence(
        _ previousDate: Date?,
        rule: CadenceRule,
        now: Date,
        calendar: Calendar
    ) -> Bool {
        guard let previousDate else { return false }
        switch rule {
        case .daily:
            return calendar.isDate(previousDate, inSameDayAs: now)
        case .weekly, .weekday:
            return calendar.isDate(previousDate, equalTo: now, toGranularity: .weekOfYear)
        case .monthly:
            return calendar.isDate(previousDate, equalTo: now, toGranularity: .month)
        }
    }

    static func streakContinues(
        from previousDate: Date,
        rule: CadenceRule,
        now: Date,
        calendar: Calendar
    ) -> Bool {
        guard let priorCadenceDate = previousCadenceDate(for: rule, from: now, calendar: calendar) else {
            return false
        }

        switch rule {
        case .daily:
            return calendar.isDate(previousDate, inSameDayAs: priorCadenceDate)
        case .weekly, .weekday:
            return calendar.isDate(previousDate, equalTo: priorCadenceDate, toGranularity: .weekOfYear)
        case .monthly:
            return calendar.isDate(previousDate, equalTo: priorCadenceDate, toGranularity: .month)
        }
    }

    static func previousCadenceDate(
        for rule: CadenceRule,
        from date: Date,
        calendar: Calendar
    ) -> Date? {
        switch rule {
        case .daily:
            return calendar.date(byAdding: .day, value: -1, to: date)
        case .weekly, .weekday:
            return calendar.date(byAdding: .weekOfYear, value: -1, to: date)
        case .monthly:
            return calendar.date(byAdding: .month, value: -1, to: date)
        }
    }

    static func streakEggMilestoneReached(
        currentStreak: Int,
        rule: CadenceRule
    ) -> Bool {
        guard currentStreak > 0 else { return false }
        switch rule {
        case .daily:
            return currentStreak.isMultiple(of: 21)
        case .weekly, .weekday:
            return currentStreak.isMultiple(of: 8)
        case .monthly:
            return currentStreak.isMultiple(of: 4)
        }
    }

    static func streakHitRarity(for rule: CadenceRule) -> LootRarity {
        switch rule {
        case .daily:
            return .common
        case .weekly, .weekday:
            return .uncommon
        case .monthly:
            return .rare
        }
    }

    static func consistencyStreakAchieved(
        rule: CadenceRule,
        on date: Date,
        completedDayKeys: Set<String>,
        calendar: Calendar,
        dayKey: (Date) -> String
    ) -> Bool {
        switch rule {
        case .daily:
            return completedDayKeys.contains(dayKey(date))
        case .weekly:
            return didCompleteQuestEveryDay(
                in: .weekOfYear,
                containing: date,
                completedDayKeys: completedDayKeys,
                calendar: calendar,
                dayKey: dayKey
            )
        case .monthly:
            return didCompleteQuestEveryDay(
                in: .month,
                containing: date,
                completedDayKeys: completedDayKeys,
                calendar: calendar,
                dayKey: dayKey
            )
        case .weekday:
            return false
        }
    }

    static func didCompleteQuestEveryDay(
        in component: Calendar.Component,
        containing date: Date,
        completedDayKeys: Set<String>,
        calendar: Calendar,
        dayKey: (Date) -> String
    ) -> Bool {
        guard let interval = calendar.dateInterval(of: component, for: date) else {
            return false
        }
        let startOfToday = calendar.startOfDay(for: date)
        guard let lastDayOfPeriod = calendar.date(byAdding: .day, value: -1, to: interval.end),
              calendar.isDate(startOfToday, inSameDayAs: lastDayOfPeriod) else {
            return false
        }

        var cursor = calendar.startOfDay(for: interval.start)
        while cursor < interval.end {
            guard completedDayKeys.contains(dayKey(cursor)) else {
                return false
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else {
                return false
            }
            cursor = next
        }
        return true
    }
}
