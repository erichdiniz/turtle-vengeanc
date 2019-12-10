

import SpriteKit

struct PhysicsCategory {
    static let none      : UInt32 = 0
    static let all       : UInt32 = UInt32.max
    static let monster   : UInt32 = 0b1       // 1
    static let projectile: UInt32 = 0b10      // 2
}

func +(left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func -(left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

func *(point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x * scalar, y: point.y * scalar)
}

func /(point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x / scalar, y: point.y / scalar)
}

#if !(arch(x86_64) || arch(arm64))
func sqrt(a: CGFloat) -> CGFloat {
    return CGFloat(sqrtf(Float(a)))
}
#endif

extension CGPoint {
    func length() -> CGFloat {
        return sqrt(x*x + y*y)
    }
    
    func normalized() -> CGPoint {
        return self / length()
    }
}

class GameScene: SKScene {
    let player = SKSpriteNode(imageNamed: "player")
    var monstersDestroyed = 0 {
        didSet {
            scoreLabel.text = "Score: \(monstersDestroyed)"
        }
    }
    var scoreLabel: SKLabelNode!

    
    override func didMove(to view: SKView){
        backgroundColor = SKColor.lightGray
        player.position = CGPoint(x: size.width * 0.1, y: size.height * 0.5)
        player.zPosition = 1
        createGround()
        addChild(player)
        
        run(SKAction.repeatForever(SKAction.sequence([SKAction.run(addTrash), SKAction.wait(forDuration: 1.0)])))
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
        
        let backgroundMusic = SKAudioNode(fileNamed: "background-music-aac.caf")
        backgroundMusic.autoplayLooped = true
        addChild(backgroundMusic)
        
        scoreLabel = SKLabelNode(fontNamed: "Chalkduster")
        scoreLabel.text = "Score: 0"
        scoreLabel.horizontalAlignmentMode = .right
        scoreLabel.position = CGPoint(x: size.width/2, y: size.height - scoreLabel.fontSize)
        scoreLabel.zPosition = 1
        addChild(scoreLabel)
    }
    
    
    func random() -> CGFloat{
        return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
    }
    
    
    func random(min: CGFloat, max:CGFloat) -> CGFloat{
        return random() * (max - min) + min
    }
    
    
    func addTrash(){
        // Create sprite
        let monster = SKSpriteNode(imageNamed: "monster")
        let monster2 = SKSpriteNode(imageNamed: "monster2")
        // Determine where to spawn the monster along the Y axis
        let actualY = random(min: monster.size.height, max: size.height/2 - monster.size.height)
        let actualY2 = random(min: 200, max: size.height - monster2.size.height)
        monster.position = CGPoint(x: size.width + monster.size.width, y: actualY)
        monster2.position = CGPoint(x: size.width + monster2.size.width, y: actualY2)

        addChild(monster)
        addChild(monster2)
        // Determine speed of the monster
        let actualDuration = random(min: CGFloat(1.0), max: CGFloat(2.0))
        // Create the actions
        let actionMove = SKAction.move(to: CGPoint(x: -monster.size.width/2, y: actualY),
                                       duration: TimeInterval(actualDuration))
        let actionMoveDone = SKAction.removeFromParent()
        
        let actionMove2 = SKAction.move(to: CGPoint(x: -monster2.size.width/2, y: actualY2),
                                       duration: TimeInterval(actualDuration))
        
        let loseAction = SKAction.run() { [weak self] in
            guard let `self` = self else { return }
            let reveal = SKTransition.flipVertical(withDuration: 0.5)
            let gameOverScene = GameOverScene(size: self.size, won: false)
            self.view?.presentScene(gameOverScene, transition: reveal)
        }
        monster.run(SKAction.sequence([actionMove, loseAction, actionMoveDone]))
        monster2.run(SKAction.sequence([actionMove2, loseAction, actionMoveDone]))
        
        monster.physicsBody = SKPhysicsBody(rectangleOf: monster.size) // 1
        monster.physicsBody?.isDynamic = true // 2
        monster.physicsBody?.categoryBitMask = PhysicsCategory.monster // 3
        monster.physicsBody?.contactTestBitMask = PhysicsCategory.projectile // 4
        monster.physicsBody?.collisionBitMask = PhysicsCategory.none // 5
        monster.zPosition = 1
        
        monster2.physicsBody = SKPhysicsBody(rectangleOf: monster2.size) // 1
        monster2.physicsBody?.isDynamic = true // 2
        monster2.physicsBody?.categoryBitMask = PhysicsCategory.monster // 3
        monster2.physicsBody?.contactTestBitMask = PhysicsCategory.projectile // 4
        monster2.physicsBody?.collisionBitMask = PhysicsCategory.none // 5
        monster2.zPosition = 1
    }
    
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        run(SKAction.playSoundFileNamed("pew-pew-lei.caf", waitForCompletion: false))


