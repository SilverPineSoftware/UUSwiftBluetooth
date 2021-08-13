//
//  UUString.m
//  Useful Utilities - Extensions for NSStrings
//
//  Created by Jonathan on 7/29/13.
//
//	License:
//  You are free to use this code for whatever purposes you desire. The only requirement is that you smile everytime you use it.
//

#import <Foundation/Foundation.h>
#import "UUString.h"

@implementation NSString (UUString)

- (bool) uuStartsWithSubstring:(NSString *)inSubstring
{
	NSRange r = [self rangeOfString:inSubstring];
	return (r.length > 0) && (r.location == 0);
}

@end
