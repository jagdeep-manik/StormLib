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

- (BOOL)removeFile:(NSString *)pathInArchive error:(NSError **)error
{
    const char *utf8FilePath = [pathInArchive UTF8String];
    if (!SFileRemoveFile(self.mpq, utf8FilePath, 0))
    {
        *error = [StormArchive lastError];
        return NO;
    }
    
    return YES;
}

- (BOOL)writeToFile:(NSString *)pathInArchive data:(NSData *)data error:(NSError **)error
{
    unsigned int preferredLocale = SFileGetLocale();
    unsigned int fileSize = (unsigned int) [data length];
    unsigned int flags = MPQ_FILE_COMPRESS | MPQ_FILE_ENCRYPTED | MPQ_FILE_REPLACEEXISTING;
    const char *utf8FilePath = [pathInArchive UTF8String];
    void *fileHandle;
    
    if (!SFileCreateFile(self.mpq, utf8FilePath, 0, fileSize, preferredLocale, flags, &fileHandle))
    {
        *error = [StormArchive lastError];
        return NO;
    }
    
    const void *dataPointer = [data bytes];
    if (!SFileWriteFile(fileHandle, dataPointer, fileSize, MPQ_COMPRESSION_ZLIB))
    {
        *error = [StormArchive lastError];
        SFileFinishFile(fileHandle);
        return NO;
    }
    
    if (!SFileFinishFile(fileHandle))
    {
        *error = [StormArchive lastError];
        return NO;
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

- (NSArray<NSDictionary *> *)findFilesMatching:(NSString *)mask error:(NSError **)error
{
    SFILE_FIND_DATA fileData;
    const char *utf8Mask = [mask UTF8String];
    void *findHandle = SFileFindFirstFile(self.mpq, utf8Mask, &fileData, nil);
    
    if (GetLastError() == ERROR_NO_MORE_FILES)
    {
        SetLastError(ERROR_SUCCESS);
        return nil;
    }
    
    if (!findHandle)
    {
        *error = [StormArchive lastError];
        return nil;
    }
    
    NSMutableArray<NSDictionary *> *results = [NSMutableArray array];
    BOOL hasMoreResults = YES;
    do
    {
        unsigned long fileTime = ((unsigned long) fileData.dwFileTimeHi << 32) | (fileData.dwFileTimeLo);
        NSDictionary *fileDataDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                            @"Path", [NSString stringWithCString:fileData.cFileName encoding:NSUTF8StringEncoding],
                                            @"PlainName", [NSString stringWithCString:fileData.szPlainName encoding:NSUTF8StringEncoding],
                                            @"BlockIndex", [NSNumber numberWithUnsignedInteger:fileData.dwBlockIndex],
                                            @"CompressedSize", [NSNumber numberWithUnsignedInteger:fileData.dwCompSize],
                                            @"FileFlags", [NSNumber numberWithUnsignedInteger:fileData.dwFileFlags],
                                            @"FileSize", [NSNumber numberWithUnsignedInteger:fileData.dwFileSize],
                                            @"HashIndex", [NSNumber numberWithUnsignedInteger:fileData.dwHashIndex],
                                            @"Locale", [NSNumber numberWithUnsignedInteger:fileData.lcLocale],
                                            @"FileTime", [NSNumber numberWithUnsignedLong:fileTime],
                                            nil];
        
        [results addObject:fileDataDictionary];
        hasMoreResults = SFileFindNextFile(findHandle, &fileData);
    } while (hasMoreResults);
    
    if (GetLastError() == ERROR_NO_MORE_FILES)
    {
        SetLastError(ERROR_SUCCESS);
    }
    
    if (!SFileFindClose(findHandle))
    {
        *error = [StormArchive lastError];
        return nil;
    }
    
    return results;
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

- (BOOL)compact:(NSError **)error
{
    if (!SFileCompactArchive(self.mpq, nil, 0))
    {
        *error = [StormArchive lastError];
        return NO;
    }
    
    return YES;
}

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