        // 1 - Choose one of the touches to work with
        guard let touch = touches.first else {
            return
        }

        
        let touchLocation = touch.location(in: self)
        
        // 2 - Set up initial location of projectile
        let projectile = SKSpriteNode(imageNamed: "projectile")
        projectile.position = player.position
        projectile.zPosition = 1
        
        // 3 - Determine offset of location to projectile
        let offset = touchLocation - projectile.position
        
        // 4 - Bail out if you are shooting down or backwards
        if offset.x < 0 { return }
        
        // 5 - OK to add now - you've double checked position
        addChild(projectile)
        
        // 6 - Get the direction of where to shoot
        let direction = offset.normalized()
        
        // 7 - Make it shoot far enough to be guaranteed off screen
        let shootAmount = direction * 1000
        
        // 8 - Add the shoot amount to the current position
        let realDest = shootAmount + projectile.position
        
        // 9 - Create the actions
        let actionMove = SKAction.move(to: realDest, duration: 2.0)
        let actionMoveDone = SKAction.removeFromParent()
        projectile.run(SKAction.sequence([actionMove, actionMoveDone]))
        
        projectile.physicsBody = SKPhysicsBody(circleOfRadius: projectile.size.width/2)
        projectile.physicsBody?.isDynamic = true
        projectile.physicsBody?.categoryBitMask = PhysicsCategory.projectile
        projectile.physicsBody?.contactTestBitMask = PhysicsCategory.monster
        projectile.physicsBody?.collisionBitMask = PhysicsCategory.none
        projectile.physicsBody?.usesPreciseCollisionDetection = true
    }

    
    func projectileDidCollideWithMonster(projectile: SKSpriteNode, monster: SKSpriteNode) {
        print("Hit")
        projectile.removeFromParent()
        monster.removeFromParent()
        
        monstersDestroyed += 1
        if monstersDestroyed > 19 {
            let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
            let gameOverScene = GameOverScene(size: self.size, won: true)
            view?.presentScene(gameOverScene, transition: reveal)
        }
    }

    func createGround() {
        let groundTexture = SKTexture(imageNamed: "background")
        
        for i in 0 ... 1 {
            let ground = SKSpriteNode(texture: groundTexture)
            ground.zPosition = 0
            ground.position = CGPoint(x: (groundTexture.size().width / 2.0 + (groundTexture.size().width * CGFloat(i))), y: groundTexture.size().height / 2)
            
            addChild(ground)
            
            let moveLeft = SKAction.moveBy(x: -groundTexture.size().width, y: 0, duration: 8)
            let moveReset = SKAction.moveBy(x: groundTexture.size().width, y: 0, duration: 0)
            let moveLoop = SKAction.sequence([moveLeft, moveReset])
            let moveForever = SKAction.repeatForever(moveLoop)
            
            ground.run(moveForever)
        }
    }
}



extension GameScene: SKPhysicsContactDelegate {
    
    func didBegin(_ contact: SKPhysicsContact) {
        // 1
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        // 2
        if ((firstBody.categoryBitMask & PhysicsCategory.monster != 0) &&
            (secondBody.categoryBitMask & PhysicsCategory.projectile != 0)) {
            if let monster = firstBody.node as? SKSpriteNode,
                let projectile = secondBody.node as? SKSpriteNode {
                projectileDidCollideWithMonster(projectile: projectile, monster: monster)
            }
        }
    }
}
