//
//  StormFile.m
//  StormLib
//
//  Created by Jagdeep Manik on 3/15/18.
//

#import "StormFile.h"
#import "StormLib.h"

@interface StormFile ()

@property (nonatomic, weak) StormArchive *parentArchive;
@property (nonatomic) void *fileHandle;

@property (nonatomic, strong) NSString *fullPath;
@property (nonatomic, strong) NSString *plainName;
@property (nonatomic, strong) NSNumber *fileSize;
@property (nonatomic, strong) NSNumber *compressedSize;
@property (nonatomic, strong) NSNumber *locale;
@property (nonatomic, strong) NSNumber *hashIndex;
@property (nonatomic, strong) NSNumber *blockIndex;
@property (nonatomic, strong) NSNumber *fileFlags;
@property (nonatomic, strong) NSNumber *fileTime;

@end

@implementation StormFile

#pragma mark - Initialization

- (id)initWithFilePath:(NSString *)filePath inArchive:(StormArchive *)archive
{
    self = [super init];
    
    self.fullPath = filePath;
    self.plainName = [filePath lastPathComponent];
    self.parentArchive = archive;
    self.fileHandle = nil;
    
    return self;
}

- (id)initWithFindData:(SFILE_FIND_DATA)data inArchive:(StormArchive *)archive
{
    self = [super init];
    self.parentArchive = archive;
    
    unsigned long fileTime = (((unsigned long) data.dwFileTimeHi) << 32) | data.dwFileTimeLo;
    self.fileHandle = nil;
    self.fileTime = [NSNumber numberWithUnsignedLong:fileTime];
    self.fullPath = [NSString stringWithCString:data.cFileName encoding:NSUTF8StringEncoding];
    self.plainName = [NSString stringWithCString:data.szPlainName encoding:NSUTF8StringEncoding];
    self.fileSize = [NSNumber numberWithUnsignedInteger:data.dwFileSize];
    self.compressedSize = [NSNumber numberWithUnsignedInteger:data.dwCompSize];
    self.locale = [NSNumber numberWithUnsignedInteger:data.lcLocale];
    self.hashIndex = [NSNumber numberWithUnsignedInteger:data.dwHashIndex];
    self.blockIndex = [NSNumber numberWithUnsignedInteger:data.dwBlockIndex];
    self.fileFlags = [NSNumber numberWithUnsignedInteger:data.dwFileFlags];
    
    return self;
}

#pragma mark - Properties

- (NSData *)loadProperty:(SFileInfoClass)infoClass
{
    NSError *error = nil;
    
    if (self.parentArchive == nil)
    {
        return nil;
    }
    
    // Attempt to open the file
    if (self.fileHandle == nil && [self open:&error] == NO)
    {
        return nil;
    }
    
    return [self.parentArchive fileInfo:self.fileHandle infoClass:infoClass error:&error];
}

- (NSString *)fullPath
{
    return self.fullPath;
}

- (NSString *)plainName
{
    return self.plainName;
}

- (BOOL)open:(NSError **)error
{
    const char *filePath = [self.fullPath UTF8String];
    void *fileHandle;
    
    if (!SFileOpenFileEx(self.parentArchive.mpq, filePath, 0, &fileHandle))
    {
        *error = [StormArchive lastError];
        return NO;
    }
    
    self.fileHandle = fileHandle;
    return YES;
}

- (BOOL)exists:(NSError **)error
{
    if (self.parentArchive == nil)
    {
        NSLog(@"Parent archive is nil for file.");
        return NO;
    }
    
    return [self.parentArchive hasFile:self.fullPath error:error];
}

@end
