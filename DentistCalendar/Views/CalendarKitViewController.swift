//
//  CalendarKitViewController.swift
//  DentistCalendar
//
//  Created by Даник 💪 on 10/18/20.
//

import UIKit
import CalendarKit
import SwiftUI
import Amplify
import Combine
//import BottomSheet
let group = DispatchGroup()

public struct newModel {
    static var appointment: Appointment? = nil
}
private func trimDate(_ date: Date) -> (String, String) {
    return (
        String(Date(year: date.year, month: date.month, day: date.day, hour: 0, minute: 0, second: 0).timeIntervalSince1970),
        String(Date(year: date.year, month: date.month, day: date.day + 1, hour: 0, minute: 0, second: 0).timeIntervalSince1970)
    )
}
private func getAppStartDate(_ date: String) -> Date {
    let date = Date(timeIntervalSince1970: TimeInterval(date)!)
    return Date(year: date.year, month: date.month, day: date.day, hour: 0, minute: 0, second: 0)
}
private func fromTimestampToDate(date: String) -> Date{
    return Date(timeIntervalSince1970: TimeInterval(date)!)
}
enum SheetType: String, Identifiable {
    var id: String {
        rawValue
    }
    case calendarView
    case createView
}
class CustomDayViewController: ObservableObject {
    let id = UUID()
    var customDayView: DayView?
     var selectedAppointment: Appointment = Appointment(title: "Загрузка...", dateStart: "0", dateEnd: "0")
    @Published var selectedDate: Date =  Date()
    @Published var isDatePickerPresented = false
    @Published var isSheetPresented = false
    @Published var selectedSheetType: SheetType = .calendarView
    var dateStart: Date = Date()
    var dateEnd: Date = Date()
}
class CustomCalendarExampleController: DayViewController {
    
    var observationToken: AnyCancellable?
    var dateStart: Binding<Date>
    var selectedAppointment: Binding<Appointment>
    var dateEnd: Binding<Date>
    var defData = [Appointment]()
    var generatedEvents = [EventDescriptor]()
    var viewData: CustomDayViewController
    var alreadyGeneratedSet = Set<Date>()
    var style = CalendarStyle()
    var colors = [UIColor.blue,
                  UIColor.yellow,
                  UIColor.green,
                  UIColor.red]
    func observeAppointments() {
        observationToken = Amplify.DataStore.publisher(for: Appointment.self)
            .receive(on: DispatchQueue.main)
            .sink { (completion) in
                if case .failure(let error) = completion {
                    print("ERROR IN OBSERVE APPOINTMENTS", error.errorDescription)
                }
            } receiveValue: { (changes) in
                //                print("CHANGES ", changes)
                guard let app = try? changes.decodeModel(as: Appointment.self) else {return}
                
                switch changes.mutationType {
                case ("create"):
                    if !self.generatedEvents.contains(where: { (event) -> Bool in
                        event.id == app.id
                    }) && self.alreadyGeneratedSet.contains(getAppStartDate(app.dateStart)) {
//                        print("NEW APPOINTMENT", app)
                        let event = self.generateEvent(appointment: app)
//                        print("ADDING EVENT", event.text)
                        self.endEventEditing()
                        self.generatedEvents.append(event)
                        self.endEventEditing()
                        self.reloadData()
                        
                    }
                    //                DispatchQueue.main.async {
                    ////                    self.endEventEditing()
                    //                    self.reloadData()
                    //
                    //                }
                    break
                case "update":
                    if let index = self.generatedEvents.firstIndex(where: {$0.id == app.id}) {
//                        print("UPDATE APPOINTMENT", app)
                        let event = self.generateEvent(appointment: app)
                        DispatchQueue.main.async {
//                            print("ADDING EVENT", event.text)
                            self.generatedEvents[index] = event
                            self.reloadData()
                            if app.id == self.selectedAppointment.wrappedValue.id {
                                self.selectedAppointment.wrappedValue = app
                            }
                        }
                    }
                    DispatchQueue.main.async {
                        self.reloadData()
                    }
                case "delete":
                    if let index = self.generatedEvents.firstIndex(where: {$0.id == app.id}) {
                        self.generatedEvents.remove(at: index)
                        self.reloadData()
                    }
                    break
                default:
                    //                DispatchQueue.main.async {
                    ////                    self.endEventEditing()
                    //                    self.reloadData()
                    //                }
                    break
                }
            }
        
    }
    
