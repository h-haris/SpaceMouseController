/*  NAME:
        SPCMControllerObject.m

    DESCRIPTION:
        Objective-C implementation of an object acting as the Controller of the MVC 
        pattern under MacOS X. This object handles a pull-down menu and an object to
        fill this menue, a button, several textfields and the Model itself.

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

#import "SPCMControllerObject.h"
#import "SPCMObject.h"
#import "PortnamesObject.h"

@implementation SPCMControllerObject

//allocate SPCMObject at startup
- (void) awakeFromNib
{
    //allocate SPCMObject
    theMouse = [[SPCMObject alloc] init];
    
	[[NSNotificationCenter defaultCenter] addObserver:self 
			selector:@selector(appWillTerminate:) 
			name: NSApplicationWillTerminateNotification 
			object:[NSApplication sharedApplication]];
	
	[theMouse setFrontend:self];
	
	//create List of serial ports
	thePorts = [[PortnamesObject alloc] init];
	[thePorts buildPortnamesArray];
	
	[thePorts fillMenu:portMenu];
	
	//fill values of multipliers
	[multiplierRotation setFloatValue:[theMouse rotScale]];
    [multiplierTranslation setFloatValue:[theMouse transScale]];
	
	[self UpdateModes: theMouse];

    if ([theMouse hasPrefsFile]) //SPCMObject manages even the prefs
	{
		//to be implemented: put the dialog at the coordinates from the prefs
		
		//select PopUpItem acording to selectedPortItem
		[portMenu selectItemAtIndex:[theMouse selectedPortItem]];
		
		[theMouse setDevPathString:[thePorts getDevicePathFromMenuitem:[theMouse selectedPortItem]]];
		
		[theMouse connectToDevice];
		
		if (![theMouse isConnected])
		{
			//switch Dialog to "Settings"
			[viewSettingsState selectTabViewItemAtIndex:0];
		}
	}
	else
	{
		//don't connect "Mouse"-driver
		
		//switch Dialog to "Settings"
		[viewSettingsState selectTabViewItemAtIndex:0];
		
		//select PopUpItem acording to selectedPortItem
		[portMenu selectItemAtIndex:[theMouse selectedPortItem]];
	}
}

- (void) appWillTerminate:(NSNotification *)notification
{
	[theMouse release];		//write prefs
	[PortnamesObject release];
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[super dealloc];
}

- (IBAction)applySettings:(id)sender
{
	NSInteger selectedPort = [portMenu indexOfSelectedItem];
	
	//compare choosen and old selected port item
	if (selectedPort!=[theMouse selectedPortItem])
	{
		//if items different, halt mouse, switch to new port and restart
		[theMouse disconnectFromDevice];
	
		[theMouse SetSelectedPortItem:selectedPort];
		
		[theMouse setDevPathString:[thePorts getDevicePathFromMenuitem:[theMouse selectedPortItem]]];
		
		[theMouse connectToDevice];
	}

	//take over multipliers directly
	//multiplierRotation
	[theMouse setRotScale:[multiplierRotation floatValue]];
	
	//multiplierTranslation
	[theMouse setTransScale:[multiplierTranslation floatValue]];
}

- (void) takeRotScaleFrom:(id)sender	//gets called, when the value was set from the prefs
{
	//multiplierRotation
	[multiplierRotation setFloatValue:[sender rotScale]];
}

- (void) takeTransScaleFrom:(id)sender	//gets called, when the value was set from the prefs
{
	//multiplierTranslation
	[multiplierTranslation setFloatValue:[sender transScale]];
}

- (void) UpdateModes:(id)sender
{
	//dominantFlag
	if ([sender domModeOn])
		[dominantFlag setTextColor:[NSColor controlTextColor]];
	else
		[dominantFlag setTextColor:[NSColor disabledControlTextColor]];
	
	//rotationFlag
	if ([sender rotOn])
		[rotationFlag setTextColor:[NSColor controlTextColor]];
	else
		[rotationFlag setTextColor:[NSColor disabledControlTextColor]];
	
	//translationFlag
	if ([sender transOn])
		[translationFlag setTextColor:[NSColor controlTextColor]];
	else
		[translationFlag setTextColor:[NSColor disabledControlTextColor]];
}

- (void) UpdateSensitivities:(id)sender
{
	[rotSensOut setIntValue:[sender rotQuality]];
	
	[transSensOut setIntValue:[sender transQuality]];	
}

- (void) UpdateNullRadius:(id)sender
{
	[zerRadOut setIntValue:[sender nullRad]];
}

@end
