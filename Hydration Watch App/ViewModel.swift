//
//  ViewModel.swift
//  Hydration Watch App
//
//  Created by Roland Kajatin on 17/06/2022.
//

import SwiftUI
import WidgetKit
import UserNotifications

class ViewModel: NSObject, UNUserNotificationCenterDelegate, ObservableObject {
    @Published private(set) var model: Model {
        didSet {
            autosave()
            
            // Update the widget
            let userDefaults = UserDefaults(suiteName: "group.widget.com.gmail.roland.kajatin")
            userDefaults?.set(target, forKey: "target")
            userDefaults?.set(progress, forKey: "progress")
            userDefaults?.set(color.description, forKey: "color")
            WidgetCenter.shared.reloadTimelines(ofKind: "com.widget.Hydration_Widget")
        }
    }
    
    override init() {
        if let url = Autosave.url, let autosavedModel = try? Model(url: url) {
            self.model = autosavedModel
        } else {
            self.model = Model()
        }

        super.init()

        let notificationCenter = UNUserNotificationCenter.current()
        
        notificationCenter.getNotificationSettings() { settings in
            if settings.authorizationStatus == .notDetermined {
                notificationCenter.requestAuthorization(options: [.alert, .sound]) { granted, error in
                    if let error = error {
                        // Handle the error here.
                        print(error)
                    }
                    
                    // Enable or disable features based on the authorization.
                }
            } else if settings.authorizationStatus == .denied {
                // TODO: if we are denied authorization, we should occasionally request it again (maybe)
                print("Authorization is denied")
            }
        }

        notificationCenter.delegate = self
        
        let identifier = "reset-day"
        notificationCenter.removeDeliveredNotifications(withIdentifiers: [identifier])
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        
        let content = UNMutableNotificationContent()
        content.title = "Reset Day"
        content.subtitle = "Subtitle"
        content.body = "Starting new day"
        
        // Fire
        var date = DateComponents()
        date.hour = 0
        date.minute = 5
        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
        
        // Create the request
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // Schedule the request with the system
        notificationCenter.add(request) { error in
            if error != nil {
                // Handle any errors.
            }
        }
        
        let midnight = Calendar(identifier: .gregorian).startOfDay(for: Date(timeIntervalSinceNow: 86400))
        model.records.removeAll(where: { $0.date < Date(timeInterval: -model.hydrationHistory*24*60*60, since: midnight) })
        
        if (mostRecentRecord.date < Date(timeIntervalSinceNow: -model.notificationInterval)) {
            let identifier = "time-to-drink"
            let content = UNMutableNotificationContent()
            content.title = "Time to Drink"
            content.subtitle = "Subtitle"
            content.body = "Remember to stay hydrated"
            //        content.sound = UNNotificationSound.default
            
            // Fire in 5 seconds
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
            
            // Create the request
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            // Schedule the request with the system
            notificationCenter.add(request) { error in
                if error != nil {
                    // Handle any errors.
                }
            }
        }
    }
    
    private struct Autosave {
        static let filename = "Autosave.hydration"
        static var url: URL? {
            let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            return documentDirectory?.appendingPathComponent(filename)
        }
    }
    
    private func autosave() {
        if let url = Autosave.url {
            save(to: url)
        }
    }
    
    private func save(to url: URL) {
        let thisFunction = "\(String(describing: self)).\(#function)"
        do {
            let data: Data = try model.json()
//            print("\(thisFunction) json = \(String(data: data, encoding: .utf8) ?? "nil")")
            try data.write(to: url)
//            print("\(thisFunction) success!")
        } catch {
            print("\(thisFunction) = \(error)")
        }
    }
    
    var todaysRecords: Array<Model.HydrationRecord> {
        model.records.filter {
            Calendar.autoupdatingCurrent.isDateInToday($0.date)
        }
    }
    
    var remainder: Float {
        return model.target - progress
    }
    
    var progress: Float {
        let sum = todaysRecords.reduce(0, { sum, record in
            sum + record.volume
        })
        return sum
    }
    
