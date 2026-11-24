import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
    // CarPlay can launch the app before any phone window is connected.
    let engine = FlutterEngine(name: "demixr")

    lazy var carPlayChannel = FlutterMethodChannel(
        name: "com.demixr.demixrApp/carplay",
        binaryMessenger: engine.binaryMessenger
    )

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        engine.run()
        GeneratedPluginRegistrant.register(with: engine)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}

class PhoneSceneDelegate: FlutterSceneDelegate {
    override func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene,
              let app = UIApplication.shared.delegate as? AppDelegate else { return }

        // The CarPlay scene runs alongside one Flutter phone window.
        guard app.engine.viewController == nil else {
            UIApplication.shared.requestSceneSessionDestruction(session, options: nil)
            return
        }

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = FlutterViewController(engine: app.engine, nibName: nil, bundle: nil)
        self.window = window
        registerSceneLifeCycle(with: app.engine)
        super.scene(scene, willConnectTo: session, options: connectionOptions)
        window.makeKeyAndVisible()
    }

    override func sceneDidDisconnect(_ scene: UIScene) {
        super.sceneDidDisconnect(scene)
        if let app = UIApplication.shared.delegate as? AppDelegate {
            unregisterSceneLifeCycle(with: app.engine)
        }
        window = nil
    }
}
