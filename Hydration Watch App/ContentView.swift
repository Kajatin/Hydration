//
//  ContentView.swift
//  Hydration Watch App
//
//  Created by Roland Kajatin on 12/06/2022.
//

import Charts
import SwiftUI

// TODO: Logo which is just a drop of water

struct ContentView: View {
    @EnvironmentObject var viewModel: ViewModel
    @State private var selectedTab: Int = 2

    var body: some View {
        ZStack {
            if (viewModel.model.timeToDrinkNotification) {
                TimeToDrinkNotification()
            } else {
                TabView(selection: $selectedTab) {
                    Settings().tag(1)
                    DailyReport().tag(2)
                    WeeklyReport().tag(3)
                }
            }
        }
    }
}

struct DailyReport: View {
    @EnvironmentObject var viewModel: ViewModel
    @Environment(\.dynamicTypeSize) var dynamicSize
    
    @State private var showDetail = false
    @State private var showDeletionAlert = false
    @State private var recordToBeDeleted: Model.HydrationRecord?
    
    private func paddingScaler() -> CGFloat {
        if dynamicSize <= .small {
            return 1.25
        } else if dynamicSize <= .xxLarge {
            return 1
        } else if dynamicSize == .xxxLarge {
            return 0.9
        } else {
            return 0.7
        }
    }

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading) {
                    // Main progress numbers
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        if (viewModel.remainder > 0) {
                            Text("\(Int(viewModel.remainder))").font(.body)
                            Text("mL").font(.caption2)
                        } else {
                            Text("Good job! 🥳").font(.body)
                        }
                        Spacer()
                        Button {
                            showDetail.toggle()
                        } label: {
                            ZStack {
                                Image(systemName: "plus")
                                if (viewModel.model.timeToDrink) {
                                    Image(systemName: "circle.fill")
                                        .offset(x: 20, y: -20)
                                        .scaleEffect(0.5)
                                }
                            }
                            .foregroundColor(viewModel.color)
                            .animation(.spring(), value: viewModel.model.timeToDrink)
                        }
                        .sheet(isPresented: $showDetail) {
                            RegisterHydration()
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding(.top, 20 * paddingScaler())
                    
                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        Text("\(Int(viewModel.progress))")
                            .font(.title)
                            .bold()
                            .foregroundColor(viewModel.color)
                        Text("mL").font(.body)
                    }
                    .padding(.top, 8 * paddingScaler())
                    .padding(.bottom, 15 * paddingScaler())
                    
                    // Progress bar
                    ProgressBar(progress: viewModel.progress, target: viewModel.model.target, color: viewModel.color)
                        .frame(height: 50)
                    
                    // Hydration records today
                    VStack(alignment: .leading) {
                        Text("Intake records")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 5)
                        if (viewModel.todaysRecords.isEmpty) {
                            Text("No records to show")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        } else {
                            ForEach(viewModel.todaysRecords.reversed()) { record in
                                HStack(alignment: .firstTextBaseline) {
                                    Text("\(record.volume.formatted()) mL")
                                    Spacer()
                                    Text(record.date, format: .dateTime.hour().minute())
                                }
                                .padding(.bottom, 5)
                                .onLongPressGesture {
                                    recordToBeDeleted = record
                                    showDeletionAlert.toggle()
                                }
                            }
                        }
                    }
                    .confirmationDialog(
                        "Delete record", isPresented: $showDeletionAlert, presenting: recordToBeDeleted
                    ) { record in
                        Button("Delete", role: .destructive) {
                            viewModel.erase(record)
                        }
                    } message: { record in
                        Text("\(record.volume.formatted()) mL from \(record.date.formatted(date: .omitted, time: .shortened))")
                    }
                    .padding(.top, 35)
                }
                .padding([.leading, .trailing], 4)
            }
            .navigationBarTitle(Text("Today"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct RegisterHydration: View {
    @State private var volume: Float = 250
    @EnvironmentObject var viewModel: ViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(Int(volume))")
                        .font(.title)
                        .bold()
                        .foregroundColor(viewModel.color)
                    Text("mL")
                        .font(.body)
                }
                HStack {
                    Button {
                        volume = max(volume-50, 0)
                    } label: {
                        Image(systemName: "minus")
                    }
                    Button {
                        volume = min(volume+50, 1000)
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    viewModel.registerDrink(
                        Model.HydrationRecord(date: Date.now, volume: volume)
                    )
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Text("Add").foregroundColor(viewModel.color)
                }
            }
        }
    }
}

struct ProgressBar: View {
    @Environment(\.dynamicTypeSize) var dynamicSize
    
    var progress: Float
    var target: Float
    var color: Color
    private let numberOfBars: CGFloat = 15
    private let textStaticOffset: CGFloat = 6
    
    private func calculateNumberOfCompletedBars() -> CGFloat {
        return CGFloat(progress) / (CGFloat(target) / numberOfBars)
    }
    
