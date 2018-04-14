# StormLib

Fork of the original [StormLib](https://github.com/ladislav-zezula/StormLib) library, modified to have an Objective-C API.

## Installation

* (TODO) Support Carthage
* Note: Ensure "App Sandbox" is OFF

## Example

```objC
- (void)stormArchiveExample
{
    NSError *error = nil;
    
    /// Open Archive
    StormArchive *archive = [[StormArchive alloc] initWithArchive:@"/Users/someone/Desktop/MyMap.w3x" flags:0 error:&error];
    if (!archive)
    {
        NSLog(@"%@", error);
        return;
    }
    
    /// Extract File
    [archive extractFile:@"war3map.j" pathOnDisk:@"/Users/someone/Desktop/war3map.j" error:&error];
    if (error)
    {
        NSLog(@"%@", error);
        return;
    }
    
    /// Find All Files
    NSArray<NSDictionary *> *findResults = [archive findFilesMatching:@"*" error:&error];
    if (error)
    {
        NSLog(@"%@", error);
        return;
    }
    
    /// Print All File Names
    for (result in findResults)
    {
        NSLog(@"%@", result["PlainName"]);
    }
    
    /// Close Archive
    [archive close:&error];
}
```
