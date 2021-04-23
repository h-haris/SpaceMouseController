
/*
//Liste der Ports aufbauen
//Nummer | Klarname des Ports | Device
*/

/*
//Achtung!! Standard C!!

// Returns an iterator across all known modems. Caller is responsible for
// releasing the iterator when iteration is complete.
static kern_return_t FindModems(io_iterator_t *matchingServices)
{
    kern_return_t		kernResult; 
    mach_port_t			masterPort;
    CFMutableDictionaryRef	classesToMatch;


    kernResult = IOMasterPort(MACH_PORT_NULL, &masterPort);
    if (KERN_SUCCESS != kernResult)
        printf("IOMasterPort returned %d\n", kernResult);


    classesToMatch = IOServiceMatching(kIOSerialBSDServiceValue);
    if (classesToMatch == NULL)
        printf("IOServiceMatching returned a NULL dictionary.\n");
    else {
        CFDictionarySetValue(classesToMatch,
                    CFSTR(kIOSerialBSDTypeKey),
                    CFSTR(kIOSerialBSDAllTypes));//kIOSerialBSDModemType
    }

    kernResult = IOServiceGetMatchingServices(masterPort, classesToMatch, 					matchingServices);    
    
    if (KERN_SUCCESS != kernResult)
        printf("IOServiceGetMatchingServices returned %d\n", kernResult);

    return kernResult;
}
    
// Given an iterator across a set of modems, return the BSD path to the first one.
// If no modems are found the path name is set to an empty string.
static kern_return_t GetModemPath(io_iterator_t serialPortIterator, char *bsdPath, CFIndex maxPathSize)
{
    io_object_t		modemService;
    kern_return_t	kernResult = KERN_FAILURE;
    Boolean		modemFound = false;
    
    // Initialize the returned path
    *bsdPath = '\0';
    
   
    IOIteratorReset(serialPortIterator);
    
    //while ((modemService = IOIteratorNext(serialPortIterator)) && !modemFound)
    while (modemService = IOIteratorNext(serialPortIterator))
    {
        CFTypeRef	modemNameAsCFString;
        CFTypeRef	bsdPathAsCFString;

//http://developer.apple.com/techpubs/macosx/Darwin/IOKit/DeviceInterfaces/HID/hid/Using_HID_C__Interfaces.html
//Listing 1-6 (tut es "Toll-free bridged")

//file://localhost/Eliza%20X/System/Library/Frameworks/IOKit.framework/Versions/A/Resources/English.lproj/Documentation/Reference/IOKit/IOKitLib/Functions/Functions.html#IORegistryEntryCreateCFProperties


        modemNameAsCFString = IORegistryEntryCreateCFProperty(modemService,
                                                              CFSTR(kIOTTYDeviceKey),	//key
                                                              kCFAllocatorDefault,
                                                              0);						//return: value
        if (modemNameAsCFString)
        {
            char modemName[128];
            Boolean result;
            
            result = CFStringGetCString(modemNameAsCFString,	//key
                                        modemName,				//value
                                        sizeof(modemName), 
                                        kCFStringEncodingASCII);
            CFRelease(modemNameAsCFString);
            
            if (result)
            {
                printf("Serial stream name: %s, ", modemName);
                modemFound = true;
                kernResult = KERN_SUCCESS;
            }
        }

        bsdPathAsCFString = IORegistryEntryCreateCFProperty(modemService,
                                                            CFSTR(kIOCalloutDeviceKey),	//key
                                                            kCFAllocatorDefault,
                                                            0);							//return: value
        if (bsdPathAsCFString)
        {
            Boolean result;
            
            result = CFStringGetCString(bsdPathAsCFString,		//key
                                        bsdPath,				//value
                                        maxPathSize, 
                                        kCFStringEncodingASCII);
            CFRelease(bsdPathAsCFString);
            
            if (result)
                printf("BSD path: %s", bsdPath);
        }

        printf("\n");
    
        (void) IOObjectRelease(modemService);
        // We have sucked this service dry of information so release it now.
    }
        
    return kernResult;
}


*/

/*
    io_iterator_t	serialPortIterator;
    char		bsdPath[ MAXPATHLEN ];
    
    kernResult = FindModems(&serialPortIterator);
    kernResult = GetModemPath(serialPortIterator, bsdPath, sizeof(bsdPath));
    IOObjectRelease(serialPortIterator);	// Release the iterator.
*/

