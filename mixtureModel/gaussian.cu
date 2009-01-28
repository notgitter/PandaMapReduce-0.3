/*
 * Copyright 1993-2007 NVIDIA Corporation.  All rights reserved.
 *
 * NOTICE TO USER:
 *
 * This source code is subject to NVIDIA ownership rights under U.S. and
 * international Copyright laws.  Users and possessors of this source code
 * are hereby granted a nonexclusive, royalty-free license to use this code
 * in individual and commercial software.
 *
 * NVIDIA MAKES NO REPRESENTATION ABOUT THE SUITABILITY OF THIS SOURCE
 * CODE FOR ANY PURPOSE.  IT IS PROVIDED "AS IS" WITHOUT EXPRESS OR
 * IMPLIED WARRANTY OF ANY KIND.  NVIDIA DISCLAIMS ALL WARRANTIES WITH
 * REGARD TO THIS SOURCE CODE, INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY, NONINFRINGEMENT, AND FITNESS FOR A PARTICULAR PURPOSE.
 * IN NO EVENT SHALL NVIDIA BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL,
 * OR CONSEQUENTIAL DAMAGES, OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS
 * OF USE, DATA OR PROFITS,  WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE
 * OR OTHER TORTIOUS ACTION,  ARISING OUT OF OR IN CONNECTION WITH THE USE
 * OR PERFORMANCE OF THIS SOURCE CODE.
 *
 * U.S. Government End Users.   This source code is a "commercial item" as
 * that term is defined at  48 C.F.R. 2.101 (OCT 1995), consisting  of
 * "commercial computer  software"  and "commercial computer software
 * documentation" as such terms are  used in 48 C.F.R. 12.212 (SEPT 1995)
 * and is provided to the U.S. Government only as a commercial end item.
 * Consistent with 48 C.F.R.12.212 and 48 C.F.R. 227.7202-1 through
 * 227.7202-4 (JUNE 1995), all U.S. Government End Users acquire the
 * source code with only those rights set forth herein.
 *
 * Any use of this source code in individual and commercial software must
 * include, in the user documentation and internal comments to the code,
 * the above Disclaimer and U.S. Government End Users Notice.
 */

/* Template project which demonstrates the basics on how to setup a project 
* example application.
* Host code.
*/

// includes, system
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>

// includes, project
#include <cutil.h>

// includes, kernels
#include <means_kernel.cu>

////////////////////////////////////////////////////////////////////////////////
// declaration, forward
void runTest( int argc, char** argv);

extern "C"
void computeGold( float* reference, float* idata, const unsigned int len);

////////////////////////////////////////////////////////////////////////////////
// Program main
////////////////////////////////////////////////////////////////////////////////
int
main( int argc, char** argv) 
{
    runTest( argc, argv);

    CUT_EXIT(argc, argv);
}

////////////////////////////////////////////////////////////////////////////////
//! Run a simple test for CUDA
////////////////////////////////////////////////////////////////////////////////
void
runTest( int argc, char** argv) 
{

    CUT_DEVICE_INIT(argc, argv);

    unsigned int timer = 0;
    CUT_SAFE_CALL( cutCreateTimer( &timer));
    CUT_SAFE_CALL( cutStartTimer( timer));

    unsigned int num_dimensions = 20;
    unsigned int num_events = 1000;
    
    // allocate host memory
    float* h_idata = (float*) malloc(sizeof(float)*num_dimensions*num_events);
    
    // initalize the memory
    for( unsigned int i = 0; i < num_events*num_dimensions; i += num_dimensions ) 
    {
        for(unsigned int j = 0; j < num_dimensions; j++) {
            h_idata[i+j]= (float)(i+j);
            //printf("%f ",(float)i+j);
        }
        //printf("\n");
    }

    unsigned int mem_size = num_dimensions*num_events*sizeof(float);
    unsigned int num_threads = num_dimensions;
    
    // allocate device memory
    float* d_idata;
    CUDA_SAFE_CALL( cudaMalloc( (void**) &d_idata, mem_size));
    // copy host memory to device
    CUDA_SAFE_CALL( cudaMemcpy( d_idata, h_idata, mem_size,
                                cudaMemcpyHostToDevice) );

    // allocate device memory for result
    float* d_odata;
    CUDA_SAFE_CALL( cudaMalloc( (void**) &d_odata, num_dimensions*sizeof(float)));

    // setup execution parameters
    dim3  grid( 1, 1, 1);
    dim3  threads( num_threads, 1, 1);

    // execute the kernel
    testKernel<<< 1, num_threads >>>( d_idata, d_odata, num_dimensions, num_events);

    // check if kernel execution generated and error
    CUT_CHECK_ERROR("Kernel execution failed");

    // allocate mem for the result on host side
    float* h_odata = (float*) malloc(num_dimensions*sizeof(float));
    // copy result from device to host
    CUDA_SAFE_CALL(cudaMemcpy(h_odata, d_odata, sizeof(float) * num_dimensions,
                                cudaMemcpyDeviceToHost) );

    CUT_SAFE_CALL(cutStopTimer(timer));
    printf( "Processing time: %f (ms)\n", cutGetTimerValue( timer));
    CUT_SAFE_CALL(cutDeleteTimer(timer));
    
    for(int i=0; i<num_dimensions; i++){
        printf("Means[%d]: %f\n",i,h_odata[i]);
    }
    
    fflush(stdout);

    // cleanup memory
    free( h_idata);
    free( h_odata);
    CUDA_SAFE_CALL(cudaFree(d_idata));
    CUDA_SAFE_CALL(cudaFree(d_odata));
}
