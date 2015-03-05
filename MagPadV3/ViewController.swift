//
//  ViewController.swift
//  MagPadV3
//
//  Created by Ding Xu on 3/4/15.
//  Copyright (c) 2015 Ding Xu. All rights reserved.
//

import UIKit
import CoreMotion

class ViewController: UIViewController, F53OSCClientDelegate, F53OSCPacketDestination {

    @IBOutlet var webView: UIWebView!
    
    // OSC
    var oscClient:F53OSCClient = F53OSCClient()
    var oscServer:F53OSCServer = F53OSCServer()
    // Buffer
    var magBuf:DualArrayBuffer = DualArrayBuffer(bufSize: BUFFERSIZE)
    // megnetometer
    var motionManager: CMMotionManager = CMMotionManager()
    var magnetoTimer: NSTimer!
    
    var debugCnt:UInt = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //let url = NSURL (string: "http://dingxu.net/doc/resume.pdf");
        let requestObj = NSURLRequest(URL: getURLFromParse(1));
        webView.loadRequest(requestObj);
    }
    
    override func viewDidAppear(animated: Bool) {
        // set up a ip addr for OSC host
        let ipAddrAlert:UIAlertController = UIAlertController(title: nil, message: "Set up IP address for OSC", preferredStyle: .Alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: {
            action in
            exit(0)
        })
        let doneAction = UIAlertAction(title: "Done", style: .Default, handler: {
            action in
            // get user input first to update total page number
            let userText:UITextField = ipAddrAlert.textFields?.first as UITextField
            sendHost = userText.text
            println("set IP addr for send host to \(userText.text)")
        })
        ipAddrAlert.addAction(cancelAction)
        ipAddrAlert.addAction(doneAction)
        ipAddrAlert.addTextFieldWithConfigurationHandler {
            (textField) -> Void in
            textField.placeholder = "type in IP address here"
        }
        self.presentViewController(ipAddrAlert, animated: true, completion: nil)
        
        // init magnetometer
        self.motionManager.startMagnetometerUpdates()
        self.magnetoTimer = NSTimer.scheduledTimerWithTimeInterval(0.01,
            target:self,
            selector:"updateMegneto:",
            userInfo:nil,
            repeats:true)
        println("Launched magnetometer")
        
        // osc init
        self.oscServer.delegate = self
        self.oscServer.port = recvPort
        self.oscServer.startListening()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // timer
    func updateMegneto(timer: NSTimer) -> Void {
        // TODO
        //println(self.magnetoTimer.timeInterval)
        if self.motionManager.magnetometerData != nil {
            let dataX = self.motionManager.magnetometerData.magneticField.x
            let dataY = self.motionManager.magnetometerData.magneticField.y
            let dataZ = self.motionManager.magnetometerData.magneticField.z
            
            // add to buffer
            if (magBuf.addDatatoBuffer(dataX, valY: dataY, valZ: dataZ)) {
                // buffer is full, send OSC data to laptop
                self.sendOSCData()
            }
        }
    }
    
    
    // OSC
    func takeMessage(message: F53OSCMessage) -> Void {
        println("message pattern: \(message.addressPattern)")
        println("message pattern: \(message.arguments.description)")
        // display
    }
    
    func sendOSCData() -> Void {
        // create a new thread to send buffer data
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), { () -> Void in
            // send osc message
            var str:String = self.magBuf.generateStringForOSC()
            let message:F53OSCMessage = F53OSCMessage(string: "/magneto \(str)")
            self.oscClient.sendPacket(message, toHost: sendHost, onPort: sendPort)
        })
    }
    
    
    // get file URL from parse
    func getURLFromParse(fileID:Int) -> NSURL {
        // check if there is an item in server
        var pdfFileURL: NSURL! = NSURL(string: "www.google.com")
        var query = PFQuery(className: "pdfFiles")
        query.whereKey("fileID", equalTo:fileID)
        var error: NSError?
        let pdfFileObjects: [PFObject] = query.findObjects(&error) as [PFObject]
        if error == nil && pdfFileObjects.count != 0 {
            // has record in the server
            let pdfFileObject: PFObject! = pdfFileObjects.first as PFObject!
            let pdfFile: PFFile! = pdfFileObject.objectForKey("file") as PFFile
            pdfFileURL = NSURL(string: pdfFile.url)!
            //let recordData: NSData = NSData(contentsOfURL: recordURL)!
        }
        return pdfFileURL
    }


}
