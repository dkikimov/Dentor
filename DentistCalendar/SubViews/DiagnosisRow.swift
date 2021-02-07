//
//  DiagnosisRow.swift
//  DentistCalendar
//
//  Created by Даник 💪 on 16.01.2021.
//

import SwiftUI

struct DiagnosisRow: View {
    @EnvironmentObject var data: AppointmentCreateViewModel
    @State var isSelected = false
    var diag: Diagnosis
    var body: some View {
        Button (action:{
            isSelected.toggle()
            if data.selectedDiagnosisList[diag.text!] != nil {
                data.selectedDiagnosisList.removeValue(forKey: diag.text!)
            } else {
                data.selectedDiagnosisList[diag.text!] = Favor(price: diag.price!.decimalValue.formatted, prePayment: "")
                print("SELECTED DIAGNOSIS LIST", data.selectedDiagnosisList)
            }
        },label: {
            HStack {
                Text(diag.text ?? "Error").foregroundColor(isSelected ? .blue : Color("Black1"))
                Spacer()
//                Text("Цена: \(diag.price != nil ? diag.price!.stringValue : "0")")
                Text("Цена: \(diag.price != nil ? diag.price!.decimalValue.formatted : "0")")

                    .foregroundColor(isSelected ? .blue : Color("Black1")).multilineTextAlignment(.trailing)
            }
        })
        .onAppear(perform: {
            isSelected = data.selectedDiagnosisList[diag.text!] != nil
        })
    }
}

//struct DiagnosisRow_Previews: PreviewProvider {
//    static var previews: some View {
//        DiagnosisRow()
//    }
//}