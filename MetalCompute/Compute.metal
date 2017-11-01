//
//  Compute.metal
//  MetalCompute
//
//  Created by Toomas Vahter on 01/11/2017.
//  Copyright © 2017 Augmented Code. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

kernel void processData(const device float *inVector [[ buffer(0) ]], device float *outVector [[ buffer(1) ]], uint id [[ thread_position_in_grid ]])
{
    float input = inVector[id];
    outVector[id] = input * 2.0;
}
