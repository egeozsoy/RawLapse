//
//  AppDelegate.swift
//  RawLapse
//
//  Created by Ege on 20.10.17.
//  Copyright © 2017 Ege. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var cameraWindow: UIWindow?
    let cameraViewController = CameraViewController()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        cameraWindow = UIWindow(frame: UIScreen.main.bounds)
        cameraWindow?.makeKeyAndVisible()
        cameraWindow?.rootViewController = cameraViewController
        
        UIApplication.shared.isIdleTimerDisabled = true
        
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        cameraViewController.fixBrightness()
        cameraViewController.forceLockScreenDimming = true
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        cameraViewController.stopUpdateTimer()
        cameraViewController.fixBrightness()
        cameraViewController.forceLockScreenDimming = true
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        cameraViewController.startUpdateTimer()
        cameraViewController.forceLockScreenDimming = false
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        cameraViewController.startUpdateTimer()
        cameraViewController.forceLockScreenDimming = false
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        cameraViewController.stopUpdateTimer()
        cameraViewController.fixBrightness()
        cameraViewController.forceLockScreenDimming = true
    }
}

