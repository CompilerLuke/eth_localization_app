import UIKit
import SwiftUI

struct MyCustomKey: EnvironmentKey {
    static var defaultValue: String = "Default Value"
}

extension EnvironmentValues {
    var serverURL: String {
        get { self[MyCustomKey.self] }
        set { self[MyCustomKey.self] = newValue }
    }
}

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // Create the SwiftUI view that provides the window contents.
        let serverURL = "http://192.168.1.107:3001/"
        
        let app_theme = AppTheme()
        
        let localizerSession = LocalizerSession(serverURL: serverURL)
        let buildingService = BuildingService(serverURL: serverURL, building: 1)
        let navigationSession = NavigationSession(serverURL: serverURL, localizerSession: localizerSession)
        let contentView = ContentView()
            .environmentObject(localizerSession)
            .environmentObject(buildingService)
            .environmentObject(navigationSession)
            .environmentObject(app_theme)
        
        UINavigationBar.appearance().backgroundColor = UIColor(app_theme.card1_bg)

        // Use a UIHostingController as window root view controller.
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = UIHostingController(rootView: contentView)
        self.window = window
        window.makeKeyAndVisible()
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }


}
