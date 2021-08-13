//
//  UUDictionary.h
//  Useful Utilities - Extensions for NSDictionary
//
//  Created by Ryan DeVore on 4/18/14.
//
//	Smile License:
//  You are free to use this code for whatever purposes you desire. The only requirement is that you smile everytime you use it.
//


#import <Foundation/Foundation.h>

@interface NSDictionary (UUDictionary)

// Safely get the object at the specified key.  If the object is NSNull, then
// nil will be returned.
- (id) uuSafeGet:(NSString*)key;

// Safely gets an object and verifies it is of the expected class type. If
// the value is NSNull or not of the expecting type, nil will be returned
- (id) uuSafeGet:(NSString*)key forClass:(Class)forClass;

// Safely gets an object and verifies it is of the expected class type.  If the
// value is NSNull or not of the expected type, the passed in default will be
// returned.
- (id) uuSafeGet:(NSString*)key forClass:(Class)forClass defaultValue:(id)defaultValue;

// Safely gets an NSNumber.  If the value is an NSString, this method will
// attempt to convert it to a number object using NSNumberFormatter
- (NSNumber*) uuSafeGetNumber:(NSString*)key;
- (NSNumber*) uuSafeGetNumber:(NSString*)key defaultValue:(NSNumber*)defaultValue;

// Safely gets an NSString
- (NSString*) uuSafeGetString:(NSString*)key;
- (NSString*) uuSafeGetString:(NSString*)key defaultValue:(NSString*)defaultValue;

// Convenience wrappers
- (NSData*) uuSafeGetData:(NSString*)key;
- (NSData*) uuSafeGetData:(NSString*)key defaultValue:(NSData*)defaultValue;

@end

@interface NSMutableDictionary (UUMutableDictionary)

- (void) uuSafeSetValue:(id)value forKey:(NSString*)key;
- (void) uuSafeRemove:(id)key;

@end