    private func calculateTextOffsetX(width: CGFloat) -> CGFloat {
        var numberOfCompletedBars = calculateNumberOfCompletedBars()
        numberOfCompletedBars.round(.towardZero)
        let offset = width * ((numberOfCompletedBars - 1) / numberOfBars) - textStaticOffset
        var scaler = 0.8
        if dynamicSize >= .accessibility1 {
            scaler = 0.74
        } else if dynamicSize >= .xxLarge {
            scaler = 0.77
        } else if dynamicSize <= .small {
            scaler = 0.82
        }
        return max(min(offset, width * scaler), 0)
    }

    var body: some View {
        GeometryReader { gp in
            VStack(alignment: .leading) {
                Text("\(Int(progress / target * 100))%")
                    .offset(x: calculateTextOffsetX(width: gp.size.width))
                HStack(spacing: 5) {
                    ForEach((1...Int(numberOfBars)), id: \.self) { idx in
                        if (idx < Int(calculateNumberOfCompletedBars())) {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(color)
                                .frame(width: (gp.size.width - 5 * (numberOfBars - 1)) / numberOfBars)
                        } else if (idx == Int(calculateNumberOfCompletedBars())) {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(color)
                                .frame(width: (gp.size.width - 5 * (numberOfBars - 1)) / numberOfBars, height: 32)
                        } else {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(.gray)
                                .frame(width: (gp.size.width - 5 * (numberOfBars - 1)) / numberOfBars, height: 15)
                        }
                    }
                }
            }
        }
    }
}

struct Settings: View {
    @EnvironmentObject var viewModel: ViewModel
    @Environment(\.dynamicTypeSize) var dynamicSize
    
    @State private var showResetSettings = false
    @State private var showEraseContent = false
    @State private var showEraseContentAndReset = false
    @State private var showTargetSelectionSetting = false
    @State private var dailyTarget: Float = 2500

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Daily intake"), footer: Text("Recommended daily intake is 3 litres for men and 2.2 litres for women.")) {
                    if (dynamicSize <= .xxLarge) {
                        Stepper(value: $viewModel.target, step: 50) {
                            Text("\(viewModel.target.formatted()) mL")
                                .font(.body)
                        }
                    } else {
                        NavigationLink {
                            DailyIntakeSettings()
                        } label: {
                            Text("\(viewModel.target.formatted())")
                        }
                    }
                }
                Section(header: Text("Notification interval"), footer: Text("It is recommended that you should drink every hour.")) {
                    if (dynamicSize <= .xxLarge) {
                        Stepper(value: $viewModel.notificationInterval, in: 1200...7200, step: 300) {
                            Text(String(format: "%.2d:%.2d h",
                                        Int((viewModel.notificationInterval / 3600).rounded(.towardZero)),
                                        Int(viewModel.notificationInterval.truncatingRemainder(dividingBy: 3600) / 60)
                                       )
                            )
                            .font(.body)
                        }
                    } else {
                        NavigationLink {
                            NotificationIntervalSettings()
                        } label: {
                            Text(String(
                                format: "%.2d:%.2d h",
                                Int((viewModel.notificationInterval / 3600).rounded(.towardZero)),
                                Int(viewModel.notificationInterval.truncatingRemainder(dividingBy: 3600) / 60)))
                            .font(.body)
                        }
                    }
                }
                Section(header: Text("Interface")) {
                    Picker("Accent", selection: $viewModel.color) {
                        ForEach(viewModel.colors, id: \.self) { color in
                            HStack {
                                Text(color.description.capitalized(with: .autoupdatingCurrent))
                                    .foregroundColor(color)
                            }
                        }
                    }
                }
                Section(header: Text("Privacy")) {
                    Button("Reset Settings") {
                        showResetSettings.toggle()
                    }
                    .foregroundColor(.blue)
                    .confirmationDialog("Reset Settings", isPresented: $showResetSettings) {
                        Button("Reset") {
                            viewModel.resetSettings()
                        }
                    } message: {
                        Text("Resetting removes custom settings and restores default values.")
                    }
                    
                    Button("Erase All Content", role: .destructive) {
                        showEraseContent.toggle()
                    }
                    .confirmationDialog("Erase All Content", isPresented: $showEraseContent) {
                        Button("Erase", role: .destructive) {
                            viewModel.clearData()
                        }
                    } message: {
                        Text("Erasing deletes all hydration records.")
                    }
                    
                    Button("Erase All Content and Settings", role: .destructive) {
                        showEraseContentAndReset.toggle()
                    }
                    .confirmationDialog("Erase All Content and Settings", isPresented: $showEraseContentAndReset) {
                        Button("Erase and Restore", role: .destructive) {
                            viewModel.resetSettings()
                            viewModel.clearData()
                        }
                    } message: {
                        Text("Erasing deletes all hydration records and restore default settings.")
                    }
                }
            }
            .navigationBarTitle(Text("Settings"))
        }
    }
}

