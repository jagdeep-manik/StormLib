//
//  StormArchive.h
//  StormLib
//
//  Created by Jagdeep Manik on 3/14/18.
//

#import <Foundation/Foundation.h>
#import "StormLib.h"

NS_ASSUME_NONNULL_BEGIN

@interface StormArchive : NSObject

- (nullable id)initWithArchive:(NSString *)path flags:(uint32_t)flags error:(NSError **)error;

- (BOOL)hasFile:(NSString *)filePath error:(NSError **)error;

- (BOOL)extractFile:(NSString *)pathInArchive pathOnDisk:(NSString *)pathOnDisk error:(NSError **)error;

- (BOOL)removeFile:(NSString *)pathInArchive error:(NSError **)error;

- (BOOL)writeToFile:(NSString *)pathInArchive data:(NSData *)data error:(NSError **)error;

- (NSData *)contentsAtPath:(NSString *)pathInArchive error:(NSError **)error;

- (NSArray<NSDictionary *> *)findFilesMatching:(NSString *)mask error:(NSError **)error;

- (BOOL)compact:(NSError **)error;

- (BOOL)close:(NSError **)error;

+ (NSError *)lastError;

@end

NS_ASSUME_NONNULL_END
