//
//  AppDelegate.swift
//  PointerContinuity
//
//  Created by Christoph Parstorfer on 24.04.21.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate, ObservableObject {
    //@Published var isExternalScreenConnected = false
    
    var viewController: ViewController!
    private var externalWindow: UIWindow?
    var externalVC: UIViewController? /// only stored to work around external display not following system appearance
    var externalDisplayArrangement: ExternalDisplayArrangement?
    var externalPointerView: PointerView?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        /// Handle disconnected display
        /// TODO this should be handled in the SceneDelegate instead
        NotificationCenter.default.addObserver(forName: UIScreen.didDisconnectNotification, object: nil, queue: nil) { _ in
            DispatchQueue.main.async {
                self.externalVC = nil
                self.externalWindow = nil
                self.externalDisplayArrangement = nil
            }
        }
        return true
    }
    
    private func setupExternalScreen(session: UISceneSession, options: UIScene.ConnectionOptions) {
        let newWindow = UIWindow()
        let windowScene = UIWindowScene(session: session, connectionOptions: options)
        newWindow.windowScene = windowScene
        externalWindow = newWindow
        let externalVC = UIViewController()
        self.externalVC = externalVC
        let pointerView = PointerView()
        viewController.createUnlockButton(for: pointerView)
        externalPointerView = pointerView
        pointerView.setupCursorWithImage(UIImage(named: "defaultCursor")!)
        externalVC.view.addSubview(pointerView)
        pointerView.pointerPosition = nil
        externalVC.view.backgroundColor = .systemBackground
        newWindow.rootViewController = externalVC
        
        externalDisplayArrangement = ExternalDisplayArrangement.PlacedRelativeToMainScreen(UIScreen.main, at: .trailing, externalScreen: windowScene.screen)
        pointerView.positionOffset = externalDisplayArrangement!.externalBounds.origin
        newWindow.isHidden = false
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // is external display?
        if connectingSceneSession.configuration.role == UISceneSession.Role.windowExternalDisplay {
            setupExternalScreen(session: connectingSceneSession, options: options)

            return UISceneConfiguration(name: "External screen", sessionRole: .windowExternalDisplay)
        } else {
            // Called when a new scene session is being created.
            // Use this method to select a configuration to create the new scene with.
            return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
        }
    }
}

