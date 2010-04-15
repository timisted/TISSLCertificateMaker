// Copyright (c) 2010 Tim Isted
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import <Foundation/Foundation.h>

#ifndef OPENSSL_NO_ENGINE
#include "openssl/engine.h"
#endif

#pragma mark -
#pragma mark ___TISSLCertificate Interface___
@interface TISSLCertificateMaker : NSObject {
@private
    int _numberOfBits;
    
    NSString *_countryCode;
    NSString *_organization;
    NSString *_server;
    
    NSData *_certificatePrivateKeyInfoData;
    NSData *_certificateInfoData;
    NSData *_requestInfoData;
    
    NSData *_certificatePrivateKeyData;
    NSData *_certificateData;
    NSData *_requestData;
    
    NSError *_mostRecentError;
    
    BIO *_bio_err;
    X509 *_x509;
    X509_REQ *_x509request;
    EVP_PKEY *_privateKey;
}

#pragma mark Designated Initializer
- (id)initWithNumberOfBits:(int)aNumber countryCode:(NSString *)aCountry organization:(NSString *)anOrganization server:(NSString *)aServer;

#pragma mark Factory Methods and Alternative Initializer
/* The default number of bits is 1024 */
+ (id)certificateMakerWithNumberOfBits:(int)aNumber countryCode:(NSString *)aCountry organization:(NSString *)anOrganization server:(NSString *)aServer;
- (id)initWithCountryCode:(NSString *)aCountry organization:(NSString *)anOrganization server:(NSString *)aServer;
+ (id)certificateMakerWithCountryCode:(NSString *)aCountry organization:(NSString *)anOrganization server:(NSString *)aServer;

#pragma mark Certificate Generation
/* These methods will return YES if the generation was successful, after which you can access the 
   data using the properties below.
   If they return NO, an error occurred; you _should_ be able to find out what this was by checking 
   the mostRecentError property. Error functionality has not yet been tested properly :( */
- (BOOL)generateCertificate;
- (BOOL)generateCertificateRequest;
- (BOOL)generateCertificateAndCertificateRequest;

#pragma mark Properties
@property (assign) int numberOfBits;

@property (retain) NSString *countryCode;
@property (retain) NSString *organization;
@property (retain) NSString *server;

/* Once certificates and requests have been generated, you can access either the resulting data raw, 
   ready e.g. for saving to a file, or use the convenience methods that return an (autoreleased) string
   initialized from the data. */
@property (readonly, retain) NSData *certificatePrivateKeyInfoData;
@property (readonly) NSString *certificatePrivateKeyInfoString;
@property (readonly, retain) NSData *certificateInfoData;
@property (readonly) NSString *certificateInfoString;
@property (readonly, retain) NSData *requestInfoData;
@property (readonly) NSString *requestInfoString;

@property (readonly, retain) NSData *certificatePrivateKeyData;
@property (readonly) NSString *certificatePrivateKeyString;
@property (readonly, retain) NSData *certificateData;
@property (readonly) NSString *certificateString;
@property (readonly, retain) NSData *requestData;
@property (readonly) NSString *requestString;

/* The localizedDescription for this error _should_ contain any errors that occurred if one of the 
   generation methods return NO. It will otherwise be nil. */
@property (readonly, retain) NSError *mostRecentError;

@end
