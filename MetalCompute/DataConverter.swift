//
//  DataConverter.swift
//  MetalCompute
//
//  Created by Toomas Vahter on 01/11/2017.
//  Copyright © 2017 Augmented Code.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Foundation
import Metal

final class DataConverter
{
    private let device: MTLDevice
    private let computePipelineState: MTLComputePipelineState
    private let commandQueue: MTLCommandQueue
    
    init()
    {
        guard let device = MTLCreateSystemDefaultDevice() else { fatalError("Metal device is not available.") }
        self.device = device
        
        guard let commandQueue = device.makeCommandQueue() else { fatalError("Failed creating Metal command queue.") }
        self.commandQueue = commandQueue
        
        guard let library = device.makeDefaultLibrary() else { fatalError("Failed creating Metal library.") }
        guard let function = library.makeFunction(name: "processData") else { fatalError("Failed creating Metal function.") }
        
        do
        {
            computePipelineState = try device.makeComputePipelineState(function: function)
        }
        catch
        {
            fatalError("Failed preparing compute pipeline.")
        }
    }
    
    
    func process(data: ContiguousArray<Float>) -> ContiguousArray<Float>
    {
        let dataBuffer = data.withUnsafeBytes { (bufferPointer) -> MTLBuffer? in
            guard let baseAddress = bufferPointer.baseAddress else { return nil }
            return device.makeBuffer(bytes: baseAddress, length: bufferPointer.count, options: .storageModeShared)
        }
        
        guard let inputBuffer = dataBuffer else { return [] }
        
        guard let outputBuffer = device.makeBuffer(length: inputBuffer.length, options: .storageModeShared) else { return [] }
        
        guard let commandBuffer = commandQueue.makeCommandBuffer() else { return [] }
        guard let commandEncoder = commandBuffer.makeComputeCommandEncoder() else { return [] }
        
        commandEncoder.setComputePipelineState(computePipelineState)
        commandEncoder.setBuffer(inputBuffer, offset: 0, index: 0)
        commandEncoder.setBuffer(outputBuffer, offset: 0, index: 1)
        
        let threadsPerThreadgroup = MTLSize(width: 10, height: 1, depth: 1)
        let threadgroupsPerGrid = MTLSize(width: data.count / threadsPerThreadgroup.width, height: threadsPerThreadgroup.height, depth: threadsPerThreadgroup.depth)
        commandEncoder.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        
        commandEncoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        let outputPointer = outputBuffer.contents().assumingMemoryBound(to: Float.self)
        let outputDataBufferPointer = UnsafeBufferPointer<Float>(start: outputPointer, count: data.count)
        return ContiguousArray<Float>(outputDataBufferPointer)
    }
}