    func observePayments() {
        _ = Amplify.DataStore.publisher(for: Payment.self)
            .receive(on: DispatchQueue.main)
            .sink { (completion) in
                if case .failure(let error) = completion {
                    print("ERROR IN OBSERVE PAYMENTS", error.errorDescription)
                }
            } receiveValue: { (changes) in
                //                print("CHANGES ", changes)
                guard (try? changes.decodeModel(as: Payment.self)) != nil else {return}
//                print("UPDATE PAYMENT", payment)
                switch changes.mutationType {
                case "delete":
                    break
//                    print("DELETE PAYMENT OBSERVE ", payment)
                default: break
                }
                }
            }
    
    private func generateEvent(appointment: Appointment) -> Event{
        let newEvent = Event(id: appointment.id)
        newEvent.startDate = fromTimestampToDate(date: appointment.dateStart)
        newEvent.endDate = fromTimestampToDate(date: appointment.dateEnd)
        newEvent.lineBreakMode = .byTruncatingTail
        if appointment.patientID != nil {
            let info = [appointment.title, convertDiagnosisString(str: appointment.diagnosis ?? "", returnEmpty: false)]
            newEvent.text = info.reduce("", {$0 + $1 + "\n"})
            if traitCollection.userInterfaceStyle == .dark {
                newEvent.textColor = textColorForEventInDarkTheme(baseColor: newEvent.color)
                newEvent.backgroundColor = newEvent.color.withAlphaComponent(0.6)
            }
            
        } else {
            newEvent.text = appointment.title
            newEvent.backgroundColor = UIColor(named: "Red2")!
            newEvent.color = UIColor(named: "Red2")!
            newEvent.textColor = UIColor(named: "Red2Text")!
        }
        
        return newEvent
    }
    private lazy var rangeFormatter: DateIntervalFormatter = {
        let fmt = DateIntervalFormatter()
        fmt.dateStyle = .none
        fmt.timeStyle = .short
        
        return fmt
    }()
    
    override func loadView() {
//        calendar.timeZone = TimeZone.current
//        calendar.locale = Locale.init(identifier: Locale.preferredLanguages.first!)
        dayView = DayView(calendar: calendar)
        style.header.daySelector.todayActiveBackgroundColor = UIColor(Color(hex: "#2A86FF"))
        dayView.updateStyle(style)
        view = dayView
            viewData.customDayView = dayView
//        print("DAYVIEW", dayView)
        //        customDayViewControlle
//        print("LOADVIEW")
    }
    override func viewDidAppear(_ animated: Bool) {
        observeAppointments()
        observePayments()
        print("VIEWDIDAPPEAR")
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dayView.autoScrollToFirstEvent = true
        print("TIMEZONE", dayView.calendar.timeZone)
        reloadData()
//        print("VIEWDIDLOAD")
        
    }
//    override func viewDidDisappear(_ animated: Bool) {
//        observationToken?.cancel()
//    }
    init(dateStart: Binding<Date>, dateEnd: Binding<Date>, selectedAppointment: Binding<Appointment>, viewData: CustomDayViewController)
    {
        self.dateStart = dateStart
        self.dateEnd = dateEnd
        self.selectedAppointment = selectedAppointment
        self.viewData = viewData
        super.init(nibName: nil, bundle: nil)
//        viewData.customDayView = self.dayView
//        print("VIEWDATA", viewData.id)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
        
    }
    // MARK: EventDataSource
    
