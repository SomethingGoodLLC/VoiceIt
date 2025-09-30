import Foundation

extension Date {
    // MARK: - Relative Time
    
    /// Relative time string (e.g., "2 hours ago", "Just now")
    var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    
    /// Short relative time (e.g., "2h ago", "Just now")
    var shortRelativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    
    // MARK: - Formatting
    
    /// Formatted date and time
    var formattedDateTime: String {
        formatted(date: .abbreviated, time: .shortened)
    }
    
    /// Formatted date only
    var formattedDate: String {
        formatted(date: .abbreviated, time: .omitted)
    }
    
    /// Formatted time only
    var formattedTime: String {
        formatted(date: .omitted, time: .shortened)
    }
    
    /// Full date and time
    var formattedFull: String {
        formatted(date: .long, time: .standard)
    }
    
    // MARK: - Comparison
    
    /// Check if date is today
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    /// Check if date is yesterday
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }
    
    /// Check if date is in the current week
    var isThisWeek: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .weekOfYear)
    }
    
    /// Check if date is in the current month
    var isThisMonth: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .month)
    }
    
    /// Check if date is in the current year
    var isThisYear: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .year)
    }
    
    // MARK: - Display Helpers
    
    /// Smart formatted string based on recency
    var smartFormatted: String {
        if isToday {
            return "Today at \(formattedTime)"
        } else if isYesterday {
            return "Yesterday at \(formattedTime)"
        } else if isThisWeek {
            let weekday = formatted(.dateTime.weekday(.wide))
            return "\(weekday) at \(formattedTime)"
        } else if isThisYear {
            return formatted(.dateTime.month().day()) + " at \(formattedTime)"
        } else {
            return formattedDateTime
        }
    }
}

extension TimeInterval {
    // MARK: - Duration Formatting
    
    /// Formatted duration string (e.g., "2:30", "1:05:30")
    var formattedDuration: String {
        let hours = Int(self) / 3600
        let minutes = (Int(self) % 3600) / 60
        let seconds = Int(self) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    /// Short duration (e.g., "2m 30s", "1h 5m")
    var shortDuration: String {
        let hours = Int(self) / 3600
        let minutes = (Int(self) % 3600) / 60
        let seconds = Int(self) % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
}

