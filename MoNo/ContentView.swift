//
//  ContentView.swift
//  MoNo
//
//  Created by Aleksa Khruleva on 08.08.2022.
//

import SwiftUI

import SwiftUI
import EventKit
import EventKitUI

let salaryDay = "07"

struct EventStruct {
    let id: String
    let date: Date
    var notes: String
}

struct ContentView: View {
    @Environment(\.managedObjectContext) var moc
    @FetchRequest(sortDescriptors: [
        SortDescriptor(\.date)
    ], predicate: NSPredicate(format: "date >= %@", Date() as NSDate)) var listOfEvents: FetchedResults<Event>
    
    @State var notes = ""
    @State var isLoading = true
    @State var result: [EventStruct] = []
    @State var datePicker = Date()
    @State var listOfDates: [Date] = []
    
    var body: some View {
        ZStack {
            VStack {
                Picker("", selection: $datePicker) {
                    ForEach(listOfDates, id: \.self) { date in
                        Text(pickerDateFormat(date: date))
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .labelsHidden()
                
                TextField("Введите текст", text: $notes)
                    .font(.title3)
                    .padding()
                
                Button {
                    Task {
                        let salaryDate = await findCommingSalaryDate(date: datePicker)
                        
                        if result.contains(where: { $0.date == salaryDate }) {
                            let eventIndex = result.firstIndex { $0.date == salaryDate }!
                            let eventId = result[eventIndex].id
                            editEvent(eventId: eventId, notes: notes)
                            result[eventIndex].notes += "\r\n- \(notes)"
                        } else {
                            let eventId = addEvent(date: datePicker, notes: notes)
                            saveEventInfo(id: eventId, date: salaryDate)
                            result.append(EventStruct(id: eventId, date: salaryDate, notes: "- \(notes)"))
                            result.sort { $0.date < $1.date }
                        }
                        notes = ""
                    }
                } label: {
                    Text("Добавить")
                        .font(.title3.bold())
                        .frame(maxWidth: .infinity)
                }
                .tint(.blue)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(notes.isEmpty)
                .padding()
                
                ScrollView(.vertical, showsIndicators: false) {
                    ForEach(result, id: \.id) { res in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(listDateFormat(date: res.date))
                                    .font(.title3)
                                    .bold()
                                Text(res.notes)
                            }
                            Spacer()
                        }
                        .padding(.bottom)
                    }
                    .padding([.leading])
                }
            }
            if isLoading || listOfDates.isEmpty {
                Rectangle()
                    .fill(Color.white)
                    .allowsHitTesting(true)
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
            }
        }
        .onAppear {
            Task {
                let today = Date()
                let calendar = Calendar.current
                
                let year = calendar.component(.year, from: today)
                let month = calendar.component(.month, from: today)
                
                let dateString = "\(year)\(String(format: "%02d", month))\(salaryDay)"
                let date = stringToDate(string: dateString)
                let commingSalaryDate = await findCommingSalaryDate(date: date)
                
                self.datePicker = commingSalaryDate
                listOfDates = datesRange(from: commingSalaryDate)
                isLoading = false
            }
            getEventInfoFromCalendar()
        }
        .onAppCameToForeground {
            getEventInfoFromCalendar()
        }
    }
    
    func getEventInfoFromCalendar() {
        result = []
        
        let eventStore = EKEventStore()
        
        for element in listOfEvents {
            if let event = eventStore.event(withIdentifier: element.id!) {
                let date = element.date!
                let notes = event.notes ?? "Нет записей"
                result.append(EventStruct(id: event.eventIdentifier, date: date, notes: notes))
            } else {
                print("ABOBA")
                moc.delete(element)
                do {
                    try moc.save()
                } catch {
                    print("removing info: something went wrong")
                }
            }
        }
    }
    
    func saveEventInfo(id: String, date: Date) {
        let event = Event(context: moc)
        event.id = id
        event.date = date
        
        do {
            try moc.save()
        } catch {
            print("saveEventInfo: something went wrong")
        }
    }
    
    func removeEventInfo(at offsets: IndexSet) {
        for index in offsets {
            let event = listOfEvents[index]
            moc.delete(event)
        }
        do {
            try moc.save()
        } catch {
            print("removeEventInfo: something went wrong")
        }
    }
}

extension View {
  func onAppCameToForeground(perform action: @escaping () -> Void) -> some View {
    self.onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
       action()
    }
  }
}