    override func eventsForDate(_ date: Date) -> [EventDescriptor] {
        let formattedDate = Date(year: date.year, month: date.month, day: date.day, hour: 0, minute: 0, second: 0)
//        viewData.selectedDate = dayView.state!.selectedDate
        if !alreadyGeneratedSet.contains(formattedDate) {
//            print("generate events", date)
            alreadyGeneratedSet.insert(formattedDate)
            generatedEvents.append(contentsOf: generateEventsForDate(date))
        }
        //        print("GEN EVENTS", generatedEvents)
        return generatedEvents
    }
    private func generateEventsForDate(_ date: Date) -> [EventDescriptor] {
        var events = [Event]()
        let data = trimDate(date)
        var fetchedData = [Appointment]()
        Amplify.DataStore.query(Appointment.self, where:
                                    
                                    //                                    Appointment.keys.owner == Amplify.Auth.getCurrentUser()!.userId &&
                                    Appointment.keys.dateStart >= data.0 && Appointment.keys.dateEnd <= data.1) { res in
            switch res {
            case .success(let appointments):
                fetchedData = appointments
            case .failure(let error):
                print("generateEventsForDate ERROR", error.errorDescription)
                return
            }
        }
        for appointment in fetchedData {
            events.append(generateEvent(appointment: appointment))
        }
        
//        print("Events for \(date)")
        return events
    }
    
    private func textColorForEventInDarkTheme(baseColor: UIColor) -> UIColor {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        baseColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return UIColor(hue: h, saturation: s * 0.3, brightness: b, alpha: a)
    }
    
    // MARK: DayViewDelegate
    
    private var createdEvent: EventDescriptor?
    
    override func dayViewDidSelectEventView(_ eventView: EventView) {
        guard let descriptor = eventView.descriptor as? Event else {
            return
        }
//        print("Event has been selected: \(descriptor) \(String(describing: descriptor.userInfo))")
        Amplify.DataStore.query(Appointment.self, byId: descriptor.id) { res in
            switch res {
            case .success(let appointment):
                self.viewData.selectedSheetType = .calendarView
                self.selectedAppointment.wrappedValue = appointment!
                self.viewData.isSheetPresented = true
                
//                print("GOT APPOINTMENTS", appointment)
            //                print("FULLSCREENISCALENDAR", fullScreenIsCalendar.wrappedValue)
            //                let vc = UIHostingController(rootView: AppointmentCalendarView(appointment: appointments[0]))
            //                show(vc, sender: self)
            case .failure(let error):
                print("ERROR CALENDAR", error.errorDescription)
            }
        }
    }
    
    override func dayViewDidLongPressEventView(_ eventView: EventView) {
        guard let descriptor = eventView.descriptor as? Event else {
            return
        }
        endEventEditing()
        print("Event has been longPressed: \(descriptor) \(String(describing: descriptor.userInfo))")
        beginEditing(event: descriptor, animated: true)
    }
    
    override func dayView(dayView: DayView, didTapTimelineAt date: Date) {
        endEventEditing()
        
        print("Did Tap at date: \(date)")
    }
    
    override func dayViewDidBeginDragging(dayView: DayView) {
        endEventEditing()
        print("DayView did begin dragging")
    }
    
    override func dayView(dayView: DayView, willMoveTo date: Date) {
        print("DayView = \(dayView) will move to: \(date)")
    }
    
    override func dayView(dayView: DayView, didMoveTo date: Date) {
        print("DayView = \(dayView) did move to: \(date)")
        viewData.selectedDate = dayView.state!.selectedDate
//        viewData.customDayView?.move(to: date)
    }
    
    override func dayView(dayView: DayView, didLongPressTimelineAt date: Date) {
        print("Did long press timeline at date \(date)")
        // Cancel editing current event and start creating a new one
        
        endEventEditing()
        let event = generateEventNearDate(date)
//        print("Creating new event")
        create(event: event, animated: true)
        createdEvent = event
    }
    
