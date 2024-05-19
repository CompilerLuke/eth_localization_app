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

        let app_theme = AppTheme()

        let factory = createServiceFactory()

        let localizationService = factory.createLocalizationService()
        let buildingService = factory.createBuildingService()
        let navigationService = factory.createNavigationService()

        let localizerSession = LocalizerSession(localizationService: localizationService)
        let navigationSession = NavigationSession(navigationService: navigationService, localizerSession: localizerSession)
        let contentView = MainContentView()
            .environmentObject(localizerSession)
            .environmentObject(buildingService)
            .environmentObject(navigationSession)
            .environmentObject(app_theme)

        let controller = UIHostingController(rootView: contentView)

        

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = controller
        self.window = window
        window.makeKeyAndVisible()
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Handle the transition from active to inactive state.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Handle the transition to the background.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Handle the transition from the background to the foreground.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any paused tasks.
    }
}

