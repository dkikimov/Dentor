////
////  RewardedAd.swift
////  SwiftUIMobileAds
////
////  Created by Patrick Haertel on 5/23/21.
////
//
//import GoogleMobileAds
//import SwiftUI
//import UIKit
//
//class RewardedAd: NSObject {
//    var rewardedAd: GADRewardedAd?
//    static let shared = RewardedAd()
//    
//    func loadAd(withAdUnitId id: String) {
//        let req = GADRequest()
//        GADRewardedAd.load(withAdUnitID: id, request: req) { rewardedAd, err in
//            if let err = err {
//                print("Failed to load ad with error: \(err)")
//                return
//            }
//            
//            self.rewardedAd = rewardedAd
//        }
//    }
//}
//
//final class RewardedAdView: NSObject, UIViewControllerRepresentable, GADFullScreenContentDelegate {
//    
//    let rewardedAd = RewardedAd.shared.rewardedAd
//    @Binding var isPresented: Bool
//    @Binding var isModalPresented: Bool
//    @Binding var wasRewardedVideoChecked: Bool
//    let adUnitId: String
//    let rewardFunc: (() -> Void)
//    var wasAdViewed: Bool
//    init(isPresented: Binding<Bool>, isModalPresented: Binding<Bool>, wasRewardedVideoChecked: Binding<Bool>, adUnitId: String, rewardFunc: @escaping (() -> Void)) {
//        self._isPresented = isPresented
//        self._isModalPresented = isModalPresented
//        self._wasRewardedVideoChecked = wasRewardedVideoChecked
//        self.adUnitId = adUnitId
//        self.rewardFunc = rewardFunc
//        self.wasAdViewed = false
//        super.init()
//        
//        rewardedAd?.fullScreenContentDelegate = self
//    }
//    
//    func makeUIViewController(context: Context) -> UIViewController {
//        let view = UIViewController()
//        
//        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1)) {
//            self.showAd(from: view)
//        }
//        
//        return view
//    }
//
//    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
//        
//    }
//    
//    func showAd(from root: UIViewController) {
//        
//        if let ad = rewardedAd {
//            ad.present(fromRootViewController: root, userDidEarnRewardHandler: {
//                    self.wasRewardedVideoChecked = true
//                    self.rewardFunc()
//            })
//        } else {
//            print("Ad not ready")
//            self.isPresented.toggle()
//        }
//    }
//    
//    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
//        RewardedAd.shared.loadAd(withAdUnitId: adUnitId)
////        if wasRewardedVideoChecked {
////            isModalPresented = false
////        }
//        isPresented.toggle()
////        wasRewardedVideoChecked = false
//    }
//}
