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
    @IBOutlet var locLabel: UILabel!
    @IBOutlet var loadingIndicator: UIActivityIndicatorView!
    
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
        
        let url = NSURL (string: "www.google.com");
        let requestObj = NSURLRequest(URL: url!);
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
        ipAddrAlert.addTextFieldWithConfigurationHandler { (textField) -> Void in
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
        
        // label init
        self.locLabel.text = "Current Location: 0"
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
        // create a new thread to get URL from parse and set webview
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), { () -> Void in
            var location:Float = message.arguments.first as Float

            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.locLabel.text = "Current Location: \(location)"
            })
            
            println("new location: \(location)");
            
            // display pdf
            let requestObj = NSURLRequest(URL: self.getURLFromParse(self.mappingFromLocation(location)));
            self.webView.loadRequest(requestObj);
            //println("reset webview request")
        })
    }
    
    func sendOSCData() -> Void {
        // create a new thread to send buffer data
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), { () -> Void in
            // send osc message
            var str:String = self.magBuf.generateStringForOSC()
            let message:F53OSCMessage = F53OSCMessage(string: "/magneto \(str)")
            self.oscClient.sendPacket(message, toHost: sendHost, onPort: sendPort)
            //println("send OSC message")
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
    
    
    ////// NEED MODIFICATION //////
    // get mapping result from location
    func mappingFromLocation(location:Float) -> Int {
        if (location < 4 && location > 0) {
            return 10;
        } else if (location < 6 && location >= 4) {
            return 11;
        } else if (location < 7.3 && location >= 6) {
            return 12;
        } else if (location < 8.8 && location >= 7.3) {
            return 13;
        } else if (location < 9.8 && location >= 8.8) {
            return 14;
        } else if (location < 11 && location >= 9.8) {
            return 15;
        } else if (location < 12 && location >= 11) {
            return 16;
        } else if (location < 14 && location >= 12) {
            return 17;
        } else if (location < 15.8 && location >= 14) {
            return 18;
        } else if (location < 16.8 && location >= 15.8) {
            return 19;
        } else if (location < 17.6 && location >= 16.8) {
            return 20;
        } else if (location >= 17.6) {
            return 21;
        }
        return 0;
    }
    
    func startLoadingIndicator() {
        // start loading indicator
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.loadingIndicator.hidden = false
            self.loadingIndicator.startAnimating()
        })
    }
    
    func stopLoadingIndicator() {
        // hide loading indicator
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.loadingIndicator.stopAnimating()
            self.loadingIndicator.hidden = true
        })
    }


}
