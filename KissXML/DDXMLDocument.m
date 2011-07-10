#import "DDXMLPrivate.h"
#import "NSString+DDXML.h"


@implementation DDXMLDocument

/**
 * Returns a DDXML wrapper object for the given primitive node.
 * The given node MUST be non-NULL and of the proper type.
**/
+ (id)nodeWithDocPrimitive:(xmlDocPtr)doc freeOnDealloc:(BOOL)flag
{
	return [[[DDXMLDocument alloc] initWithDocPrimitive:doc freeOnDealloc:flag] autorelease];
}

- (id)initWithDocPrimitive:(xmlDocPtr)doc freeOnDealloc:(BOOL)flag
{
	self = [super initWithPrimitive:(xmlKindPtr)doc freeOnDealloc:flag];
	return self;
}

+ (id)nodeWithPrimitive:(xmlKindPtr)kindPtr freeOnDealloc:(BOOL)flag
{
	// Promote initializers which use proper parameter types to enable compiler to catch more mistakes
	NSAssert(NO, @"Use nodeWithDocPrimitive:freeOnDealloc:");
	
	return nil;
}

- (id)initWithPrimitive:(xmlKindPtr)kindPtr freeOnDealloc:(BOOL)flag
{
	// Promote initializers which use proper parameter types to enable compiler to catch more mistakes.
	NSAssert(NO, @"Use initWithDocPrimitive:freeOnDealloc:");
	
	[self release];
	return nil;
}

/**
 * Initializes and returns a DDXMLDocument object created from an NSData object.
 * 
 * Returns an initialized DDXMLDocument object, or nil if initialization fails
 * because of parsing errors or other reasons.
**/
- (id)initWithXMLString:(NSString *)string options:(NSUInteger)mask error:(NSError **)error
{
	return [self initWithData:[string dataUsingEncoding:NSUTF8StringEncoding]
	                  options:mask
	                    error:error];
}

/**
 * Initializes and returns a DDXMLDocument object created from an NSData object.
 * 
 * Returns an initialized DDXMLDocument object, or nil if initialization fails
 * because of parsing errors or other reasons.
**/
- (id)initWithData:(NSData *)data options:(NSUInteger)mask error:(NSError **)error
{
	if (data == nil || [data length] == 0)
	{
		if (error) *error = [NSError errorWithDomain:@"DDXMLErrorDomain" code:0 userInfo:nil];
		
		[self release];
		return nil;
	}
	
	// Even though xmlKeepBlanksDefault(0) is called in DDXMLNode's initialize method,
	// it has been documented that this call seems to get reset on the iPhone:
	// http://code.google.com/p/kissxml/issues/detail?id=8
	// 
	// Therefore, we call it again here just to be safe.
	xmlKeepBlanksDefault(0);
	
	xmlDocPtr doc = xmlParseMemory([data bytes], [data length]);
	if (doc == NULL)
	{
		if (error) *error = [NSError errorWithDomain:@"DDXMLErrorDomain" code:1 userInfo:nil];
		
		[self release];
		return nil;
	}
	
	return [self initWithDocPrimitive:doc freeOnDealloc:YES];
}

- (id)initWithReadIO:(xmlInputReadCallback)ioread closeIO:(xmlInputCloseCallback)ioclose context:(void*)ioctx options:(NSUInteger)mask error:(NSError **)error {
	
	// Even though xmlKeepBlanksDefault(0) is called in DDXMLNode's initialize method,
	// it has been documented that this call seems to get reset on the iPhone:
	// http://code.google.com/p/kissxml/issues/detail?id=8
	// 
	// Therefore, we call it again here just to be safe.
	xmlKeepBlanksDefault(0);
	
	xmlDocPtr doc = xmlReadIO(ioread, ioclose, ioctx, NULL, NULL, mask);
	if (doc == NULL)
	{
		if (error) *error = [NSError errorWithDomain:@"DDXMLErrorDomain" code:1 userInfo:nil];
		
		return nil;
	}
	
	return [self initWithDocPrimitive:doc freeOnDealloc:YES];
}

- (id)initWithRootElement:(DDXMLElement *)element {
    xmlDocPtr doc = xmlNewDoc(BAD_CAST "1.0");
    if (self = [self initWithDocPrimitive:doc freeOnDealloc:YES]) {
        if (element) {
            [self setRootElement:element];
        }
    }
    
    return self;
}

- (void)setVersion:(NSString *)version {
    xmlDocPtr doc = (xmlDocPtr)genericPtr;
    xmlFree((xmlChar *)doc->version);
    doc->version = xmlStrdup([version xmlChar]);
}

- (NSString *)version {
    xmlDocPtr doc = (xmlDocPtr)genericPtr;
    return [NSString stringWithUTF8String:((const char*)doc->version)];
}

- (void)setStandalone:(BOOL)standalone {
    xmlDocPtr doc = (xmlDocPtr)genericPtr;
    doc->standalone = standalone;
}

- (BOOL)isStandalone {
    xmlDocPtr doc = (xmlDocPtr)genericPtr;
    return doc->standalone;
}

/**
 * Returns the root element of the receiver.
**/
- (DDXMLElement *)rootElement
{
	xmlDocPtr doc = (xmlDocPtr)genericPtr;
	
	// doc->children is a list containing possibly comments, DTDs, etc...
	
	xmlNodePtr rootNode = xmlDocGetRootElement(doc);
	
	if (rootNode != NULL)
		return [DDXMLElement nodeWithElementPrimitive:rootNode freeOnDealloc:NO];
	else
		return nil;
}

- (void)setRootElement:(DDXMLNode *)root {
    xmlDocPtr doc = (xmlDocPtr)genericPtr;
    xmlDocSetRootElement(doc, (xmlNodePtr)root->genericPtr);
}

- (NSData *)XMLData
{
	return [[self XMLString] dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSData *)XMLDataWithOptions:(NSUInteger)options
{
	return [[self XMLStringWithOptions:options] dataUsingEncoding:NSUTF8StringEncoding];
}

@end