    private func generateEventNearDate(_ date: Date) -> EventDescriptor {
        
        let duration = Int(arc4random_uniform(0) + 60)
        let startDate = Calendar.current.date(byAdding: .minute, value: -Int(CGFloat(duration) / 2), to: date)!
        let event = Event(id: "")
        
        event.startDate = startDate
        event.endDate = Calendar.current.date(byAdding: .minute, value: duration, to: startDate)!
        var info = ["Имя пациента".localized,"Диагноз".localized]
        
        info.append(rangeFormatter.string(from: event.startDate, to: event.endDate))
        event.text = info.reduce("", {$0 + $1 + "\n"})
        event.lineBreakMode = .byTruncatingTail
        event.editedEvent = event
        // Event styles are updated independently from CalendarStyle
        // hence the need to specify exact colors in case of Dark style
        if #available(iOS 12.0, *) {
            if traitCollection.userInterfaceStyle == .dark {
                event.textColor = textColorForEventInDarkTheme(baseColor: event.color)
                event.backgroundColor = event.color.withAlphaComponent(0.6)
            }
        }
        return event
        
    }
    
    override func dayView(dayView: DayView, didUpdate event: EventDescriptor) {
        viewData.dateStart = event.startDate
        viewData.dateEnd = event.endDate
//        print("new startDate: \(event.startDate) new endDate: \(event.endDate)")
        self.viewData.selectedSheetType = .createView
        
        
        
        if event.id.isEmpty {
            guard self.viewData.isSheetPresented == false && event.startDate != event.endDate else {return}
            self.viewData.isSheetPresented = true
            group.enter()
//            print("GROUP ENTER")
            group.notify(queue: .main) {
                
                print(newModel.appointment ?? "nothing")
                
//                print("I WAS NOTIFIED")
                if newModel.appointment == nil{
                    self.endEventEditing()
                    self.viewData.isSheetPresented = false
                    return
                }
                
                self.viewData.isSheetPresented = false
                
                
//                print("CREATED EVENT")
                //                self.generatedEvents.append(newEvent)
                self.createdEvent = nil
                newModel.appointment = nil
                self.endEventEditing()
                self.reloadData()
            }
            
        } else {
            Amplify.DataStore.query(Appointment.self, byId: event.id) {  res in
                switch res {
                case .success(var app):
                    let startDate = String(event.startDate.timeIntervalSince1970)
                    let endDate = String(event.endDate.timeIntervalSince1970)
                    if app!.dateStart != startDate && app!.dateEnd != endDate{
                        app!.dateStart = startDate
                        app!.dateEnd = endDate
                        Amplify.DataStore.save(app!) { result in
                            switch result {
                            case .success:
                                break
                            case .failure(let error):
                                print("error", error.errorDescription)
                                return
                            }
                            
                        }
                    }
                    if let _ = event.editedEvent {
                        event.commitEditing()
                    }
                    reloadData()
                case .failure(let error):
                    print("Error in dayView", error.errorDescription)
                    return
                }
            }
            
            
            
        }
        
    }
}

struct CustomController: UIViewControllerRepresentable {
    @Binding var dateStart: Date
    @Binding var dateEnd: Date
    @Binding var generatedEvents: [EventDescriptor]
    @Binding var selectedAppointment: Appointment
    var viewData: CustomDayViewController
    func updateUIViewController(_ uiViewController: UIViewController, context: Context){
        
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
        let dayViewController = CustomCalendarExampleController( dateStart: $dateStart, dateEnd: $dateEnd, selectedAppointment: $selectedAppointment, viewData: viewData)
        return dayViewController
    }
}


struct CalendarKitView: View {
    
    @State var dateStart = Date()
    @State var dateEnd = Date()
    @State var cancellable: AnyCancellable?
    @State var generatedEvents = [EventDescriptor]()
//    @State var selectedDate: Date = Date()
    @StateObject var data = CustomDayViewController()
    @State var isDatePickerPresented = false
    @State var isShown = false
    @State var isTodayShown = false
//    @State var isDataPickerPresented = false
    @State var isSettingsPresented = false
    
