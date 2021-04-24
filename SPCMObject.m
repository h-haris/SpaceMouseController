/*  NAME:
        SPCMObject.m

 DESCRIPTION:
     Objective-C interface definition for an object (M and C part of the MVC pattern)
     communicating to and from a Logitech Spacemouse (Magellan; grey modell; RS232
     connection) under MacOS X.
     Following is modelled:
     - object holds: used serial port and its NSFileHandle
     - object holds: multipliers for rot and trans and decoded device state
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

#include <fcntl.h>
#include <unistd.h>

#import "SPCMObject.h"
#import "SPCMdeliverQuesa.h"

static SInt8 CharToNibble(char ch)
{
    return(ch&0x0F);
}

SInt16 FourCharsToVal(char a3,char a2,char a1,char a0)
{
    return ((4096*(a3&0x0F)
             +256*(a2&0x0F)
              +16*(a1&0x0F)
                 +(a0&0x0F))-32768);
}

static char NibbleToCharTable[] =
    {0x30,0x41,0x42,0x33,0x44,0x35,0x36,0x47,0x48,0x39,0x3a,0x4b,0x3c,0x4d,0x4e,0x3f};

@implementation SPCMObject

//init/clean-up/dealloc
- init
{
    self = [super init];
    if(!self) return self;

    // Ok, we did pass the risky point. So lets do our default settings.

    devPathString = [[NSString alloc] init];
    inEvents = [[NSMutableString alloc ] init];
    QuesaConnection = [[SPCMdeliverQuesa alloc] init];

    portDescriptor=-1;

    [self PrefsFromDisk];

    return self;
}

- (void)dealloc
{
    //Destructor

    [devPathString release];
    [inEvents release];
    [self disconnectFromDevice];

    //write current setting to prefs
    [self PrefsToDisk];
    [prefs release];
    [QuesaConnection release];
    [super dealloc];
}

- PrefsFromDisk
{
    prefs = [[NSUserDefaults standardUserDefaults] retain];

    // create the user defaults here if they don't exists
    // create a dictionary
    NSMutableDictionary *defaultPrefs = [NSMutableDictionary dictionary]; //local object!?
    // put default prefs in the dictionary

    [defaultPrefs setObject: [NSNumber numberWithBool:NO] forKey:@"hasPrefsFile"];
    [defaultPrefs setObject: [NSNumber numberWithBool:YES] forKey:@"translationOn"];
    [defaultPrefs setObject: [NSNumber numberWithBool:YES] forKey:@"rotationOn"];
    [defaultPrefs setObject: [NSNumber numberWithBool:NO] forKey:@"dominantModeOn"];

    [defaultPrefs setObject: [NSNumber numberWithInt:0] forKey:@"selectedPortItem"];
    [defaultPrefs setObject: [NSNumber numberWithInt:4] forKey:@"rotationQuality"];
    [defaultPrefs setObject: [NSNumber numberWithInt:2] forKey:@"translationQuality"];
    [defaultPrefs setObject: [NSNumber numberWithInt:15] forKey:@"nullRadius"];

    [defaultPrefs setObject: [NSNumber numberWithFloat:10.0] forKey:@"rotScale"];
    [defaultPrefs setObject: [NSNumber numberWithFloat:3.0] forKey:@"transScale"];

    // register the dictionary of defaults
    [prefs registerDefaults: defaultPrefs];

    hasPrefsFile = [prefs boolForKey:@"hasPrefsFile"];
    transOn = [prefs boolForKey:@"translationOn"];
    rotOn = [prefs boolForKey:@"rotationOn"];
    domModeOn = [prefs boolForKey:@"dominantModeOn"];

    selectedPortItem = [prefs integerForKey:@"selectedPortItem"];
    rotQuality = [prefs integerForKey:@"rotationQuality"];
    transQuality = [prefs integerForKey:@"translationQuality"];
    nullRad = [prefs integerForKey:@"nullRadius"];

    [self setRotScale:[prefs floatForKey:@"rotScale"]];
    [self setTransScale:[prefs floatForKey:@"transScale"]];

    return self;
}

- PrefsToDisk
{
    [prefs setBool:YES forKey:@"hasPrefsFile"];
    [prefs setBool:transOn forKey:@"translationOn"];
    [prefs setBool:rotOn forKey:@"rotationOn"];
    [prefs setBool:domModeOn forKey:@"dominantModeOn"];

    [prefs setInteger:selectedPortItem forKey:@"selectedPortItem"];
    [prefs setInteger:rotQuality forKey:@"rotationQuality"];
    [prefs setInteger:transQuality forKey:@"translationQuality"];
    [prefs setInteger:nullRad forKey:@"nullRadius"];

    [prefs setFloat:rotScale forKey:@"rotScale"];
    [prefs setFloat:transScale forKey:@"transScale"];

    //write values to file!
    [prefs synchronize];

    return self;
}

- (BOOL) hasPrefsFile
{
    return hasPrefsFile;
}

- setFrontend:anObject
{
    frontend=anObject;
    return self;
}

//connect/disconnect

- SetSelectedPortItem:(NSInteger)_selectedPort
{
    selectedPortItem=_selectedPort;
    return self;
}

- (NSInteger)selectedPortItem
{
    return selectedPortItem;
}

- (NSString *)devPathString
{
    return devPathString;
}

- setDevPathString:(NSString *)newDevPathString
{
    id old=devPathString;
    devPathString=[newDevPathString retain];
    [old release];
    return self;
}

//based on serialportsample.c
- (BOOL)connectToDevice
{
    struct termios  options;
    // Init a new port and don't forget to reset our buffers!

    portDescriptor=open([devPathString cString], O_RDWR | O_NOCTTY | O_NDELAY );
    //O_RDWR   : open for reading and writing
    //O_NOCTTY : don't assign a controlling terminal
    //O_NDELAY : don't delay

    if (portDescriptor == -1)
    {
        NSLog(@"Error opening serial port %@ - %s(%d).\n",
            devPathString, strerror(errno), errno);
        goto error;
    }

    if (fcntl(portDescriptor, F_SETFL, 0) == -1) //F_SETFL : Set descriptor-flags to argument
    {
        NSLog(@"Error clearing O_NDELAY %@ - %s(%d).\n",
            devPathString, strerror(errno), errno);
        goto error;
    }

    // Get the current options and save them for later reset
    if (tcgetattr(portDescriptor, &gOriginalTTYAttrs) == -1)
    {
        NSLog(@"Error getting tty attributes %@ - %s(%d).\n",
            devPathString, strerror(errno), errno);
        goto error;
    }

    // Set raw input, one second timeout
    // These options are documented in the man page for termios
    // (in Terminal enter: man termios/ openman termios (if manopen is installed))
    options = gOriginalTTYAttrs;
    options.c_cflag|=(B9600 | CREAD | CS8 | CSTOPB | HUPCL | CRTSCTS); //or
    options.c_lflag=0;
    //options.c_lflag &= ~(ICANON | ECHO | ECHOE | ISIG); //and not
    //ICANON : canonicalize input lines
    //ECHO   : enable echoing
    //ECHOE  : visuallay erase chars
    //ISIG   : enable signals
    options.c_oflag&=~OPOST;    //and not
    //OPOST  : enable following output procressing (kind of processing is set through extra flags)
    options.c_cc[VEOL]='\r';
    options.c_cc[VERASE]='\000';
    options.c_cc[VKILL]='\000';
    options.c_cc[VMIN ]=1;
    options.c_cc[VTIME]=0;

    // Set the options
    if (tcsetattr(portDescriptor, TCSANOW, &options) == -1) //TCSANOW : do changes immediately
    {
        NSLog(@"Error setting tty attributes %@ - %s(%d).\n",
            devPathString, strerror(errno), errno);
        goto error;
    }

    // Success
    sleep(1);

    //create NSFileHandle from portDescriptor
    port = [[NSFileHandle alloc] initWithFileDescriptor:portDescriptor];

    [[NSNotificationCenter defaultCenter] addObserver:self
        selector:@selector(dataFromMouse:)
        name:NSFileHandleReadCompletionNotification
        object:port];

    [port readInBackgroundAndNotify];

    // The first direct write is just to set the mouse to 9600 Baud.
    // Then we will set every value to a default. This way all our values
    // get initialized.
    [self transmitChars:"z\r\r" length:3];
    sleep(1);

    [self zeroMouse];
    //transmit last settings
    [self setMouseDomMode:domModeOn
              withTransOn:transOn
                 andRotOn:rotOn];

    [self setTransQual:transQuality
            andRotQual:rotQuality];
    [self setDataRateMin:2 andMax:8];
    [self setNullRad:nullRad];

    [self beepFor:4];

    return TRUE;

    // Failure path
error:
    if (portDescriptor != -1)
    {
        close(portDescriptor);
        portDescriptor=-1;
    }
    return FALSE;
}

- disconnectFromDevice
{
    if([self isConnected])
    {
        //Notification is off!
        [[NSNotificationCenter defaultCenter] removeObserver:self];

        //close port and handle!!!
        [port closeFile];
        [port release];

        //write back gOriginalTTYAttrs!
        tcsetattr(portDescriptor, TCSANOW, &gOriginalTTYAttrs);
        close(portDescriptor);
        portDescriptor=-1;
    }
    return self;
}

- (BOOL)isConnected
{
    if(portDescriptor!=-1)
            return YES;
    else    return NO;
}

- transmitChars: (const char *)buffer length: (NSInteger)length
{
    if([self isConnected])
        write(portDescriptor,buffer,length);
    return self;
}

- (void)dataFromMouse:(NSNotification *)notification
{
    NSData *SPCMEvent=[[notification userInfo]
        objectForKey:@"NSFileHandleNotificationDataItem"];

    [self processNotificationData:SPCMEvent];

    //restart reading
    [port readInBackgroundAndNotify];
}

- processNotificationData:(NSData *)notificationData
{
    NSString        *notifString;
    NSCharacterSet  *crSet;
    NSScanner       *inScanner;
    NSString        *anEvent;
    NSRange         crRange, cuttingRange;

    //convert notification data to notification string
    notifString=[[NSString alloc] initWithData:notificationData encoding:NSASCIIStringEncoding];
    //append notification string to event string
    [inEvents appendString:notifString];
    [notifString release];
    //setup scanner
    crSet=[NSCharacterSet characterSetWithCharactersInString:@"\r"];
    inScanner=[NSScanner scannerWithString:inEvents];
    //search for \r (CR) in event string -- quick 'n' dirty: at end of inEvents
    crRange = [inEvents rangeOfCharacterFromSet:crSet];
    if (crRange.location != NSNotFound){
        //do bookkeeping for later character deletion
        cuttingRange.location=[inScanner scanLocation];
        //scan ...
        while ([inScanner isAtEnd] == NO) {
            if ([inScanner scanUpToCharactersFromSet:crSet intoString:&anEvent]) {
                //... and parse
                [self doEvent:[anEvent cStringUsingEncoding:NSASCIIStringEncoding]];
                //do bookkeeping for later character deletion
                cuttingRange.length=[inScanner scanLocation]+1;
            }
        }
        //remove found events from event string
        [inEvents deleteCharactersInRange:cuttingRange];
    }
    return self;
}

- setMouseDomMode:(BOOL)domFlag
      withTransOn:(BOOL)transFlag
         andRotOn:(BOOL)rotFlag
{
    char    serSendBuffer[3];

    rotOn       =rotFlag;
    transOn     =transFlag;
    domModeOn   =domFlag;

    serSendBuffer[0]='m';
    serSendBuffer[1]=NibbleToCharTable[rotFlag*1 + transFlag*2 + domFlag*4];
    serSendBuffer[2]='\r';

    // We don't need to ask for the result here. The mouse echos the setting.

    [self transmitChars:serSendBuffer length:3];
    return self;
}

- (BOOL)transOn
{
    return transOn;
}

- (BOOL)rotOn
{
    return rotOn;
}

- (BOOL)domModeOn
{
    return domModeOn;
}

- setTransQual:(NSInteger)transInt andRotQual:(NSInteger)rotInt
{
    char    serSendBuffer[4];

    if(rotInt < 0)      rotInt=0;
    if(rotInt > 15)     rotInt=15;
    if(transInt < 0)    transInt=0;
    if(transInt > 15)   transInt=15;

    rotQuality  =rotInt;
    transQuality=transInt;

    serSendBuffer[0]='q';
    serSendBuffer[1]=NibbleToCharTable[transInt];
    serSendBuffer[2]=NibbleToCharTable[rotInt];
    serSendBuffer[3]='\r';

    [self transmitChars:serSendBuffer length:4];
    return self;
}

- (NSInteger)transQuality
{
    return transQuality;
}

- (NSInteger)rotQuality
{
    return rotQuality;
}

- setNullRad:(NSInteger)anInt
{
    char    serSendBuffer[3];

    if(anInt < 0)   anInt=0;
    if(anInt > 15)  anInt=15;

    nullRad=anInt;

    serSendBuffer[0]='n';
    serSendBuffer[1]=NibbleToCharTable[anInt];
    serSendBuffer[2]='\r';

    [self transmitChars:serSendBuffer length:3];
    return self;
}

- (NSInteger)nullRad
{
    return nullRad;
}

/*
    Conversion to real Device rates
    min: (minRate+1)*20ms
    max: (maxRate+1)*20ms
*/
- setDataRateMin:(NSInteger)minRate andMax:(NSInteger)maxRate
{
    char    serSendBuffer[4];

    if(minRate < 2)     minRate =2;     // 60 ms
    if(minRate > 15)    minRate =15;    //320 ms
    if(maxRate < 2)     maxRate =2;     // 60 ms
    if(maxRate > 15)    maxRate =15;    //320 ms
    if(minRate > maxRate) minRate=maxRate;
    if(maxRate < minRate) maxRate=minRate;

    serSendBuffer[0]='p';
    serSendBuffer[1]=NibbleToCharTable[maxRate];
    serSendBuffer[2]=NibbleToCharTable[minRate];
    serSendBuffer[3]='\r';

    [self transmitChars:serSendBuffer length:4];
    return self;
}

