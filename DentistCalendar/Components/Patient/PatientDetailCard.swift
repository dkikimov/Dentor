//
//  PatientDetailCard.swift
//  DentistCalendar
//
//  Created by Даник 💪 on 10/20/20.
//

import SwiftUI

func stringToDate(date: String) -> String {
    let convertedDate = Date(timeIntervalSince1970: Double(date)!)
    let dateFormatter = DateFormatter() //Set timezone that you want
    dateFormatter.locale = Locale.init(identifier: Locale.preferredLanguages.first!)
    dateFormatter.dateFormat = "d MMMM YYYY - HH:mm" //Specify your format that you want
    let strDate = dateFormatter.string(from: convertedDate)
    return strDate
}
/// TODO: Fix Index Bug
struct PatientDetailCard: View {
    var appointment: Appointment
    @ObservedObject var detailViewModel: PatientDetailViewModel
    var index: Int
    var detailButtonAction: () -> Void
    var moreButtonAction: () -> Void
    @State var serviceSum: Decimal = 0.0
    @State var servicePaid: Decimal = 0.0
    var body: some View {
        Button(action: {
            detailButtonAction()
        }, label: {
            VStack(alignment: .leading) {
                HStack(alignment: .center, spacing:3){
                    Image("tooth").resizable().aspectRatio(contentMode: .fit)
                        .frame(width: 18, height: 18)
                        .padding(.horizontal, 10)
                        .foregroundColor(Color("Gray1"))
                    Text("Зуб:")
                    Text(String(appointment.toothNumber ?? "Пусто".localized)).fontWeight(.bold)
                    Spacer()
                }
                HStack(alignment: VerticalAlignment.firstTextBaseline, spacing:3){
                    Image("id-card").resizable().aspectRatio(contentMode: .fit).frame(width: 18, height: 18).offset(y: 2)
                        .foregroundColor(Color("Gray1")).padding(.horizontal, 10)
                    
                    Text("Услуги: ") +
                    Text(convertDiagnosisString(str: appointment.diagnosis!))
                        .fontWeight(.bold)
                }.lineLimit(3)
                HStack(alignment: VerticalAlignment.firstTextBaseline, spacing:3){
                    Image(systemName: "calendar").resizable().aspectRatio(contentMode: .fit).frame(width: 18, height: 18).offset(y: 2)
                        .foregroundColor(Color("Gray1")).padding(.horizontal, 10)
                    Text("Дата: ") + Text(stringToDate(date: appointment.dateStart))
                        .fontWeight(.bold)
                    
                }
                if appointment.payments != nil && !appointment.diagnosis!.isEmpty {
                    HStack {
                        VStack(spacing: 2) {
                            HStack {
                                Text(detailViewModel.sumServices[index]?.0 ?? "" + " " + String(describing: Locale.current.currencySymbol ?? ""))
                                    .bold()
                                    .font(.footnote)
                                    .foregroundColor(.gray)
                                    .lineLimit(1)
                                Spacer()
                                Text(detailViewModel.sumServices[index]?.1 ?? "" + " " + String(describing: Locale.current.currencySymbol ?? ""))
                                    .bold()
                                    .font(.footnote)
                                    .lineLimit(1)
                            }
                            ProgressView(
                                value: detailViewModel.sumServices[index, default: ("0", "0")].0.getNumber,
                                total: detailViewModel.sumServices[index, default: ("0", "0")].1.getNumber)
                            .scaleEffect(x: 1, y: 1.5, anchor: .center)
                            .progressViewStyle(LinearProgressViewStyle())
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top, 12)
                }
            }
            
            
            .padding(20)
            .background(Color("White1"))
            .cornerRadius(20)
            .foregroundColor(Color("Black1"))
        })
        .overlay(
            Button(action: moreButtonAction) {
                Image(systemName: "ellipsis")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 18, height: 18)
                    .foregroundColor(Color("Gray1"))
                    .rotationEffect(.init(degrees: 90))
                    .padding(.horizontal, 15)
                    .padding(.top, 3)
                    .padding()
            }
            
            , alignment: .topTrailing
        )
        .onAppear(perform: {
            let res = countBilling(appointment: appointment)
            self.servicePaid = res.0
            self.serviceSum = res.1
            if serviceSum < servicePaid {
                self.serviceSum = servicePaid
            }
            self.detailViewModel.sumServices[index] = (self.servicePaid.currencyFormatted, self.serviceSum.currencyFormatted)
        })
    }
}
