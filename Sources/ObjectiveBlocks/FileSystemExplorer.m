#import "FileSystemExplorer.h"

@implementation FileSystemExplorer

// TODO: Use https://en.wikipedia.org/wiki/Box-drawing_character

+ (NSString *)paddingSpaces:(NSUInteger)level {
    NSMutableString *result = [NSMutableString new];
    for (int i = 0; i < level; i++) {
        [result appendString:@"   "];
    }
    return result;
}


+ (void)exploreDirectory:(NSString *)path level:(NSUInteger)level {
    NSError *error = nil;
    NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:&error];
    for (NSString *content in contents) {
        NSString *fullPath = [path stringByAppendingPathComponent:content];

        NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:fullPath error:&error];
        if (attributes && [attributes objectForKey:NSFileType] == NSFileTypeSymbolicLink) {
            NSString *destinationOfLink = [[NSFileManager defaultManager] destinationOfSymbolicLinkAtPath:fullPath error:&error];
            if (destinationOfLink) {
                BOOL destinationOfLinkExists = [[NSFileManager defaultManager] fileExistsAtPath:destinationOfLink];
                NSLog(@"%@|- %@ -%@-> %@", [self paddingSpaces:level], content, destinationOfLinkExists ? @"x" : @"-", destinationOfLink);
            } else {
                NSLog(@"ERROR! Is it a symbolic link or not? (error=%@)", error);
            }
        } else {
            BOOL isDirectory = NO;
            if ([[NSFileManager defaultManager] fileExistsAtPath:fullPath isDirectory:&isDirectory]) {
                NSLog(@"%@|- %@", [self paddingSpaces:level], content);
                if (isDirectory) {
                    [self exploreDirectory:fullPath level:(level + 1)];
                }
            }
        }
    }
}


+ (void)exploreFileSystem {
    NSString *homeDirectory = NSHomeDirectory();
    [self exploreDirectory:homeDirectory level:0];
}


@end