/*
    maximum rotational deflection, when in linear mode (absolute)
    rot_lin_max_abs_defl: 400dig / 4 degr
    rotScaleBase= 4000.0 leads to a maximum deflection of 0.4 degr, when Controller is in linear mode
*/
#define rotScaleBase (4000.0f)
- setRotScale:(float)aFloat
{
    rotScale=aFloat;
    rotMult =(rotScale/rotScaleBase)*(pi/180.0);//rotational values are passed as radians to QD3D
    return self;
}

- (float)rotScale
{
    return rotScale;
}

/*
    maximum translational deflection, when in linear mode (absolute)
    trans_lin_max_abs_defl: 400dig / 1.5 mm
    transScaleBase= 4000.0 leads to a maximum deflection of 0.15 mm, when Controller is in linear mode
*/
#define transScaleBase (4000.0f)
- setTransScale:(float)aFloat
{
    transScale  =aFloat;
    transMult   =transScale/transScaleBase;
    return self;
}

- (float)transScale
{
    return transScale;
}

- queryDeviceVersion
{
    [self transmitChars:"vQ\r" length:3];
    return self;
}

- beepFor:(NSInteger)anInt
{
    char    serSendBuffer[3];

    if(anInt < 0) anInt=0;
    if(anInt > 7) anInt=7;

    serSendBuffer[0]='b';
    serSendBuffer[1]=NibbleToCharTable[anInt + 7];
    serSendBuffer[2]='\r';

    [self transmitChars:serSendBuffer length:3];
    return self;
}

