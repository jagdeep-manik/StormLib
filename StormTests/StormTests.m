//
//  StormTests.m
//  StormTests
//
//  Created by Jagdeep Manik on 3/14/18.
//

#import <XCTest/XCTest.h>
#import <Foundation/Foundation.h>
#import "StormArchive.h"

@interface StormTests : XCTestCase

@property (nonatomic, strong) NSString *mapPath;
@property (nonatomic, strong) NSString *resourcePath;
@property (nonatomic, strong) NSBundle *bundle;
@property (nonatomic, strong) StormArchive *archive;

@end

@implementation StormTests

- (void)setUp
{
    [super setUp];
    
    self.bundle = [NSBundle bundleForClass:[self class]];
    self.mapPath = [self.bundle pathForResource:@"(8)AzerothGrandPrix" ofType:@"w3x"];
    self.resourcePath = [self.bundle resourcePath];
    XCTAssertNotNil(self.mapPath);
    XCTAssertNotNil(self.resourcePath);
    
    NSError *error = nil;
    self.archive = [[StormArchive alloc] initWithArchive:self.mapPath flags:0 error:&error];
    XCTAssertNil(error);
}

- (void)tearDown
{
    NSError *error = nil;
    [self.archive close:&error];
    XCTAssertNil(error);
}

- (BOOL)isFile:(NSString *)firstFile equalTo:(NSString *)otherFile
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    return [fileManager contentsEqualAtPath:firstFile andPath:otherFile];
}

#pragma mark - Basic Tests

- (void)testExtraction
{
    NSError *error = nil;
    
    // Extract File
    NSString *destinationPath = [NSString stringWithFormat:@"%@/testExtraction.j", self.resourcePath];
    [self.archive extractFile:@"war3map.j" pathOnDisk:destinationPath error:&error];
    XCTAssertNil(error);
    
    // Check Correctness
    NSString *referencePath = [self.bundle pathForResource:@"testReferenceScript" ofType:@"j"];
    BOOL filesAreEqual = [self isFile:destinationPath equalTo:referencePath];
    XCTAssertTrue(filesAreEqual);
    
    // Remove File
    [[NSFileManager defaultManager] removeItemAtPath:destinationPath error:&error];
    XCTAssertNil(error);
}

- (void)testHasFile
{
    NSError *error = nil;
    
    // Check for file that exists
    BOOL fileExists = [self.archive hasFile:@"war3map.j" error:&error];
    XCTAssertNil(error);
    XCTAssertTrue(fileExists);
    
    // Check for file that does not exist
    fileExists = [self.archive hasFile:@"invalid" error:&error];
    XCTAssertNil(error);
    XCTAssertFalse(fileExists);
}

- (void)testRead
{
    NSError *error = nil;
    
    // Read file
    NSString *destinationPath = [NSString stringWithFormat:@"%@/testRead.j", self.resourcePath];
    NSData *contentsOfFile = [self.archive contentsAtPath:@"war3map.j" error:&error];
    XCTAssertNil(error);
    XCTAssertNotNil(contentsOfFile);
    
    // Write contents to disk and check correctness
    [contentsOfFile writeToFile:destinationPath atomically:NO];
    NSString *referencePath = [self.bundle pathForResource:@"testReferenceScript" ofType:@"j"];
    BOOL filesAreEqual = [self isFile:destinationPath equalTo:referencePath];
    XCTAssertTrue(filesAreEqual);
    
    // Remove File
    [[NSFileManager defaultManager] removeItemAtPath:destinationPath error:&error];
    XCTAssertNil(error);
}

@end
