//
//  DualArrayBuffer.swift
//  MagPadV3
//
//  Created by Ding Xu on 3/4/15.
//  Copyright (c) 2015 Ding Xu. All rights reserved.
//

import UIKit

class DualArrayBuffer: NSObject {
    
    // buffer data
    var data1X: Array<CGFloat>
    var data1Y: Array<CGFloat>
    var data1Z: Array<CGFloat>
    
    var data2X: Array<CGFloat>
    var data2Y: Array<CGFloat>
    var data2Z: Array<CGFloat>
    
    var dataIndex: Int
    var bufferIndex: Bool   // false for buffer 1 and true for buffer 2
    let bufferSize: Int
    
    init(bufSize:Int) {
        // init the size of buffer
        data1X = Array<CGFloat>(count: bufSize, repeatedValue:0)
        data1Y = Array<CGFloat>(count: bufSize, repeatedValue:0)
        data1Z = Array<CGFloat>(count: bufSize, repeatedValue:0)
        
        data2X = Array<CGFloat>(count: bufSize, repeatedValue:0)
        data2Y = Array<CGFloat>(count: bufSize, repeatedValue:0)
        data2Z = Array<CGFloat>(count: bufSize, repeatedValue:0)
        
        bufferSize = bufSize
        // data index in buffer
        dataIndex = 0
        // false for buffer 1 and true for buffer 2
        bufferIndex = false
        
        super.init()
    }
    
    // add new data into buffer and return if a buffer is full
    func addDatatoBuffer(valX:Double, valY:Double, valZ:Double) -> Bool {
        
        var result:Bool = false;
        
        // storage data
        if (self.dataIndex < self.bufferSize) {
            // not comes to end of a buffer
            if (!self.bufferIndex) {
                // store in buffer 1
                self.data1X[self.dataIndex] = CGFloat(valX)
                self.data1Y[self.dataIndex] = CGFloat(valY)
                self.data1Z[self.dataIndex] = CGFloat(valZ)
                self.dataIndex++
            } else {
                // store in buffer 2
                self.data2X[self.dataIndex] = CGFloat(valX)
                self.data2Y[self.dataIndex] = CGFloat(valY)
                self.data2Z[self.dataIndex] = CGFloat(valZ)
                self.dataIndex++
            }
            result = false
        }
        
        // check if buffer is full
        if (self.dataIndex >= self.bufferSize) {
            // update buffer inner index
            self.dataIndex = 0
            
            // change buffer index
            self.bufferIndex = !self.bufferIndex
            
            // update result
            result = true
        }
        return result
    }
    
    func generateStringForOSC() -> String {
        // check which buffer is being used now and the other is the buffered one for OSC
        var str:String = ""
        if (self.bufferIndex) {
            // buffer 2 is being used now and buffer 1 is buffered for OSC
            for i in 0...self.bufferSize-1 {
                str += "\(self.data1X[i]) \(self.data1Y[i]) \(self.data1Z[i]) "
            }
            //println("generate string from buffer 1 for OSC")
        } else {
            // buffer 1 is being used now and buffer 2 is buffered for OSC
            for i in 0...self.bufferSize-1 {
                str += "\(self.data2X[i]) \(self.data2Y[i]) \(self.data2Z[i]) "
            }
            //println("generate string from buffer 2 for OSC")
        }
        return str
    }
    
}
