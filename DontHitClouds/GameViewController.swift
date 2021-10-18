//
//  GameViewController.swift
//  DontHitClouds
//
//  Created by Ian Cowan on 12/4/20.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {
    
    private let backgroundColor: SKColor = UIColor(red: 181 / 255, green: 101 / 255, blue: 30 / 255, alpha: 1.0)

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let view = self.view as! SKView? {
            // Setup the settings if nothing can be found
            setupSettings()
            
            let scene = GameScene(size: CGSize(width: 428, height: 926))
            // Set the scale mode to scale to fit the window
            scene.scaleMode = .aspectFill
            scene.backgroundColor = backgroundColor
            
            // Setup dark mode if applicable
            if UserSettings.mode == Modes.system && traitCollection.userInterfaceStyle == .dark || UserSettings.mode == Modes.dark {
                scene.darkMode = true
            }
            
            // Present the scene
            view.presentScene(scene)
            
            view.ignoresSiblingOrder = true
        }
    }
    
    func setupSettings() {
        let defaults = UserDefaults.standard
        
        // Setup the default settings if nothing is found
        if defaults.object(forKey: SettingKeys.ads) == nil {
            defaults.setValue(true, forKey: SettingKeys.ads)
            defaults.setValue(Modes.system, forKey: SettingKeys.mode)
        }
        
        // Now, make sure the settings are set correctly
        UserSettings.ads = defaults.value(forKey: SettingKeys.ads) as! Bool
        UserSettings.mode = defaults.value(forKey: SettingKeys.mode) as! Int
    }

    override var shouldAutorotate: Bool {
        return false
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

struct SettingKeys {
    static let ads: String = "ADS"
    static let mode: String = "MODE"
}

struct Modes {
    static let system = 0
    static let light = 1
    static let dark = 2
}

struct UserSettings {
    static var ads: Bool = true
    static var mode: Int = Modes.system
}
