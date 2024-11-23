//
//  NotificationLogger.swift
//  SoundMap
//
//  Created by Jonathan on 22/11/2024.
//

import Foundation

class NotificationLogger {
    static let shared = NotificationLogger()
    
    #if DEBUG
    private let isLoggingEnabled = true
    #else
    private let isLoggingEnabled = false
    #endif
    
    private init() {}
    
    enum LogType {
        case location
        case stay
        case venue
        case notification
        case error
        
        var prefix: String {
            switch self {
            case .location: return "📍 [LOCATION]"
            case .stay: return "⏱️ [STAY]"
            case .venue: return "🏢 [VENUE]"
            case .notification: return "🔔 [NOTIFICATION]"
            case .error: return "❌ [ERROR]"
            }
        }
    }
    
    func log(_ type: LogType, _ message: String) {
        #if DEBUG
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        print("\n\(timestamp) \(type.prefix): \(message)\n")
        #endif
    }
}
