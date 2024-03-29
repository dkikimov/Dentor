//
//  EventAddViewModel.swift
//  DentistCalendar
//
//  Created by Даник 💪 on 28.11.2020.
//

import SwiftUI
import EventKit
import Amplify

let options: NSLinguisticTagger.Options = [.omitPunctuation, .omitWhitespace, .joinNames]
let tags: [NSLinguisticTag] = [.personalName]
let detectorType: NSTextCheckingResult.CheckingType = [.phoneNumber]

class EventAddViewModel: ObservableObject {
    @Published var eventStore = EKEventStore()
    @Published var calendars: Set<EKCalendar>?
    @Published var isSheetPresented = false
    @Published var isEditMode: EditMode = .active
    @Published var eventsList = [EKEvent]()
    @Published var selectedEvents = [EKEvent]()
    @Published var isLoading: Bool = false
    @Published var errorText = ""
    var wasCalled: Bool = false
    func requestAccess(completion: @escaping (Bool, Error?) -> () ) {
        eventStore.requestAccess(to: .event) { (status, err) in
            if err != nil {
                self.errorText = err!.localizedDescription
            }
            DispatchQueue.main.async {
                completion(status, err)
            }
        }
    }
    
    func getEvents(){
        requestAccess { (status, err) in
            if err != nil {
                return
            }
            if status {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                
                let startDate = Date().addingTimeInterval(-2678400)
                let endDate = Date().addingTimeInterval(7776000)
                
                DispatchQueue.main.async {
                    let eventsPredicate = self.eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: Array(self.calendars ?? []))
                    self.eventsList = self.eventStore.events(matching: eventsPredicate)
                    self.selectedEvents = self.eventsList.map { $0 }
                }
                
            }
            
        }
        
    }
    func addEvents(_ presentationMode: Binding<PresentationMode>) {
        isLoading = true
        
        for i in selectedEvents {
            let data = i.title
            var isWithPatient: Bool = false
            var patientName = String(i.title.split(separator: " ")[0]).trimmingCharacters(in: .whitespaces)
            let tagger = NSLinguisticTagger(tagSchemes: [.nameType], options: 0)
            tagger.string = data
            let range = NSRange(location: 0, length: data!.utf16.count)
            var phone = ""
            tagger.enumerateTags(in: range, unit: .word, scheme: .nameType, options: options) { tag, tokenRange, stop in
                if let tag = tag, tags.contains(tag) {
                    if let range = Range(tokenRange, in: data!) {
                        let name = data![range]
                        if tag == .personalName {
                            patientName = String(name)
                            isWithPatient = true
                        }
                    }
                }
            }
            do {
                let detector = try NSDataDetector(types: detectorType.rawValue)
                let results = detector.matches(in: data!, options: [], range: NSRange(location: 0, length:
                                                                                        data!.utf16.count))
                
                for result in results {
                    if let range = Range(result.range, in: data!) {
                        let matchResult = data![range]
                        phone = String(matchResult)
                        isWithPatient = true
                    }
                }
                
            } catch {
                isLoading = false
            }
            if isWithPatient {
                Amplify.DataStore.query(Patient.self, where: Patient.keys.fullname == patientName) { res in
                    switch res {
                    case .success(let patients):
                        if patients.count > 0 {
                            let newAppointment = Appointment(title: patients[0].fullname, patientID: patients[0].id, toothNumber: "", diagnosis: "", dateStart: strFromDate(date: i.startDate), dateEnd: strFromDate(date: i.endDate))
                            _ = Amplify.DataStore.save(newAppointment)
                        } else if patients.count == 0{
                            let newPatient = Patient(fullname: String(patientName.capitalized.prefix(patientNameMaxLength)), phone: phone.replacingOccurrences(of: " ", with: ""))
                            
                            Amplify.DataStore.save(newPatient) { result in
                                switch result {
                                case .success(let pat):
                                    let newAppointment = Appointment(title: patientName, patientID: pat.id, toothNumber: "", diagnosis: "", dateStart: strFromDate(date: i.startDate), dateEnd: strFromDate(date: i.endDate))
                                    _ = Amplify.DataStore.save(newAppointment)
                                    
                                case .failure(let error):
                                    print("ERROR SAVING PATIENT", error.errorDescription)
                                    
                                }
                                
                            }
                            
                        }
                        break
                    case .failure(let error):
                        break
                    }
                    isLoading = false
                    
                }
            } else {
                let newAppointment = Appointment(title: data!, dateStart: strFromDate(date: i.startDate), dateEnd: strFromDate(date: i.endDate))
                _ = Amplify.DataStore.save(newAppointment)
            }
            
        }
        DispatchQueue.main.async {
            self.isLoading = false
            presentSuccessAlert(message: "Записи были успешно импортированы!")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
            
            presentationMode.wrappedValue.dismiss()
        })
    }
}
