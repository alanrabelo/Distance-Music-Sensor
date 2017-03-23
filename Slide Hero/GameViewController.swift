//
//  GameViewController.swift
//  Slide Hero
//
//  Created by Alan Rabelo Martins on 22/03/17.
//  Copyright © 2017 Alan Rabelo Martins. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit
import CoreMotion
import AVFoundation
import CoreBluetooth

class GameViewController: UIViewController {
    
    var motionManager : CMMotionManager?
    var cameraNode: SCNNode?
    
    //AVAUDIO VARIABLES
    var engine: AVAudioEngine = AVAudioEngine()
    var player: AVAudioPlayerNode = AVAudioPlayerNode()
    var file : AVAudioFile?
    var buffer : AVAudioPCMBuffer?
    var pitchNode : AVAudioUnitTimePitch?
    var marker : SCNNode?
    var scene : SCNScene?

    //CORE BLUETOOTH VARIABLES
    var manager : CBCentralManager?
    var peripheralList = [CBPeripheral]()
    var kCaracteristicUUID : UUID?
    var peripheralCaracteristic : CBCharacteristic?
    var currentPeripheral : CBPeripheral?
    
    var arrayOfPitches = [Int]()

    func writeValue(data: String){
        let data = (data as NSString).data(using: String.Encoding.utf8.rawValue)

        currentPeripheral?.writeValue(data!, for: peripheralCaracteristic!, type: CBCharacteristicWriteType.withoutResponse)
        
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        manager = CBCentralManager(delegate: self, queue: DispatchQueue.main)

        
        // create a new scene
        scene = SCNScene(named: "art.scnassets/ship.scn")!
        
        // create and add a camera to the scene
        cameraNode = scene?.rootNode.childNode(withName: "mainCamera", recursively: true)!

        marker = scene?.rootNode.childNode(withName: "marker", recursively: true)
        // place the camera
        
        // create and add a light to the scene
                // create and add an ambient light to the scene

        
        // retrieve the ship node
//        let ship = scene.rootNode.childNode(withName: "ship", recursively: true)!
//        
//        // animate the 3d object
//        ship.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 2, z: 0, duration: 1)))
        
        // retrieve the SCNView
        let scnView = self.view as! SCNView
        
        // set the scene to the view
        scnView.scene = scene
        
//        let audio = SCNAudioSource(name: "mainSound.aif", volume: 0.5, positional: false, loops: true, shouldStream: true, shouldLoad: true)
//        
//        let audioPlayer = SCNAudioPlayer(source: audio)
//        
//        scene.rootNode.addAudioPlayer(audioPlayer)
        
        // allows the user to manipulate the camera
        //scnView.allowsCameraControl = true
        
        // show statistics such as fps and timing information
        //scnView.showsStatistics = true
        
        // configure the view
        scnView.backgroundColor = UIColor.black
        
        // add a tap gesture recognizer
        
        //configuring motion manager
        motionManager = CMMotionManager()
        motionManager?.deviceMotionUpdateInterval = 1.0/60.0
        
        
        motionManager?.startDeviceMotionUpdates(to: OperationQueue.main, withHandler: { (motion, error) in
            
            if let motionValues = motion?.gravity {
                self.cameraNode?.position = SCNVector3(x: Float(motionValues.x * 4), y: 50, z: Float(motionValues.y * -6))
            }
            
            

        })
        
        initPlayer(withPitch: 100)
        
        setupView()

    }

    private let levelWidth = 300
    private let levelLength = 300
    
    private var _terrain: RBTerrain?
    

    private func setupView() {
        let particle = SCNParticleSystem.particle(withName: "Snow")
        cameraNode?.addParticleSystem(particle)
        
    }
    
    private func addTerrain() {
        // Create terrain
        _terrain = RBTerrain(width: levelWidth, length: levelLength, scale: 300)
        
        let generator = RBPerlinNoiseGenerator(seed: nil)
        _terrain?.formula = {(x: Int32, y: Int32) in
            return generator.valueFor(x: x, y: y)
        }
        
        _terrain!.create(withColor: UIColor.lightGray)
        _terrain!.position = SCNVector3Make(-100, 0, -100)
        _terrain?.castsShadow = false
        scene!.rootNode.addChildNode(_terrain!)
        

    }

    
    func initPlayer(withPitch pitchValue : Float) {
        
        player = AVAudioPlayerNode()
        player.volume = 1.0
        let soundPath = Bundle.main.path(forResource: "mainSound", ofType: "aif", inDirectory: "art.scnassets/sounds/")
        
        let url = URL(fileURLWithPath: soundPath!)
        
        file = try? AVAudioFile(forReading: url)
        
        buffer = AVAudioPCMBuffer(pcmFormat: file!.processingFormat, frameCapacity: AVAudioFrameCount(file!.length))
        do {
            try file!.read(into: buffer!)
        } catch _ {
            
        }
        pitchNode = AVAudioUnitTimePitch()
        pitchNode?.pitch = pitchValue  //Distortion
        pitchNode?.rate = 1.0 //Voice speed
        engine.attach(player)
        engine.attach(pitchNode!)
        engine.connect(player, to: pitchNode!, format: buffer?.format)
        engine.connect(pitchNode!, to: engine.mainMixerNode, format: buffer?.format)
        player.scheduleBuffer(buffer!, at: nil, options: AVAudioPlayerNodeBufferOptions.loops, completionHandler: {
            
        })
        
        engine.prepare()
        
        
        do {
            try engine.start()
        } catch _ {
            
        }
        
        
        
    }
    
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    var initialMarkerPosition = 0
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {

        let frameHeight = Float(self.view.frame.size.height)
        let touchLocation = touches.first!.location(in: self.view)
        pitchNode?.pitch =  -(Float(touchLocation.y) * 3 - frameHeight)
        let markerPositionZ = (Float(touchLocation.y) * 2 - frameHeight) / 20
        
        
        let moveAction = SCNAction.move(to: SCNVector3Make(-13.0, 8.0, markerPositionZ), duration: 0.1)
        marker?.runAction(moveAction)
        
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        
        let frameHeight = Float(self.view.frame.size.height)
        let touchLocation = touches.first!.location(in: self.view)
        let markerPositionZ = (Float(touchLocation.y) * 2 - frameHeight) / 20

        let moveAction = SCNAction.move(to: SCNVector3Make(-13.0, 8.0, markerPositionZ), duration: 0.1)
        marker?.runAction(moveAction)
        
        pitchNode?.pitch =  -(Float(touchLocation.y) * 3 - frameHeight)
        player.play()
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        let moveAction = SCNAction.move(to: SCNVector3Make(-13.0, 8.0, 20), duration: 0.15)
        marker?.runAction(moveAction)
        
        player.pause()
        
    }


    
}

