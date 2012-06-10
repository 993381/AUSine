//
//  main.mm
//  AUSine
//
//  Created by Tom Schroeder on 6/9/12.
//  Copyright (c) 2012. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

typedef struct
{
   AudioUnit audioUnit;
   float frame;
} SineUnit;

static const uint kSampleRate = 44100;
static const float kSineFrequency = 440.0;

OSStatus CallbackProc(void *refCon,
                      AudioUnitRenderActionFlags *ioActionFlags,
                      const AudioTimeStamp *timeStamp,
                      UInt32 busNumber,
                      UInt32 numberFrames,
                      AudioBufferList *ioData)
{
   SineUnit *sineUnit = (SineUnit*)refCon;
	
   float cycleLength = kSampleRate / kSineFrequency;
   
   for (int frame = 0; frame < numberFrames; ++frame) 
   {
      Float32 sample = (Float32)sin(2 * M_PI * (sineUnit->frame / cycleLength));

      // Left Channel
      ((Float32*)ioData->mBuffers[0].mData)[frame] = sample;
		
      // Right Channel
      ((Float32*)ioData->mBuffers[1].mData)[frame] = sample;

      sineUnit->frame += 1.0;
   }
   
   return noErr;
}

void CheckError(OSStatus error)
{
   if (error != noErr)
   {
      printf("Error: %i", error);
      exit(-1);
   }
}

int main(int argc, const char * argv[])
{
   @autoreleasepool
   {
      SineUnit sineUnit = {0};
      OSStatus error;
      
      AudioComponentDescription outputcd = {0};
      outputcd.componentType = kAudioUnitType_Output;
      outputcd.componentSubType = kAudioUnitSubType_DefaultOutput;
      outputcd.componentManufacturer = kAudioUnitManufacturer_Apple;
      
      AudioComponent component = AudioComponentFindNext(NULL, &outputcd);
      if (!component)
      {
         printf("Error: AudioComponentFindNext\n");
         return -1;
      }
      error = AudioComponentInstanceNew(component, &sineUnit.audioUnit);
      CheckError(error);
      
      AURenderCallbackStruct input;
      input.inputProc = CallbackProc;
      input.inputProcRefCon = &sineUnit;
      error = AudioUnitSetProperty(sineUnit.audioUnit,
                                   kAudioUnitProperty_SetRenderCallback, 
                                   kAudioUnitScope_Input,
                                   0,
                                   &input, 
                                   sizeof(input));
      CheckError(error);
      
      error = AudioUnitInitialize(sineUnit.audioUnit);
      CheckError(error);
      error = AudioOutputUnitStart(sineUnit.audioUnit);
      CheckError(error);
      
      [NSThread sleepForTimeInterval:5.0];
      
      AudioOutputUnitStop(sineUnit.audioUnit);
      AudioUnitUninitialize(sineUnit.audioUnit);
      AudioComponentInstanceDispose(sineUnit.audioUnit);
      
   }
   
   return 0;
}

