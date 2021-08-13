//
//  UUDictionary.m
//  Useful Utilities - Extensions for NSDictionary
//
//  Created by Ryan DeVore on 4/18/14.
//
//	Smile License:
//  You are free to use this code for whatever purposes you desire. The only requirement is that you smile everytime you use it.
//

#import "UUDictionary.h"

@implementation NSDictionary (UUDictionary)

- (id) uuSafeGet:(NSString*)key
{
    return [self uuSafeGet:key forClass:nil defaultValue:nil];
}

- (id) uuSafeGet:(NSString*)key forClass:(Class)forClass
{
    return [self uuSafeGet:key forClass:forClass defaultValue:nil];
}

- (id) uuSafeGet:(NSString*)key forClass:(Class)forClass defaultValue:(id)defaultValue
{
    id obj = [self objectForKey:key];
    if (obj && ![obj isKindOfClass:[NSNull class]])
    {
        if (forClass == nil || [obj isKindOfClass:forClass])
        {
            return obj;
        }
    }
    
    return defaultValue;
}

- (NSNumber*) uuSafeGetNumber:(NSString*)key
{
    return [self uuSafeGetNumber:key defaultValue:nil];
}

- (NSNumber*) uuSafeGetNumber:(NSString*)key defaultValue:(NSNumber*)defaultValue
{
    id node = [self uuSafeGet:key];
    
    if (node)
    {
        if ([node isKindOfClass:[NSNumber class]])
        {
            return node;
        }
        else if ([node isKindOfClass:[NSString class]])
        {
            NSNumberFormatter* f = [[NSNumberFormatter alloc] init];
            [f setNumberStyle:NSNumberFormatterDecimalStyle];
            id val = [f numberFromString:node];
            if (val)
            {
                return val;
            }
        }
    }
    
    return defaultValue;
}

- (NSString*) uuSafeGetString:(NSString*)key
{
    return [self uuSafeGetString:key defaultValue:nil];
}

- (NSString*) uuSafeGetString:(NSString*)key defaultValue:(NSString*)defaultValue
{
    return [self uuSafeGet:key forClass:[NSString class] defaultValue:defaultValue];
}

- (NSData*) uuSafeGetData:(NSString*)key
{
    return [self uuSafeGetData:key defaultValue:nil];
}

- (NSData*) uuSafeGetData:(NSString*)key defaultValue:(NSData*)defaultValue
{
    return [self uuSafeGet:key forClass:[NSData class] defaultValue:defaultValue];
}

@end

@implementation NSMutableDictionary (UUMutableDictionary)

- (void) uuSafeSetValue:(nullable id)value forKey:(nonnull NSString*)key
{
    if (key)
    {
        [self setValue:value forKey:key];
    }
}

- (void) uuSafeRemove:(id)key
{
    if (key)
    {
        [self removeObjectForKey:key];
    }
}

@end
