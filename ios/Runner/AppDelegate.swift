import UIKit
import Flutter
import FirebaseAuth
import Firebase
import FirebaseMessaging
import GoogleMaps


@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }
    GMSServices.provideAPIKey("AIzaSyDlE8fe6amRsClOzkM8_X7LHE6EaBfp8bM")
    
    application.registerForRemoteNotifications()

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
    
    //Auth
    override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
         Messaging.messaging().apnsToken = deviceToken
               let firebaseAuth = Auth.auth()
               firebaseAuth.setAPNSToken(deviceToken, type: AuthAPNSTokenType.unknown)
        super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
     }
     override func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
               let firebaseAuth = Auth.auth()
               if (firebaseAuth.canHandleNotification(userInfo)){
                   print(userInfo)
                   return
               }
    }
}
