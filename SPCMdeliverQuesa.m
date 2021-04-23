/*  NAME:
        SPCMdeliverQuesa.m
		
    DESCRIPTION:
        Objective-C Implementation of an an object communicating with Quesa and
		delivering translation, rotation and buttons to a Q3Controller under MacOS X 

    COPYRIGHT:
        Copyright (c) 1999-2005, Quesa Developers. All rights reserved.

        For the current release of Quesa, please see:

            <http://www.quesa.org/>
        
        Redistribution and use in source and binary forms, with or without
        modification, are permitted provided that the following conditions
        are met:
        
            o Redistributions of source code must retain the above copyright
              notice, this list of conditions and the following disclaimer.
        
            o Redistributions in binary form must reproduce the above
              copyright notice, this list of conditions and the following
              disclaimer in the documentation and/or other materials provided
              with the distribution.
        
            o Neither the name of Quesa nor the names of its contributors
              may be used to endorse or promote products derived from this
              software without specific prior written permission.
        
        THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
        "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
        LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
        A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
        OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
        SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
        TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
        PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
        LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
        NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
        SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
    ___________________________________________________________________________
*/

#include <CoreFoundation/CoreFoundation.h>

#import "SPCMdeliverQuesa.h"

@implementation SPCMdeliverQuesa

- init
{
	self = [super init];
	if( !self ) return self;

	Q3Initialize();
	
	fControllerData.signature		= "Magellan SpaceMouse:Logitech:\0";
	fControllerData.valueCount		= 0;
	fControllerData.channelCount		= 0;
	fControllerData.channelGetMethod	= NULL ;
	fControllerData.channelSetMethod	= NULL ;
	
	fControllerRef = Q3Controller_New(&fControllerData);
	
	/*
	err = err_Controller;
	if (fControllerRef == NULL) goto exit;
	*/
	
	return self;
}

- (void)dealloc
{
    //Decommission the controller
	if (fControllerRef != NULL) {
		Q3Controller_Decommission(fControllerRef);
		fControllerRef = NULL;
	}
		
    [super dealloc];
}


- (BOOL)deliverTranslation:(float)x :(float)y :(float)z
	  	       andRotation:(float)a :(float)b :(float)c
{
	TQ3Boolean track2DCursor;
	
	TQ3Quaternion d_orient;
	TQ3Vector3D d_pos;
	
	Q3Controller_Track2DCursor(fControllerRef, &track2DCursor);
	d_pos.x = x;
	d_pos.y = y;
	d_pos.z = z;
	
	Q3Controller_MoveTrackerPosition(fControllerRef, &d_pos);
	Q3Quaternion_SetRotate_XYZ(&d_orient,a,b,c); 	
	Q3Controller_MoveTrackerOrientation(fControllerRef, &d_orient);			
	
	return NO;
}

- (BOOL)deliverKeyPress:(int)keys
{
	TQ3Boolean track2DCursor;
	
	Q3Controller_Track2DCursor(fControllerRef, &track2DCursor);
	Q3Controller_SetButtons(fControllerRef, keys);			
	
	return NO;
}

@end