/*
		PortNameAsCFString = IORegistryEntryCreateCFProperty(serPortService,
                                                              CFSTR(kIOTTYDeviceKey),	//key
                                                              kCFAllocatorDefault,
                                                              0);						//return: value
        if (PortNameAsCFString)
        {
            char portName[128];
            
            result = CFStringGetCString(PortNameAsCFString,	//key
                                        portName,			//value
                                        sizeof(portName), 
                                        kCFStringEncodingASCII);
            CFRelease(PortNameAsCFString);
            
        }

        bsdPathAsCFString = IORegistryEntryCreateCFProperty(serPortService,
                                                            CFSTR(kIOCalloutDeviceKey),	//key
                                                            kCFAllocatorDefault,
                                                            0);							//return: value
        if (bsdPathAsCFString)
        {
            char portPath[128];
			
            result = CFStringGetCString(bsdPathAsCFString,		//key
                                        portPath,				//value
                                        sizeof(portPath), 
                                        kCFStringEncodingASCII);
            CFRelease(bsdPathAsCFString);

        }
    
        (void) IOObjectRelease(serPortService);
        //Iterator freigeben
*/

/*
//SPCMObject initialisieren
//[theMouse setDevPathString:@"/dev/cu.USA28X112P1.1\0"];
//[theMouse connectToDevice:"/dev/cu.USA28X212P1.1\0"];
//[theMouse connectToDevice];
*/

- (BOOL)deliverTranslation:(float)x :(float)y :(float)z
	  	       andRotation:(float)a :(float)b :(float)c
{
	// If we can send an event we will compose the right transformation
	// matrix and them we'll pass it along.
	// We will return our success flag.
	
        /*
	if( !sendEvents ) return NO;
	if( syncEvents && awaitingSync ) return NO;
        */
        
	// Looks like we might really send it. depending on the handedness
	// we have to adjust the given values. As we remember they always come
	// from a right handed device. (at least we have said they should be
	// that way :-)
	
	/*
	if( !targetIsRightHanded )
	{
		 z = -z;
		 a = -a;
		 b = -b;
	}
	[transformMatrix setByTranslation:x :y: z andRotation:a :b :c];
	*/
        
	//[target transformationEvent:transformMatrix];
        
        /*
	if( syncEvents ) awaitingSync = YES;
	return YES;
        */
        
        /*
        Auf irgendeine Art über CoreFoundation einen Event abschicken, auf den
        die Demo-Applikation von 3D-Connexion reagiert
        
        siehe: CFMessagePort
        */
        return NO;
        //Überarbeiten!!
}

- (BOOL)deliverKeyPress:(int)keys
{
	/*
        Auf irgendeine Art über CoreFoundation einen Event abschicken, auf den
        die Demo-Applikation von 3D-Connexion reagiert
        
        siehe: CFMessagePort
        */
        
        //Key Down und Key Up berücksichtigen!!
        return NO;
        //Überarbeiten!!
}

/*
    auf k3DDevice_Initialize und k3DDevice_Close reagieren !?
*/

/* alt/nicht benutzt

void *SpaceMouseActivityEntry( DPSTimedEntry tag, double now, id myDriver )
{
	[myDriver checkActivity];
	return myDriver;
}

- setTarget:anObject
{
	// When becoming inactive we will reset all the activity checks.
	// The timeentry settings are save because it will only work when we are
	// connected to a device! So tentry does reflect the right conditions.
	/*
	if( [self isConnectedToDevice] )
	{
		// We will disable events here to ensure that they won't interfere
		// while we're trying to 'shut them down'.
		
		sendEvents = NO;
		
		if( anObject == nil )
		{
			if( tentry  ) DPSRemoveTimedEntry( tentry );
			if( isActive ) [target transformationDidEnd:self];
			isActive = NO;
			newActions = NO;
			tentry = 0;
		}
		else
		{
			if( !tentry )
			{
				tentry = DPSAddTimedEntry( 1, 
								   (DPSTimedEntryProc)SpaceMouseActivityEntry, 
								   self, NX_MODALRESPTHRESHOLD );
			}
			isActive = NO;
			newActions = NO;
		}
	}
	return [super setTarget:anObject];
       
}

- checkActivity
{
	// Here we will handle the activitv control.
	// If we are still isActive we might check the conditions.
	
	if( !isActive ) return self;
	
	// If there has been a new activity in the last time-period we will
	// assume that the transformation did not end yet. But we will reset the
	// flag.
	// Otherwise we will infor our target that no new action did take place.
	
	if( newActions )
		newActions = NO;
	else
	{
		[target transformationDidEnd:self];
		isActive = NO;
	}
	return self;
}

*/