func editEvent(eventId: String, notes: String) {
    let eventStore = EKEventStore()
    let authStatus = EKEventStore.authorizationStatus(for: EKEntityType.event)
    
    if authStatus == .authorized {
        let event = eventStore.event(withIdentifier: eventId)!
        
        var eventNotes = event.notes!
        eventNotes += "\r\n- \(notes)"
        event.notes = eventNotes
        
        do {
            try eventStore.save(event, span: .thisEvent)
        } catch {
            print("editEvent: something went wrong")
        }
    } else {
        print("authStatus: something went wrong")
    }
}

func addEvent(date: Date, notes: String) -> String {
    let eventStore = EKEventStore()
    let authStatus = EKEventStore.authorizationStatus(for: EKEntityType.event)
    
    if authStatus == .authorized {
        let newEvent = EKEvent(eventStore: eventStore)
        newEvent.calendar = eventStore.defaultCalendarForNewEvents
        newEvent.title = "Зарплата"
        newEvent.isAllDay = true
        newEvent.startDate = date
        newEvent.endDate = date
        newEvent.notes = "- \(notes)"
        
        //        let nineMorning = Calendar.autoupdatingCurrent.date(bySettingHour: 15, minute: 0 , second: 0, of: Date())
        //        let alarm = EKAlarm(absoluteDate: nineMorning!)
        //        newEvent.addAlarm(alarm)
        
        do {
            try eventStore.save(newEvent, span: .thisEvent)
            return newEvent.eventIdentifier
        } catch {
            print("addEvent: something went wrong")
            return ""
        }
    } else {
        print("authStatus: something went wrong")
        return ""
    }
}

func datesRange(from: Date) -> [Date] {
    var tempDate = from
    var array = [tempDate]
    
    for _ in 1...12 {
        tempDate = Calendar.current.date(byAdding: .month, value: 1, to: tempDate)!
        array.append(tempDate)
    }

    return array
}

func pickerDateFormat(date: Date) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.timeZone = TimeZone(identifier: "UTC")
    dateFormatter.locale = Locale(identifier: "ru")
    
    dateFormatter.dateFormat = "LLLL"
    let month = dateFormatter.string(from: date).capitalized
    
    dateFormatter.dateFormat = "yyyy"
    let year = dateFormatter.string(from: date)
    
    let formattedDate = "\(month) \(year)"
    return formattedDate
}


func listDateFormat(date: Date) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.timeZone = TimeZone(identifier: "UTC")
    dateFormatter.locale = Locale(identifier: "ru")
    
    dateFormatter.dateFormat = "dd"
    let day = dateFormatter.string(from: date)
    
    dateFormatter.dateFormat = "MMMM"
    let month = dateFormatter.string(from: date).capitalized
    
    dateFormatter.dateFormat = "yyyy"
    let year = dateFormatter.string(from: date)
    
    let formattedDate = "\(day) \(month) \(year)"
    return formattedDate
}

func stringToDate(string: String) -> Date {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyyMMdd"
    dateFormatter.timeZone = TimeZone(identifier: "UTC")
    let date = dateFormatter.date(from: string)!
    return date
}

func dateToString(date: Date) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyyMMdd"
    dateFormatter.timeZone = TimeZone(identifier: "UTC")
    let string = dateFormatter.string(from: date)
    return string
}

func isWorkingDate(date: Date) async -> String {
    let dateString = dateToString(date: date)
    
    guard let url = URL(string: "https://isdayoff.ru/\(dateString)") else {
        return "Error"
    }
    
    do {
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = String(data: data, encoding: String.Encoding.utf8)! as String
        return response
    } catch {
        return "Error"
    }
}

func findCommingSalaryDate(date: Date) async -> Date {
    var salaryDate = await findThisMonthSalaryDate(date: date)
    let today = Date()
    
    if salaryDate < today {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        
        let dateString = "\(year)\(String(format: "%02d", month + 1))\(salaryDay)"
        let date = stringToDate(string: dateString)
        salaryDate = await findThisMonthSalaryDate(date: date)
    }
    
    return salaryDate
}

func findThisMonthSalaryDate(date: Date) async -> Date {
    var salaryDate = date
    var response = await isWorkingDate(date: salaryDate)
    
    while response == "1" {
        salaryDate = Calendar.current.date(byAdding: .day, value: -1, to: salaryDate)!
        response = await isWorkingDate(date: salaryDate)
    }
    
    return salaryDate
}