- zeroMouse
{
    [self transmitChars:"z\r" length:2];
    return self;
}

- doEvent:(const char *)buffer
{
    if(buffer!=NULL)
    {
        if(buffer[0] == 'd') [self doTransformationEvent:buffer];
        if(buffer[0] == 'k') [self doKeyEvent:buffer];
        if(buffer[0] == 'n') [self doNullRadiusEvent:buffer];
        if(buffer[0] == 'q') [self doQualityEvent:buffer];
//      if(buffer[0] == 'p') [self doDataRateEvent:buffer];
//      if(buffer[0] == 'e') [self doErrorEvent:buffer];
//      if(buffer[0] == 'v') [self doVersionEvent:buffer];
        if(buffer[0] == 'm') [self doModeEvent:buffer];
    }
    return self;
}

- doModeEvent:(const char *)buffer
{
    int mode;

    mode = CharToNibble(buffer[1]);

    if(mode&0x01)
            rotOn=YES;
    else    rotOn=NO;

    if(mode&0x02)
            transOn=YES;
    else    transOn=NO;

    if(mode&0x04)
            domModeOn=YES;
    else    domModeOn=NO;

    [frontend UpdateModes:self];
    return self;
}

- doQualityEvent:(const char *)buffer
{
    transQuality=CharToNibble(buffer[1]);
    rotQuality=CharToNibble(buffer[2]);

    [frontend UpdateSensitivities:self];
    return self;
}

