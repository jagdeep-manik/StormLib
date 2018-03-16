//
//  StormFile.h
//  StormLib
//
//  Created by Jagdeep Manik on 3/15/18.
//

#import <Foundation/Foundation.h>
#import "StormArchive.h"

@class StormArchive;

NS_ASSUME_NONNULL_BEGIN

@interface StormFile : NSObject

- (id)initWithFilePath:(NSString *)filePath inArchive:(StormArchive *)archive;

- (id)initWithFindData:(SFILE_FIND_DATA)data inArchive:(StormArchive *)archive;

- (BOOL)exists:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
