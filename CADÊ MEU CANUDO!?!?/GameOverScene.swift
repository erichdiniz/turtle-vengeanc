import SpriteKit

class GameOverScene: SKScene {
    init(size: CGSize, won:Bool) {
        super.init(size: size)
        
        // 1
        backgroundColor = SKColor.lightGray
        
        // 2
        let message = won ? "PARABENS CARALHO!" : "MORREU FODASE"
        
        // 3
        let label = SKLabelNode(fontNamed: "Chalkduster")
        label.text = message
        label.fontSize = 30
        label.fontColor = SKColor.black
        label.position = CGPoint(x: size.width/2, y: size.height/2)
        addChild(label)
        
        // 4
        run(SKAction.sequence([
            SKAction.wait(forDuration: 2.0),
            SKAction.run() { [weak self] in
                // 5
                guard let `self` = self else { return }
                let reveal = SKTransition.flipVertical(withDuration: 0.4)
                let scene = GameScene(size: size)
                self.view?.presentScene(scene, transition:reveal)
            }
            ]))
    }
    
    // 6
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