    var target: Float {
        get { return model.target }
        set { model.target = newValue }
    }
    
    var notificationInterval: Double {
        get { return model.notificationInterval }
        set { model.notificationInterval = newValue.rounded() }
    }
    
    let colors = Model.colors
    
    var color: Color {
        get { return model.color }
        set { model.color = newValue }
    }
    
    var weeklyRecords: Dictionary<Date, Float> {
        let groupedByDay = Dictionary(grouping: model.records, by: {
            let components = Calendar.current.dateComponents([.year, .month, .day], from: $0.date)
            return Calendar.current.date(from: components)!
        })
        return groupedByDay.mapValues {
            let sum = $0.reduce(0, { sum, record in
                sum + record.volume
            })
            return sum
        }
    }
    
    var mostRecentRecord: Model.HydrationRecord {
        if model.records.isEmpty {
            return Model.HydrationRecord(date: Date(timeIntervalSince1970: 0), volume: 0)
        }
        
        return model.records.sorted(by: {
            $0.date.compare($1.date) == .orderedDescending
        })[0]
    }
    
    struct chartItem: Identifiable {
        var id: Date { date }
        let date: Date
        let consumption: Float
    }
    
    func createWeeklyRecordsChartData(_ records: Dictionary<Date, Float>) -> [chartItem] {
        records.map { record in
            return chartItem(date: record.key, consumption: record.value)
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if (notification.request.identifier == "time-to-drink") {
            model.timeToDrink = true
            model.timeToDrinkNotification = true
//            print("Time to drink")
        } else if (notification.request.identifier == "reset-day") {
//            print("Resetting day")
            let midnight = Calendar(identifier: .gregorian).startOfDay(for: Date(timeIntervalSinceNow: 86400))
            model.records.removeAll(where: { $0.date < Date(timeInterval: -model.hydrationHistory*24*60*60, since: midnight) })
        }
        
        completionHandler(.sound)
    }
    
    // MARK: Intents

    func registerDrink(_ drink: Model.HydrationRecord) {
        model.records.append(drink)
        model.timeToDrink = false
//        for _ in 0...30 {
//            model.records.append(Model.HydrationRecord(date: Date.init(timeIntervalSinceNow: TimeInterval(-86400 * Int.random(in: 0..<7))), volume: Float(Int.random(in: 150...300))))
//        }
        
        // Cancel previous notification
        let identifier = "time-to-drink"
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.removeDeliveredNotifications(withIdentifiers: [identifier])
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        
        if (progress >= target) {
            return
        }
        
        let midnight = Calendar(identifier: .gregorian).startOfDay(for: Date(timeIntervalSinceNow: 86400))
        let timeUntilMidnight = midnight.timeIntervalSinceNow
        let averageIntake: Double = 250
        let timeInterval = (averageIntake * Double(timeUntilMidnight)) / Double(remainder)
        let fireIn: Double = min(timeInterval, model.notificationInterval)
        let dateWhenNotificationShows = Date(timeInterval: fireIn, since: mostRecentRecord.date)

        let content = UNMutableNotificationContent()
        content.title = "Take a Sip"
//        content.subtitle = "Subtitle"
        content.body = "Last intake was \(Date.now.relativeDateString(to: dateWhenNotificationShows))"
        
        // Create the request
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: fireIn, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // Schedule the request with the system
        notificationCenter.add(request) { error in
            if error != nil {
                // Handle any errors.
            }
        }
    }
    
    func erase(_ record: Model.HydrationRecord) {
        if let idx = model.records.firstIndex(of: record) {
            model.records.remove(at: idx)
        }
    }
    
    func resetSettings() {
        model.restoreDefaults()
    }
    
    func clearData() {
        // Cancel previous notification
        let identifier = "time-to-drink"
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.removeDeliveredNotifications(withIdentifiers: [identifier])
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])

        model.records.removeAll()
    }
    
    func dismissNotification() {
        model.timeToDrinkNotification = false
    }
}