    @StateObject var modalManager = ModalManager()
//    @EnvironmentObject var internetManager: InternetConnectionManager
    var body: some View {
            NavigationView {
                    ZStack {
                        CustomController(dateStart: $dateStart, dateEnd: $dateEnd, generatedEvents: $generatedEvents,selectedAppointment: $data.selectedAppointment, viewData: data)
                        if isTodayShown {
                            VStack {
                                Spacer()
                                HStack{
                                    Button(action: {
                                        moveDate(Date())
                                    }, label: {
                                        Text("Сегодня")
                                            .font(.footnote)
                                            .bold()
                                            .foregroundColor(.white)
                                            .padding(10)

                                    })
                                    .background(Color("Blue"))
                                    .clipShape(Rectangle())
                                    .cornerRadius(30)
                                    Spacer()
                                }.padding([.bottom, .leading], 15)

                            }
                            .offset(y: isShown ? 0 : 100)
                            .animation(.spring())
                            .onAppear(perform: {
                                isShown = true
                            })
                        }
                    }
                    .onChange(of: data.selectedDate, perform: { (newDate) in
                        print("NEWDATE", data.selectedDate)
                        if newDate.isToday {
                            isShown = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
                                isTodayShown = false
                            })
                        } else {
                            isTodayShown = true
                        }
                    })
                    .onChange(of: modalManager.selectedDate, perform: { (newDate) in
                        data.isSheetPresented = false
//                        modalManager.isDatePickerPresented = false
                        isDatePickerPresented = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: {
                            if newDate != data.selectedDate {
                                data.customDayView?.move(to: newDate)
                            }
                        })
//                        print("DAYVIEW", data.customDayView)
//                        print("VIEWDATA", data.id)

                    })
                    .navigationBarTitle("Календарь", displayMode: .inline)
                    .navigationBarItems(leading:
                                            NavigationLink(destination: ProfileSettingsView(), label: {
                                                Image(systemName: "gearshape.fill").font(.title3)
                                            }), trailing: getDatePickerButton()
                                            
                    )
            
                
            }
            .navigationViewStyle(StackNavigationViewStyle())
        
            .halfModalSheet(isPresented: $modalManager.isDatePickerPresented, height: UIScreen.main.bounds.width + 50) {
                DatePicker("", selection: $modalManager.selectedDate, displayedComponents: .date)
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .labelsHidden()
            }
            .sheet(isPresented: $data.isSheetPresented, content: {
//            Print("FULL ScREEN", data.fullScreenIsCalendar)
                switch data.selectedSheetType {
                case .calendarView:
                    AppointmentCalendarView(appointment: data.selectedAppointment)
//                        .environmentObject(internetManager)

                case .createView:
                    AppointmentCreateView(isAppointmentPresented: $data.isSheetPresented, viewType: .createWithPatient, dateStart: data.dateStart, dateEnd: data.dateEnd, group: group)
                        .allowAutoDismiss(false)
//                        .environmentObject(internetManager)
                }
//            if data.fullScreenIsCalendar {
//                AppointmentCalendarView(appointment: data.selectedAppointment, fullScreenIsCalendar: $data.fullScreenIsCalendar, intestital: intestial)
//                    .allowAutoDismiss(true)
//                    .environmentObject(internetManager)
//            } else {
//                AppointmentCreateView(isAppointmentPresented: $data.isSheetPresented, viewType: .createWithPatient, dateStart: data.dateStart, dateEnd: data.dateEnd, group: group)
//                    .allowAutoDismiss(false)
//            }
            
        })
    }
    
    @ViewBuilder func getDatePickerButton() -> some View {
        if UIDevice.current.userInterfaceIdiom == .phone {
            Button(action: {
                modalManager.selectedDate = data.selectedDate
                modalManager.isDatePickerPresented.toggle()
            }, label: {
                Image(systemName: "calendar")
                    .font(.title3)
                
            })
        } else {
            Button(action: {
//                data.selectedSheetType = .datePickerView
//                data.isSheetPresented = true
                isDatePickerPresented = true
            }, label: {
                Image(systemName: "calendar")
                    .font(.title3)
                
            })
            .popover(isPresented: $isDatePickerPresented, content: {
                DatePicker("", selection: $modalManager.selectedDate, displayedComponents: .date)
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .frame(minWidth:300, minHeight: 300)
                    .padding()
            })
        }
    }
    func dateOnly(date: Date, calendar: Calendar) -> Date {
        let yearComponent = calendar.component(.year, from: date)
        let monthComponent = calendar.component(.month, from: date)
        let dayComponent = calendar.component(.day, from: date)
        let zone = calendar.timeZone
        
        let newComponents = DateComponents(timeZone: zone,
                                           year: yearComponent,
                                           month: monthComponent,
                                           day: dayComponent)
        let returnValue = calendar.date(from: newComponents)
        
        //    let returnValue = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: date)
        
        
        return returnValue!
    }
    
    func moveDate(_ date: Date) {
        let offsetDate = dateOnly(date: date, calendar: data.customDayView!.calendar)
        data.customDayView!.state?.move(to: offsetDate)
//        print("DAY VIEW", data.customDayView!)
    }
}


