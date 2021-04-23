/*  NAME:
        PortnamesObject.m

    DESCRIPTION:
        Objectice-C implementation of an object holding the names and paths of 
		serial ports under MacOS X

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

//
//  PortnamesObject.m
//  SpaceMouseController
//
//  Created by Ole Hartmann on Tue Feb 18 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#include <CoreFoundation/CoreFoundation.h>

#include <IOKit/IOKitLib.h>
#include <IOKit/serial/IOSerialKeys.h>
#include <IOKit/IOBSD.h>

#import "PortnamesObject.h"

@implementation PortnamesObject

- init
{
	self = [super init];
	if( !self ) return self;

	PortnamesArray = [[NSMutableArray alloc] init];

	return self;
}

- (void)dealloc
{
    [PortnamesArray release];
	
    [super dealloc];
}

- (kern_return_t)buildPortnamesArray
{
	kern_return_t			kernResult; 
    mach_port_t				masterPort;
    CFMutableDictionaryRef	classesToMatch;
	CFMutableDictionaryRef	PortProperties;
	io_iterator_t			matchingServices;
	io_object_t				serPortService;
	
	//find seriel ports
	kernResult = IOMasterPort(MACH_PORT_NULL, &masterPort);
    if (KERN_SUCCESS != kernResult)
        NSLog(@"IOMasterPort returned %d\n", kernResult);

    classesToMatch = IOServiceMatching(kIOSerialBSDServiceValue);
    if (classesToMatch == NULL)
        NSLog(@"IOServiceMatching returned a NULL dictionary.\n");
    else {
        CFDictionarySetValue(classesToMatch,
                    CFSTR(kIOSerialBSDTypeKey),
                    CFSTR(kIOSerialBSDAllTypes /*kIOSerialBSDRS232Type*/));
    }

    kernResult = IOServiceGetMatchingServices(masterPort, classesToMatch, &matchingServices);    
    
    if (KERN_SUCCESS != kernResult)
        NSLog(@"IOServiceGetMatchingServices returned %d\n", kernResult);
	
	//empty old array
	[PortnamesArray removeAllObjects];
	
	//get human readable names and devices paths of all ports
    IOIteratorReset(matchingServices);
	
	if (KERN_SUCCESS != kernResult)
		return kernResult;
	
    while (serPortService = IOIteratorNext(matchingServices))
    {		
		kernResult = IORegistryEntryCreateCFProperties(serPortService,
														&PortProperties,
														kCFAllocatorDefault,
														kNilOptions);
														
		if (KERN_SUCCESS != kernResult)
			NSLog(@"IORegistryEntryCreateCFProperties returned %d\n", kernResult);
		
		[PortnamesArray addObject:(NSDictionary *)PortProperties];
    }

	IOObjectRelease(matchingServices);	// Release the iterator.
	
	return kernResult;
}

-(void)fillMenu:(id)thePopUp
{
	//key:	kIOTTYDeviceKey for	Port-Name
	[thePopUp removeAllItems];
	
	NSEnumerator *enumerator = [PortnamesArray objectEnumerator];
	NSDictionary *anDictionary;
	
	while (anDictionary = [enumerator nextObject]) {
		[thePopUp addItemWithTitle:[anDictionary objectForKey:(id)CFSTR(kIOTTYDeviceKey)]];
	}
	
	return;
}

- (NSString*)getDevicePathFromMenuitem:(int)anInt
{
	//key:	kIOCalloutDeviceKey	for BSD path
	return [[PortnamesArray objectAtIndex:anInt] objectForKey:(id)CFSTR(kIOCalloutDeviceKey)];
}

@end
