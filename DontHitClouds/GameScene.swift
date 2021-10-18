//
//  GameScene.swift
//  DontHitClouds
//
//  Created by Ian Cowan on 12/4/20.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var darkMode: Bool = false
    var beforeStartOverlay: SKNode = SKNode()
    
    var airplane: SKSpriteNode = SKSpriteNode()
    var airplaneZRotation: CGFloat = 0
    var gameRunning: Bool = false
    var gameStartable: Bool = true
    var touchStart: Bool = false
    
    var cloud: SKSpriteNode = SKSpriteNode()
    var moveAndRemove: SKAction = SKAction()
    
    var milesLabel: SKLabelNode = SKLabelNode()
    var mileMarkers: [(SKSpriteNode, Bool)] = [] // Bool - TRUE: removed, FALSE: not removed
    var miles: Int = 0
    
    override func didMove(to view: SKView) {
        self.loadNewGame()
    }
    
    // Call this to reload
    func loadNewGame() {
        self.physicsWorld.contactDelegate = self
        self.physicsWorld.gravity = CGVector(dx: 0, dy: -1.62)
        self.loadBackground()
        self.loadBeforeStartOverlay()
        self.loadAirplane()
    }
    
    func loadBackground() {
        // Get the background
        var background = SKSpriteNode(imageNamed: "Background")
        milesLabel.fontColor = SKColor.black
        if darkMode {
            background = SKSpriteNode(imageNamed: "BackgroundDark")
            milesLabel.fontColor = SKColor.gray
        }
        
        let aspectRatio = background.frame.height / background.frame.width
        background.size = CGSize(width: self.frame.width, height: self.frame.width * aspectRatio)
        background.zPosition = 0
        
        // Now, we want to adjust the positioning of the background so that it
        // will not overflow on the bottom, but fits to the screen
        let displaySize: CGRect = UIScreen.main.bounds
        background.position = CGPoint(x: self.frame.width / 2, y: (self.frame.height / 2)  + (background.frame.height - displaySize.height) / 4)
        
        // Setup the ground for the falling airplane
        let ground = SKSpriteNode()
        ground.position = CGPoint(x: self.frame.width / 2, y: self.frame.minY)
        ground.size = CGSize(width: self.frame.width, height: 1)
        
        // Setup the ground physics
        ground.physicsBody = SKPhysicsBody(rectangleOf: ground.size)
        ground.physicsBody?.affectedByGravity = false
        ground.physicsBody?.isDynamic = false
        ground.physicsBody?.categoryBitMask = PhysicsCategories.ground
        ground.physicsBody?.collisionBitMask = PhysicsCategories.airplane
        ground.physicsBody?.contactTestBitMask = PhysicsCategories.airplane
        
        // Setup the ceiling so there's no cheating...
        let ceiling = SKSpriteNode()
        ceiling.position = CGPoint(x: self.frame.width / 2, y: self.frame.maxY + 100)
        ceiling.size = CGSize(width: self.frame.width, height: 100)
        
        // Setup ceiling physics
        ceiling.physicsBody = SKPhysicsBody(rectangleOf: ceiling.size)
        ceiling.physicsBody?.affectedByGravity = false
        ceiling.physicsBody?.isDynamic = false
        ceiling.physicsBody?.categoryBitMask = PhysicsCategories.ceiling
        ceiling.physicsBody?.collisionBitMask = PhysicsCategories.airplane
        ceiling.physicsBody?.contactTestBitMask = PhysicsCategories.airplane
        
        // Setup the miles label
        milesLabel.text = "\(miles)"
        milesLabel.fontName = "AvenirNext-Bold"
        milesLabel.position = CGPoint(x: self.frame.width / 2, y: (self.frame.height / 2) + (self.frame.height / 4))
        milesLabel.zPosition = 3
        
        // Add the background and ground
        self.addChild(background)
        self.addChild(milesLabel)
        self.addChild(ground)
        self.addChild(ceiling)
    }
    
    func loadBeforeStartOverlay() {
        //TODO: Overlay
    }
    
    func loadAirplane() {
        // Get the airplane
        let airplaneTexture = SKTexture(imageNamed: "Airplane")
        airplane = SKSpriteNode(texture: airplaneTexture)
        
        // Setup the airplane
        airplane.setScale(0.75)
        airplane.position = CGPoint(x: self.frame.width / 2, y: self.frame.height / 2)
        airplane.zPosition = 1
        
        // Setup the airplane's physics body
        airplane.physicsBody = SKPhysicsBody(texture: airplaneTexture, size: CGSize(width: airplane.size.width, height: airplane.size.height))
        airplane.physicsBody?.affectedByGravity = false
        airplane.physicsBody?.categoryBitMask = PhysicsCategories.airplane
        airplane.physicsBody?.collisionBitMask = PhysicsCategories.ground | PhysicsCategories.ceiling | PhysicsCategories.cloud
        airplane.physicsBody?.contactTestBitMask = PhysicsCategories.ground | PhysicsCategories.ceiling | PhysicsCategories.mileMarker | PhysicsCategories.cloud
        airplane.physicsBody?.isDynamic = true
        
        airplaneZRotation = airplane.zRotation
        
        // Add the airplane
        self.addChild(airplane)
    }
    
    func loadCloud() {
        // Generate the cloud (randomly)!
        let cloudTexture = SKTexture(imageNamed: "Cloud\(Int.random(in: 1...4))")
        cloud = SKSpriteNode(texture: cloudTexture)
        
        // Setup the cloud
        cloud.setScale(Random.nextCGFloat(min: 0.2, max: 0.5))
        cloud.position = CGPoint(x: self.frame.width + cloud.frame.width, y: self.frame.height / 2 + Random.nextCGFloat(min: -250, max: 400))
        cloud.zPosition = 2
        
        // Setup the cloud physics
        cloud.physicsBody = SKPhysicsBody(texture: cloudTexture, size: CGSize(width: cloud.size.width - 10, height: cloud.size.height - 10))
        cloud.physicsBody?.affectedByGravity = false
        cloud.physicsBody?.categoryBitMask = PhysicsCategories.cloud
        cloud.physicsBody?.collisionBitMask = PhysicsCategories.airplane
        cloud.physicsBody?.contactTestBitMask = PhysicsCategories.airplane
        cloud.physicsBody?.isDynamic = false
        
        // Move and then remove it
        cloud.run(moveAndRemove)
        
        // Add the cloud
        self.addChild(cloud)
    }
    
    func loadMileMarker() {
        // Generate the mile marker
        let mileMarker = SKSpriteNode()
        mileMarker.size = CGSize(width: 1, height: self.frame.height)
        mileMarker.position = CGPoint(x: self.frame.width, y: self.frame.height / 2)
        
        // Setup the physics body
        mileMarker.physicsBody = SKPhysicsBody(rectangleOf: mileMarker.size)
        mileMarker.physicsBody?.affectedByGravity = false
        mileMarker.physicsBody?.isDynamic = false
        mileMarker.physicsBody?.categoryBitMask = PhysicsCategories.mileMarker
        mileMarker.physicsBody?.collisionBitMask = 0
        mileMarker.physicsBody?.contactTestBitMask = PhysicsCategories.airplane
        
        // Move and then remove it
        mileMarker.run(moveAndRemove)
        
        // Add the mile marker
        self.addChild(mileMarker)
        mileMarkers.append((mileMarker, false))
    }
    
    func setupClouds(delayTime: Float) {
        let spawn = SKAction.run({ () in
            self.loadCloud()
        })
        
        let delay = SKAction.wait(forDuration: TimeInterval(delayTime))
        let spawnDelay = SKAction.sequence([spawn, delay])
        let spawnDelayClouds = SKAction.repeatForever(spawnDelay)
        self.run(spawnDelayClouds)
        
        let distance = CGFloat((self.frame.width + cloud.frame.width) * 5)
        let moveClouds = SKAction.moveBy(x: -distance, y: 0, duration: TimeInterval(0.0075 * distance))
        let removeClouds = SKAction.removeFromParent()
        moveAndRemove = SKAction.sequence([moveClouds, removeClouds])
    }
    
    func levelUp() {
        // Shorten the cloud delay
        self.setupClouds(delayTime: 2.0 - (Float(miles) / 100))
    }
    
    func initClouds() {
        // Default cloud delay of 2 sec
        self.setupClouds(delayTime: 2.0)
    }
    
    func setupMileMarkers() {
        let spawn = SKAction.run({ () in
            self.loadMileMarker()
        })
        
        let delay = SKAction.wait(forDuration: 4)
        let spawnDelay = SKAction.sequence([spawn, delay])
        let spawnDelayMileMarkers = SKAction.repeatForever(spawnDelay)
        self.run(spawnDelayMileMarkers)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !gameRunning && gameStartable {
            self.initClouds()
            self.setupMileMarkers()
            
            gameRunning = true
        }
        
        airplane.physicsBody?.affectedByGravity = false
        touchStart = true
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        airplane.physicsBody?.affectedByGravity = true
        touchStart = false
    }
    
    override func update(_ currentTime: TimeInterval) {
        if gameRunning {
            airplane.zRotation = airplaneZRotation + (airplane.physicsBody?.velocity.dy ?? 0) * 0.001
            
            airplane.position.x = self.frame.width / 2
            airplane.physicsBody?.velocity.dx = 0
        }
        
        if gameRunning && touchStart {
            airplane.physicsBody?.applyForce(CGVector(dx: 0, dy: airplane.frame.height * 1.5))
        }
    }
    
    func endGame(_ reason: Int) {
        // Stop the airplane from moving if it hit the ground
        if reason == EndGame.hitGround {
            airplane.physicsBody?.affectedByGravity = false
            airplane.physicsBody?.isDynamic = false
        }
        
        // Don't collide with the clouds while falling and don't add anymore to the score
        airplane.physicsBody?.collisionBitMask = PhysicsCategories.ground | PhysicsCategories.ceiling
        airplane.physicsBody?.contactTestBitMask = PhysicsCategories.ground | PhysicsCategories.ceiling
        
        // Now, let's stop the game if the game was running
        if (gameRunning) {
            gameRunning = false
            gameStartable = false
            self.removeAllActions()
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        let firstBody = contact.bodyA
        let secondBody = contact.bodyB
        
        // If the airplane hits the ground
        if firstBody.categoryBitMask == PhysicsCategories.airplane && secondBody.categoryBitMask == PhysicsCategories.ground || firstBody.categoryBitMask == PhysicsCategories.ground && secondBody.categoryBitMask == PhysicsCategories.airplane {
            self.endGame(EndGame.hitGround)
        }
        
        // If the airplane hits the ceiling
        if firstBody.categoryBitMask == PhysicsCategories.airplane && secondBody.categoryBitMask == PhysicsCategories.ceiling || firstBody.categoryBitMask == PhysicsCategories.ceiling && secondBody.categoryBitMask == PhysicsCategories.airplane {
            self.endGame(EndGame.hitCeiling)
        }
        
        // If the airplane hits a cloud
        if firstBody.categoryBitMask == PhysicsCategories.airplane && secondBody.categoryBitMask == PhysicsCategories.cloud || firstBody.categoryBitMask == PhysicsCategories.cloud && secondBody.categoryBitMask == PhysicsCategories.airplane {
            self.endGame(EndGame.hitCloud)
        }
        
        // Keeps track of the score every time the airplane hits a mile marker
        if firstBody.categoryBitMask == PhysicsCategories.airplane && secondBody.categoryBitMask == PhysicsCategories.mileMarker || firstBody.categoryBitMask == PhysicsCategories.mileMarker && secondBody.categoryBitMask == PhysicsCategories.airplane {
            if mileMarkers.count > 0 && !mileMarkers[0].1 {
                mileMarkers[0].1 = true
                miles += 1
                milesLabel.text = "\(miles)"
                
                // Remove the contacted mile marker
                mileMarkers[0].0.removeFromParent()
                mileMarkers.remove(at: 0)
                
                // Every 10 miles, make it slightly harder
                if miles <= 100 && miles % 10 == 0 {
                    self.levelUp()
                }
            }
        }
    }
    
}

struct PhysicsCategories {
    static let airplane: UInt32 = 0x1 << 1
    static let ground: UInt32 = 0x1 << 2
    static let ceiling: UInt32 = 0x1 << 3
    static let cloud: UInt32 = 0x1 << 4
    static let mileMarker: UInt32 = 0x1 << 5
}

struct EndGame {
    static let hitCeiling = 0
    static let hitGround = 1
    static let hitCloud = 2
}

struct Random {
    static func nextInt() -> Int {
        return Int(arc4random()) / 0xFFFFFFFF
    }
    
    static func nextInt(min: Int, max: Int) -> Int {
        return nextInt() * (max - min) + min
    }
    
    static func nextCGFloat() -> CGFloat {
        return CGFloat(Float(arc4random())) / 0xFFFFFFFF
    }
    
    static func nextCGFloat(min: CGFloat, max: CGFloat) -> CGFloat {
        return nextCGFloat() * (max - min) + min
    }
}