struct DailyIntakeSettings: View {
    @EnvironmentObject var viewModel: ViewModel
    
    var body: some View {
        NavigationView {
            VStack {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(Int(viewModel.target))")
                        .font(.title)
                        .bold()
                        .foregroundColor(viewModel.color)
                    Text("mL")
                        .font(.body)
                }
                HStack {
                    Button {
                        viewModel.target = max(viewModel.target-50, 500)
                    } label: {
                        Image(systemName: "minus")
                    }
                    Button {
                        viewModel.target = min(viewModel.target+50, 5000)
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .navigationBarTitle(Text("Daily intake"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct NotificationIntervalSettings: View {
    @EnvironmentObject var viewModel: ViewModel
    
    var body: some View {
        NavigationView {
            VStack {
                HStack(alignment: .firstTextBaseline) {
                    Text(String(
                        format: "%.2d:%.2d",
                        Int((viewModel.notificationInterval / 3600).rounded(.towardZero)),
                        Int(viewModel.notificationInterval.truncatingRemainder(dividingBy: 3600) / 60)))
                    .foregroundColor(viewModel.color)
                    Text(" h")
                }
                .font(.title)
                
                HStack {
                    Button {
                        viewModel.notificationInterval = max(viewModel.notificationInterval-300, 1200)
                    } label: {
                        Image(systemName: "minus")
                    }
                    Button {
                        viewModel.notificationInterval = min(viewModel.notificationInterval+300, 7200)
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .navigationBarTitle(Text("Notification interval"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct WeeklyReport: View {
    @EnvironmentObject var viewModel: ViewModel
    
    @State private var showChart = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if (viewModel.weeklyRecords.isEmpty) {
                    VStack {
                        Text("No logs found")
                            .font(.headline)
                            .padding(.bottom, 10)
                        Text("Start recording your liquid intake and the last week's summary will appear here")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                } else {
                    VStack(alignment: .leading) {
                        ForEach(viewModel.weeklyRecords.sorted(by: >), id: \.key) { date, volume in
                            HStack(alignment: .firstTextBaseline) {
                                Text(date.relativeDayString())
                                    .lineLimit(1)
                                Spacer()
                                Text("\(volume.formatted()) mL")
                            }
                            .foregroundColor(Calendar.autoupdatingCurrent.isDateInToday(date) ? .primary : .secondary)
                            .padding(.bottom)
                        }
                        NavigationLink {
                            ChartView()
                        } label: {
                            Text("Chart")
                        }
                        .padding(.top)
                    }
                }
            }
            .padding(.top)
            .navigationBarTitle(Text("Weekly report"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct ChartView: View {
    @EnvironmentObject var viewModel: ViewModel

    var body: some View {
        Chart(viewModel.createWeeklyRecordsChartData(viewModel.weeklyRecords)) { data in
            RuleMark(y: .value("Target", viewModel.target)).foregroundStyle(.white)
            BarMark(
                x: .value("Date", data.date),
                y: .value("Consumption", data.consumption),
                width: .fixed(10)
            )
            .cornerRadius(5)
            .foregroundStyle(by: .value("ReachedTarget", data.consumption >= viewModel.target ? "fulfilled" : "failed"))
        }
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel(format: Date.FormatStyle().weekday(), centered: true)
                    .offset(y:2)
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(.gray)
                
                if value.index < (value.count - 1) {
                    AxisValueLabel(format: IntegerFormatStyle<Int>())
                        .offset(x:5)
                }
            }
        }
        .chartForegroundStyleScale(["failed": .gray, "fulfilled": viewModel.color])
        .chartLegend(.hidden)
        .padding([.leading, .trailing])
    }
}

struct TimeToDrinkNotification: View {
    @EnvironmentObject var viewModel: ViewModel

    var body: some View {
        ZStack {
            VStack {
                Text("Drink up")
                    .font(.title2)
                    .foregroundColor(viewModel.color)
                    .padding(.bottom)
                Text("\(viewModel.mostRecentRecord.volume.formatted()) mL")
                    .foregroundColor(.secondary)
                Text("\(viewModel.mostRecentRecord.date.relativeDateString())")
                    .foregroundColor(.secondary)
            }
            Button("Dismiss", role: .cancel) {
                viewModel.dismissNotification()
            }
            .buttonStyle(.borderless)
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .navigationBarHidden(true)
    }
}

extension Date {
    func relativeDayString() -> String {
        if (Calendar.autoupdatingCurrent.isDateInToday(self)) {
            return "Today"
        } else if (Calendar.autoupdatingCurrent.isDateInYesterday(self)) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(for: self)!
        }
    }
    
    func relativeDateString() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date.now)
    }
    
    func relativeDateString(to: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: to)
    }
}

struct ContentView_Previews: PreviewProvider {
    static let viewModel = ViewModel()

    static var previews: some View {
        ContentView().environmentObject(viewModel)
    }
}
