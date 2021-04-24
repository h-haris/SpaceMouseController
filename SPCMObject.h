/*  NAME:
        SPCMObject.h

    DESCRIPTION:
        Objective-C interface definition for an object (M and C part of the MVC pattern) 
        communicating to and from a Logitech Spacemouse (Magellan; grey modell; RS232
        connection) under MacOS X.
        Following is modelled:
        - object holds: used serial port and its NSFileHandle
        - object holds: multipliers for rot and trans and
        decoded device state
        - Preferences
        - communication and parsing of device replies

 COPYRIGHT:
     Copyright (c) 2005-2021, Quesa Developers. All rights reserved.

     For the current release of Quesa, please see:

         <https://github.com/jwwalker/Quesa>

     For the current release of Quesa including 3D device support,
     please see: <https://github.com/h-haris/Quesa>
     
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

//needed for the termios-struct in SPCMObject.h:
#include <termios.h>		

#import <Cocoa/Cocoa.h>

@class SPCMdeliverQuesa;

@interface SPCMObject : NSObject
{
    //holds used serial port and its NSFileHandle
    //holds multipliers for rot and trans
    //holds decoded device state
	
	//object runtime states and structures
    id		frontend;
   
	float	rotMult;
    float	transMult;
	
	//serial port
    struct 	termios 	gOriginalTTYAttrs;
    NSInteger   portDescriptor;
	id          port;
	
	SPCMdeliverQuesa *QuesaConnection;	//Connection to Quesa; holds ControllerRef	

	NSString *devPathString;
	
	NSMutableString *inEvents;
	
	NSUserDefaults *prefs;
	
	//prefs + State
	NSInteger   selectedPortItem;
	
	BOOL 	hasPrefsFile;
	
    BOOL	transOn;
    BOOL	rotOn;
    BOOL	domModeOn;
    NSInteger   rotQuality;
    NSInteger   transQuality;
    NSInteger   nullRad;
	
	float	rotScale;
    float	transScale;
}

- init;
- (void)dealloc;

- PrefsFromDisk;
- PrefsToDisk;
- (BOOL) hasPrefsFile;

- setFrontend:anObject;

// port handling
- (NSString *)devPathString;
- setDevPathString:(NSString *)newDevPathString;

- (BOOL)connectToDevice;
- disconnectFromDevice;
- (BOOL)isConnected;

// communication
- processNotificationData:(NSData *)notificationData;
- transmitChars: (const char *)buffer length: (NSInteger)length;

// The following are SpaceMouse specific methods. They are used to parse the
// data and to set the mouse states.
// accessors

- SetSelectedPortItem:(NSInteger)_selectedPort;
- (NSInteger)selectedPortItem;

- (BOOL)transOn;
- (BOOL)rotOn;
- (BOOL)domModeOn;

- (NSInteger)rotQuality;
- (NSInteger)transQuality;
- (NSInteger)nullRad;

- setRotScale:(float)aFloat;
- (float)rotScale;
- setTransScale:(float)aFloat;
- (float)transScale;

//send commands + parse received strings
- setMouseDomMode:(BOOL)domFlag 
		  withTransOn:(BOOL)transFlag
	      andRotOn:(BOOL)rotFlag;
- setTransQual:(NSInteger)transInt andRotQual:(NSInteger)rotInt;
- setDataRateMin:(NSInteger)minRate andMax:(NSInteger)maxRate;
- setNullRad:(NSInteger)anInt;
- beepFor:(NSInteger)anInt;

- zeroMouse;

- doEvent:(const char *)buffer;
- doModeEvent:(const char *)buffer;
- doQualityEvent:(const char *)buffer;
- doNullRadiusEvent:(const char *)buffer;
- doKeyEvent:(const char *)buffer;
- doTransformationEvent:(const char *)buffer;

@end
