//
//  StormArchive.h
//  StormLib
//
//  Created by Jagdeep Manik on 3/14/18.
//

#import <Foundation/Foundation.h>
#import "StormLib.h"
#import "StormFile.h"

NS_ASSUME_NONNULL_BEGIN

@interface StormArchive : NSObject

@property (nonatomic) void *mpq;

- (nullable id)initWithArchive:(NSString *)path flags:(uint32_t)flags error:(NSError **)error;

- (nullable NSString *)archivePath:(NSError **)error;

- (BOOL)hasFile:(NSString *)filePath error:(NSError **)error;

- (BOOL)extract:(NSString *)pathInArchive pathOnDisk:(NSString *)pathOnDisk error:(NSError **)error;

- (nullable NSData *)fileInfo:(void *)handle infoClass:(SFileInfoClass)infoClass error:(NSError **)error;

- (BOOL)close:(NSError **)error;

+ (NSError *)lastError;

@end

NS_ASSUME_NONNULL_END
