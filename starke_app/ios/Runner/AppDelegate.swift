import UIKit
import Flutter
import Firebase
import AppTrackingTransparency 
import google_mobile_ads


@main
@objc class AppDelegate: FlutterAppDelegate {

          private let reelsChannelName = "com.news.wrteam/reels_deeplink"
          private var pendingReelsUrl: String?
          private var reelsChannel: FlutterMethodChannel?

          override func application(
              _ application: UIApplication,
              didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
          ) -> Bool {
              FirebaseApp.configure()
              GeneratedPluginRegistrant.register(with: self)
              if #available(iOS 10.0, *) {
                  UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
              }

//              MobileAds.shared.requestConfiguration.setPublisherFirstPartyIDEnabled(false)
              GADMobileAds.sharedInstance().requestConfiguration.setPublisherFirstPartyIDEnabled(false)
              if let url = launchOptions?[.url] as? URL {
                  cacheReelsUrlIfNeeded(url.absoluteString)
              }

              let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)

              DispatchQueue.main.async { [weak self] in
                  self?.setupReelsChannel()
              }

              return result
          }

          override func application(
              _ app: UIApplication,
              open url: URL,
              options: [UIApplication.OpenURLOptionsKey: Any] = [:]
          ) -> Bool {
              if url.absoluteString.contains("/reels") {
                  cacheAndNotifyReels(url.absoluteString)
                  return true
              }
              return super.application(app, open: url, options: options)
          }

          override func application(
              _ application: UIApplication,
              continue userActivity: NSUserActivity,
              restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
          ) -> Bool {
              if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
                 let url = userActivity.webpageURL,
                 url.absoluteString.contains("/reels") {
                  cacheAndNotifyReels(url.absoluteString)
                  return true
              }
              return super.application(
                  application,
                  continue: userActivity,
                  restorationHandler: restorationHandler
              )
          }

          override func applicationDidBecomeActive(_ application: UIApplication) {
              if #available(iOS 15.0, *) {
                  ATTrackingManager.requestTrackingAuthorization(completionHandler: { _ in })
              }
          }

          private func setupReelsChannel() {
              guard let controller = window?.rootViewController as? FlutterViewController else {
                  return
              }
              let channel = FlutterMethodChannel(
                  name: reelsChannelName,
                  binaryMessenger: controller.binaryMessenger
              )
              channel.setMethodCallHandler { [weak self] call, result in
                  if call.method == "getInitialReelsLink" {
                      result(self?.pendingReelsUrl)
                  } else {
                      result(FlutterMethodNotImplemented)
                  }
              }
              reelsChannel = channel
          }

          private func cacheReelsUrlIfNeeded(_ url: String?) {
              guard let url = url, url.contains("/reels") else { return }
              pendingReelsUrl = url
          }

          private func cacheAndNotifyReels(_ url: String) {
              guard url.contains("/reels") else { return }
              pendingReelsUrl = url
              reelsChannel?.invokeMethod("onReelsLink", arguments: url)
          }
      }
class AppLinks {

    var window: UIWindow?

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return handleDeepLink(url: url)
    }

    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
           let url = userActivity.webpageURL {
            return handleDeepLink(url: url)
        }
        return false
    }

    private func handleDeepLink(url: URL) -> Bool {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return false
        }

        if let urlPattern = components.path.split(separator: "/").last {
             return true
        }

        return false
    }

}