- doNullRadiusEvent:(const char *)buffer
{
    nullRad=CharToNibble(buffer[1]);

    [frontend UpdateNullRadius:self];
    return self;
}

- doKeyEvent:(const char *)buffer
{
    int keys;

    keys =256*CharToNibble(buffer[3]);
    keys+=16 *CharToNibble(buffer[2]);
    keys+=    CharToNibble(buffer[1]);

    [QuesaConnection deliverKeyPress:keys];

    return self;
}

- doTransformationEvent:(const char *)buffer
{
    float   x, y, z, a, b, c;

    x=transMult*FourCharsToVal(buffer[0*4+1],buffer[0*4+2],buffer[0*4+3],buffer[0*4+4]);
    y=transMult*FourCharsToVal(buffer[1*4+1],buffer[1*4+2],buffer[1*4+3],buffer[1*4+4]);
    z=transMult*FourCharsToVal(buffer[2*4+1],buffer[2*4+2],buffer[2*4+3],buffer[2*4+4]);

    a=rotMult*FourCharsToVal(buffer[3*4+1],buffer[3*4+2],buffer[3*4+3],buffer[3*4+4]);
    b=rotMult*FourCharsToVal(buffer[4*4+1],buffer[4*4+2],buffer[4*4+3],buffer[4*4+4]);
    c=rotMult*FourCharsToVal(buffer[5*4+1],buffer[5*4+2],buffer[5*4+3],buffer[5*4+4]);

    [QuesaConnection deliverTranslation:x :y :z andRotation:a :b :c];

    return self;
}

@end
