//
//  StormArchive.mm
//  StormLib
//
//  Created by Jagdeep Manik on 3/14/18.
//

#import "StormArchive.h"


#pragma mark - Private Properties

@interface StormArchive ()

@property (nonatomic) void *mpq;

@end


@implementation StormArchive

#pragma mark - Initialization

- (id)initWithArchive:(NSString *)path flags:(uint32_t)flags error:(NSError **)error
{
    void *handle;
    const char *utf8Path = [path UTF8String];
    
    if (!SFileOpenArchive(utf8Path, 0, flags, &handle))
    {
        
        *error = [StormArchive lastError];
        return nil;
    }
    
    self = [super init];
    self.mpq = handle;
    
    return self;
}

#pragma mark - File Management

- (BOOL)hasFile:(NSString *)filePath error:(NSError **)error
{
    const char *utf8Path = [filePath UTF8String];
    BOOL isFileInArchive = SFileHasFile(self.mpq, utf8Path);
    
    if (GetLastError() != ERROR_FILE_NOT_FOUND && GetLastError() != ERROR_SUCCESS)
    {
        *error = [StormArchive lastError];
        return NO;
    }
    else
    {
        SetLastError(ERROR_SUCCESS);
    }
    
    return isFileInArchive;
}

- (BOOL)extractFile:(NSString *)pathInArchive pathOnDisk:(NSString *)pathOnDisk error:(NSError **)error
{
    const char *utf8FilePath = [pathInArchive UTF8String];
    const char *utf8DiskPath = [pathOnDisk UTF8String];
    
    if (!SFileExtractFile(self.mpq, utf8FilePath, utf8DiskPath, 0))
    {
        *error = [StormArchive lastError];
        return NO;
    }
    
    if (GetLastError() == ERROR_HANDLE_EOF)
    {
        SetLastError(ERROR_SUCCESS);
    }
    
    return YES;
}

- (NSData *)contentsAtPath:(NSString *)pathInArchive error:(NSError **)error
{
    const char *utf8FilePath = [pathInArchive UTF8String];
    void *fileHandle;
    
    if (!SFileOpenFileEx(self.mpq, utf8FilePath, 0, &fileHandle))
    {
        *error = [StormArchive lastError];
        return nil;
    }
    
    NSMutableData *mutableData = [[NSMutableData alloc] init];
    char buffer[0x10000];
    unsigned int bytesRead = 1;
    
    while (bytesRead > 0)
    {
        if (!SFileReadFile(fileHandle, buffer, sizeof(buffer), &bytesRead, nil) && GetLastError() != ERROR_HANDLE_EOF)
        {
            *error = [StormArchive lastError];
            SFileCloseFile(fileHandle);
            return nil;
        }
        
        [mutableData appendBytes:buffer length:bytesRead];
    }
    
    if (GetLastError() == ERROR_HANDLE_EOF)
    {
        SetLastError(ERROR_SUCCESS);
    }
    
    if (!SFileCloseFile(fileHandle))
    {
        *error = [StormArchive lastError];
        return nil;
    }
    
    return mutableData;
}

#pragma mark - File Info

- (NSData *)fileInfo:(void *)handle infoClass:(SFileInfoClass)infoClass error:(NSError **)error
{
    void *buffer[0x400];
    unsigned int lengthNeeded;
    
    if (!SFileGetFileInfo(handle, infoClass, buffer, sizeof(buffer), &lengthNeeded))
    {
        if (GetLastError() == ERROR_INSUFFICIENT_BUFFER)
        {
            void *buffer[lengthNeeded];
            if (!SFileGetFileInfo(handle, infoClass, buffer, lengthNeeded, &lengthNeeded))
            {
                *error = [StormArchive lastError];
                return nil;
            }
        }
        else
        {
            *error = [StormArchive lastError];
            return nil;
        }
    }
    
    NSData *data = [[NSData alloc] initWithBytes:buffer length:lengthNeeded];
    return data;
}

#pragma mark - Cleanup

- (BOOL)close:(NSError **)error
{
    if (!SFileCloseArchive(self.mpq))
    {
        *error = [StormArchive lastError];
        return NO;
    }
    
    return YES;
}

#pragma mark - Error Handling

+ (NSError *)lastError
{
    uint32_t code = GetLastError();
    return [NSError errorWithDomain:NSPOSIXErrorDomain code:code userInfo:nil];
}

@end
