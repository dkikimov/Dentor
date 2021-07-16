
import SwiftUI
import Amplify
import ApphudSDK
//import Adapty
struct CalendarDayView: View {
    @State var tabSelection: Tabs = .tab1
    @EnvironmentObject var modalManager: ModalManager
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State var activeView: DestinationTypes = .calendar
    @AppStorage("introductionInstruction") var isWalkthroughPresented = true
//    @State var isWalkthroughPresented = true

    var body: some View {
        //        VStack {
//        if UIDevice.current.userInterfaceIdiom == .phone {
            
            
            TabView(selection: $tabSelection) {
                
                CalendarKitView()
                    .tag(Tabs.tab1)
                    .tabItem({
                        Image(systemName: "calendar")
                        Text("Календарь")
                        
                    })
                
                PatientsListView()
                    .tag(Tabs.tab2)
                    .tabItem({
                        Image(systemName: "person.3.fill")
                        Text("Пациенты")
                    })
            }
            .transition(.opacity)
            .fullScreenCover(isPresented: $isWalkthroughPresented, content: {
                WalktroughView(isWalkthroughViewShowing: $isWalkthroughPresented)
            })
            .onAppear {
                let userID = Amplify.Auth.getCurrentUser()!.userId
//                Adapty.identify(userID) { (error) in
//                    if error != nil {
//                        print("ERROR when identifying user", error)
//                    }
//                }
                Apphud.startManually(apiKey: "app_NLE7uVfdajb1hbJHYguEuoBf5zgy65", userID: userID, deviceID: userID)

            }
    }
    @ViewBuilder
    func view(for destination: DestinationTypes) -> some View {
        switch destination {
        case .calendar:
            CalendarKitView()
        case .patients:
            PatientsListView()
        case .settings:
            ProfileSettingsView()
        }
    }
}
//func returnNaviBarTitle(tabSelection: Tabs) -> String{//this function will return the correct NavigationBarTitle when different tab is selected.
//    switch tabSelection{
//    case .tab1: return "Календарь"
//    case .tab2: return "Пациенты"
//    }
//}
//func returnDisplayMode(tabSelection: Tabs) -> NavigationBarItem.TitleDisplayMode{//this function will return the correct NavigationBarTitle when different tab is selected.
//    switch tabSelection{
//    case .tab1: return .inline
//    case .tab2: return .large
//    }
//}
//func returnBarItems(tabSelection: Tabs) ->  View? {
//    switch tabSelection{
//    case .tab1: return NavigationLink(destination: ProfileSettingsView(), label: {
//        Image(systemName: "gearshape.fill").font(.title3)
//    })
//    default: return nil
//    }
//}