extension GameViewController: CBCentralManagerDelegate {
    
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            // Iniciar o scan. Só podemos fazer isso quando o state for powered on.
            
            // DEF6026C-FC40-4AE4-84A3-EC15F2AA196F
            print("Start scan for peripherals")
            manager?.scanForPeripherals(withServices: nil, options: nil)
            
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        if peripheral.name != nil{
            if peripheral.name! != "Megazord de Alan" {
                print(peripheral.name!)
            }
        
        }
        
        
        //RC-HC08-9701
        
        if peripheral.name == "RC-HC08-9701" {
            if currentPeripheral != nil {
                return
            }
            currentPeripheral = peripheral
            
            
            print(currentPeripheral!.identifier.uuidString)
            kCaracteristicUUID = currentPeripheral?.identifier
            central.connect(currentPeripheral!, options: nil)
            
            
            central.stopScan()
            currentPeripheral?.delegate = self
            
            
            
            
            
            
        }
        
    }
    

    
    
}

extension GameViewController : CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("error: \(error)")
            return
        }
        
        let services = peripheral.services!
        print("Found \(services.count) services! :\(services)")
        
        peripheral.discoverCharacteristics(nil, for: services.last!)
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        if let error = error {
            print("error: \(error)")
            return
        }
        
        if let caracteristics = service.characteristics {
            for caracteristic in caracteristics {
                peripheralCaracteristic = caracteristic
                currentPeripheral?.setNotifyValue(true, for: caracteristic)

            }
        }
        
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Sucessfully connected")
        currentPeripheral?.discoverServices(nil)
        
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        
        
        if let dataBytes = characteristic.value {
            if let string = String.init(bytes: dataBytes, encoding: String.Encoding.utf8) {
                
                var arrayOfStrings = [String]()
                
                for string in string.components(separatedBy: "\r\n") {
                    
                    if let number = Int.init(string.replacingOccurrences(of: "\r", with: "").replacingOccurrences(of: "\n", with: "")) {
                        print(number)
                        if arrayOfPitches.count < 10 {
                            arrayOfPitches.append(number)
                        } else {
                            playNote(withArray: arrayOfPitches)
                        }
                    }
                    
                }
                
                
                
                
                
            }
        }
        
        

    }
    
    func playNote(withDistance distance : Int) {
        
        var value : Float = 0
        let maxDistance = 20
        
        if distance <= maxDistance {
            value = Float(distance * 3)
        } else {
            player.pause()

            return
        }
        
        
        let frameHeight = Float(self.view.frame.size.height)
        value = frameHeight / Float(maxDistance) * value
        print(value)

        let markerPositionZ = (Float(value) - frameHeight) / 20
        
        let moveAction = SCNAction.move(to: SCNVector3Make(-13.0, 8.0, markerPositionZ), duration: 0.1)
        marker?.runAction(moveAction)
        
        pitchNode?.pitch =  -(Float(value) * 4 - frameHeight)
        player.play()
        
    }
    
    func playNote(withArray distances : [Int]) {
        
        var value : Float = 0
        let maxDistance = 300
        
        var numbers = distances
        numbers.sort {
            return $0 < $1
        }
        
        let refinedValue = numbers[numbers.count / 2]
        
        arrayOfPitches.removeAll()
        
        if refinedValue <= maxDistance {
            value = Float(refinedValue) * 0.3
        } else {
            player.pause()
            let moveAction = SCNAction.move(to: SCNVector3Make(-13.0, 8.0, 25), duration: 0.15)
            marker?.runAction(moveAction)
            return
        }
        
        let frameHeight = Float(self.view.frame.size.height)
        value = frameHeight / Float(maxDistance) * value
        print(value)
        
        let markerPositionZ = (Float(value * 10) - frameHeight*1.3) / 10
        
        let moveAction = SCNAction.move(to: SCNVector3Make(-13.0, 8.0, markerPositionZ), duration: 0.1)
        marker?.runAction(moveAction)
        
        pitchNode?.pitch =  -(Float(value * 10) - frameHeight)
        player.play()
        
    }

}
