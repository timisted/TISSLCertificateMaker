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

#import "TISSLCertificateMaker.h"

#include <stdio.h>
#include <stdlib.h>

#include "openssl/pem.h"
#include "openssl/conf.h"
#include "openssl/x509v3.h"
#ifndef OPENSSL_NO_ENGINE
#include "openssl/engine.h"
#endif

#pragma mark ___Enums and Forward Declarations___
typedef enum _TISSLCertificateDataGenerationType {
    TISSLCertificateDataGenerationTypeUnknown = 0,
    TISSLCertificateDataGenerationTypePrivateKey,
    TISSLCertificateDataGenerationTypePrivateKeyInfo,
    TISSLCertificateDataGenerationTypeCertificate,
    TISSLCertificateDataGenerationTypeCertificateInfo,
    TISSLCertificateDataGenerationTypeCertificateRequest,
    TISSLCertificateDataGenerationTypeCertificateRequestInfo
} TISSLCertificateDataGenerationType;


#pragma mark -
#pragma mark ___TISSLCertificate Private Methods___
@interface TISSLCertificateMaker (TISSLCertificateMakerPrivate)

- (BOOL)_generateCertificate:(BOOL)shouldGenerateCertificate certificateRequest:(BOOL)shouldGenerateCertificateRequest;
- (BOOL)_makeCertificateWithSerial:(int)serial days:(int)days;
- (BOOL)_makeCertificateRequestWithSerial:(int)serial days:(int)days;

- (void)_extractAndSaveDataType:(TISSLCertificateDataGenerationType)aType;
- (NSData **)_dataPointerForDataType:(TISSLCertificateDataGenerationType)aType;
- (NSString *)_stringForDataOfType:(TISSLCertificateDataGenerationType)aType;
- (void)_buildErrorFromPipe:(NSPipe *)aPipe;

- (int)_mkcertWithX509:(X509**)x509p EVP_PKEY:(EVP_PKEY **)pkeyp bits:(int)bits serial:(int)serial days:(int)days;
- (int)_mkreqWithX509:(X509_REQ **)req EVP_PKEY:(EVP_PKEY **)pkeyp bits:(int)bits serial:(int)serial days:(int)days;
- (int)_add_extWithX509:(X509 *)cert nid:(int)nid value:(char *)value;

- (void)_clearAllData;

@end

#pragma mark -
#pragma mark ___TISSLCertificate Implementation___
@implementation TISSLCertificateMaker

@synthesize numberOfBits = _numberOfBits;
@synthesize countryCode = _countryCode, organization = _organization, server = _server;
@synthesize certificatePrivateKeyInfoData = _certificatePrivateKeyInfoData;
@synthesize certificateInfoData = _certificateInfoData, requestInfoData = _requestInfoData;
@synthesize certificatePrivateKeyData = _certificatePrivateKeyData, certificateData = _certificateData, requestData = _requestData;
@synthesize mostRecentError = _mostRecentError;

#pragma mark -
#pragma mark Designed Initializer 
- (id)initWithNumberOfBits:(int)aNumber countryCode:(NSString *)aCountry organization:(NSString *)anOrganization server:(NSString *)aServer
{
    self = [super init];
    if (self != nil) {
        _numberOfBits = aNumber;
        
        _countryCode = [aCountry copy];
        _organization = [anOrganization copy];
        _server = [aServer copy];
    }
    return self;
}

#pragma mark Other Initialization, Factory Methods and Deallocation
+ (id)certificateMakerWithNumberOfBits:(int)aNumber countryCode:(NSString *)aCountry organization:(NSString *)anOrganization server:(NSString *)aServer
{
    return [[[self alloc] initWithNumberOfBits:aNumber countryCode:aCountry organization:anOrganization server:aServer] autorelease];
}

- (id)initWithCountryCode:(NSString *)aCountry organization:(NSString *)anOrganization server:(NSString *)aServer
{
    return [self initWithNumberOfBits:1024 countryCode:aCountry organization:anOrganization server:aServer];
}

+ (id)certificateMakerWithCountryCode:(NSString *)aCountry organization:(NSString *)anOrganization server:(NSString *)aServer
{
    return [[[self alloc] initWithCountryCode:aCountry organization:anOrganization server:aServer] autorelease];
}

- (void)dealloc
{
    [self _clearAllData];
    [_countryCode release];
    [_organization release];
    [_server release];
    
    [super dealloc];
}

#pragma mark -
#pragma mark Public Methods
- (BOOL)generateCertificate;
{
    return [self _generateCertificate:YES certificateRequest:NO];
}

- (BOOL)generateCertificateRequest
{
    return [self _generateCertificate:NO certificateRequest:YES];
}

- (BOOL)generateCertificateAndCertificateRequest
{
    return [self _generateCertificate:YES certificateRequest:YES];
}

#pragma mark Primary Certificate Generation
- (BOOL)_generateCertificate:(BOOL)shouldGenerateCertificate certificateRequest:(BOOL)shouldGenerateCertificateRequest
{
    [self _clearAllData];
    
    BOOL success = YES;
    
    CRYPTO_mem_ctrl(CRYPTO_MEM_CHECK_ON);
    
    NSPipe *errorPipe = [[NSPipe alloc] init];
    NSFileHandle *errorFileHandle = [errorPipe fileHandleForWriting];
    FILE *errorFilePointer = fdopen([errorFileHandle fileDescriptor], "w");
	_bio_err = BIO_new_fp(errorFilePointer, BIO_NOCLOSE);
    
    if( shouldGenerateCertificate ) 
        success &= [self _makeCertificateWithSerial:0 days:365];
    
    if( shouldGenerateCertificateRequest ) 
        success &= [self _makeCertificateRequestWithSerial:0 days:365];
    
    X509_free(_x509);
    X509_REQ_free(_x509request);
	EVP_PKEY_free(_privateKey);
    
#ifndef OPENSSL_NO_ENGINE
	ENGINE_cleanup();
#endif
	CRYPTO_cleanup_all_ex_data();
    
	CRYPTO_mem_leaks(_bio_err);
	BIO_free(_bio_err);
    fclose(errorFilePointer);
    
    if( !success )
        [self _buildErrorFromPipe:errorPipe];
    
    [errorPipe release];
    
    return success;
}

- (BOOL)_makeCertificateWithSerial:(int)serial days:(int)days
{
    //mkcert(&x509,&pkey,512,0,365);
    if( [self _mkcertWithX509:&_x509 EVP_PKEY:&_privateKey bits:[self numberOfBits] serial:serial days:days] )
    {
        //RSA_print_fp(stdout,_privateKey->pkey.rsa,0);
        [self _extractAndSaveDataType:TISSLCertificateDataGenerationTypePrivateKeyInfo];
        
        //PEM_write_PrivateKey(stdout,_privateKey,NULL,NULL,0,NULL, NULL);
        [self _extractAndSaveDataType:TISSLCertificateDataGenerationTypePrivateKey];
        
        //X509_print_fp(stdout,_x509);
        [self _extractAndSaveDataType:TISSLCertificateDataGenerationTypeCertificateInfo];
        
        //PEM_write_X509(stdout,_x509);
        [self _extractAndSaveDataType:TISSLCertificateDataGenerationTypeCertificate];
        
        return YES;
    }
    
    return NO;
}

- (BOOL)_makeCertificateRequestWithSerial:(int)serial days:(int)days
{
    //mkreq(&req,&pkey,512,0,365);
    if( [self _mkreqWithX509:&_x509request EVP_PKEY:&_privateKey bits:[self numberOfBits] serial:serial days:days] )
    {
        //X509_REQ_print_fp(stdout,req);
        [self _extractAndSaveDataType:TISSLCertificateDataGenerationTypeCertificateRequestInfo];
        
        //PEM_write_X509_REQ(stdout,req);
        [self _extractAndSaveDataType:TISSLCertificateDataGenerationTypeCertificateRequest];
        
        return YES;
    }
    
    return NO;
}

#pragma mark Internal Data Generation and Extraction
- (void)_clearAllData
{
    [_certificatePrivateKeyInfoData release]; _certificatePrivateKeyInfoData = nil;
    [_certificateInfoData release]; _certificateInfoData = nil;
    [_requestInfoData release]; _requestInfoData = nil;
    [_certificatePrivateKeyData release]; _certificatePrivateKeyData = nil;
    [_certificateData release]; _certificateData = nil;
    [_requestData release]; _requestData = nil;
    [_mostRecentError release]; _mostRecentError = nil; 
}

- (void)_extractAndSaveDataType:(TISSLCertificateDataGenerationType)aType
{
    NSPipe *pipe = [[NSPipe alloc] init];
    NSFileHandle *fileHandle = [pipe fileHandleForWriting];
    FILE *filePointer = fdopen([fileHandle fileDescriptor], "w");
    
    switch (aType) {
        case TISSLCertificateDataGenerationTypePrivateKeyInfo:
            RSA_print_fp(filePointer,_privateKey->pkey.rsa,0);
            break;
            
        case TISSLCertificateDataGenerationTypePrivateKey:
            PEM_write_PrivateKey(filePointer, _privateKey, NULL, NULL, 0, NULL, NULL);
            break;
            
        case TISSLCertificateDataGenerationTypeCertificateInfo:
            X509_print_fp(filePointer,_x509);
            break;
            
        case TISSLCertificateDataGenerationTypeCertificate:
            PEM_write_X509(filePointer,_x509);
            break;
            
        case TISSLCertificateDataGenerationTypeCertificateRequestInfo:
            X509_REQ_print_fp(filePointer,_x509request);
            break;
            
        case TISSLCertificateDataGenerationTypeCertificateRequest:
            PEM_write_X509_REQ(filePointer,_x509request);
            break;
    }
    
    fclose(filePointer);
    
    NSData **dataPointer = [self _dataPointerForDataType:aType];
    if( dataPointer ) {
        *dataPointer = [[[pipe fileHandleForReading] readDataToEndOfFile] copy];
    }
    [pipe release];
}

- (NSData **)_dataPointerForDataType:(TISSLCertificateDataGenerationType)aType
{
    switch (aType) {
        case TISSLCertificateDataGenerationTypePrivateKeyInfo:
            return &_certificatePrivateKeyInfoData;
            
        case TISSLCertificateDataGenerationTypePrivateKey:
            return &_certificatePrivateKeyData;
            
        case TISSLCertificateDataGenerationTypeCertificateInfo:
            return &_certificateInfoData;
            
        case TISSLCertificateDataGenerationTypeCertificate:
            return &_certificateData;
            
        case TISSLCertificateDataGenerationTypeCertificateRequestInfo:
            return &_requestInfoData;
            
        case TISSLCertificateDataGenerationTypeCertificateRequest:
            return &_requestData;
            
        default:
            return nil;
    }
}

- (NSString *)_stringForDataOfType:(TISSLCertificateDataGenerationType)aType
{
    NSData **dataPointer = [self _dataPointerForDataType:aType];
    
    if( dataPointer )
        return [[[NSString alloc] initWithData:*dataPointer encoding:NSUTF8StringEncoding] autorelease];
    
    return nil;
}

#pragma mark Error Handling
- (void)_buildErrorFromPipe:(NSPipe *)aPipe
{
    NSString *errorString = [[NSString alloc] initWithData:[[aPipe fileHandleForReading] readDataToEndOfFile] 
                                                  encoding:NSUTF8StringEncoding];
    
    NSMutableDictionary *errorDictionary = [NSDictionary dictionaryWithObject:errorString
                                                                       forKey:NSLocalizedDescriptionKey];
    _mostRecentError = [[NSError alloc] initWithDomain:@"com.timisted.TISSLCertificateErrorDomain"
                                                  code:-1 
                                              userInfo:errorDictionary];
    
    [errorString release];
}

#pragma mark -
#pragma mark Readonly String Accessors
- (NSString *)certificatePrivateKeyInfoString
{
    return [self _stringForDataOfType:TISSLCertificateDataGenerationTypePrivateKeyInfo];
}

- (NSString *)certificateInfoString
{
    return [self _stringForDataOfType:TISSLCertificateDataGenerationTypeCertificateInfo];
}

- (NSString *)requestInfoString
{
    return [self _stringForDataOfType:TISSLCertificateDataGenerationTypeCertificateRequestInfo];
}

- (NSString *)certificatePrivateKeyString
{
    return [self _stringForDataOfType:TISSLCertificateDataGenerationTypePrivateKey];
}

- (NSString *)certificateString
{
    return [self _stringForDataOfType:TISSLCertificateDataGenerationTypeCertificate];
}

- (NSString *)requestString
{
    return [self _stringForDataOfType:TISSLCertificateDataGenerationTypeCertificateRequest];
}

#pragma mark -
#pragma mark Code from OpenSSL Demo Code Files
static void callback(int p, int n, void *arg)
{
    char c='B';
    
    if (p == 0) c='.';
    if (p == 1) c='+';
    if (p == 2) c='*';
    if (p == 3) c='\n';
    fputc(c,stderr);
}

- (int)_mkcertWithX509:(X509**)x509p EVP_PKEY:(EVP_PKEY **)pkeyp bits:(int)bits serial:(int)serial days:(int)days
{
    X509 *x;
    EVP_PKEY *pk;
    RSA *rsa;
    X509_NAME *name=NULL;
    
    if ((pkeyp == NULL) || (*pkeyp == NULL))
    {
        if ((pk=EVP_PKEY_new()) == NULL)
        {
            //abort(); 
            return(0);
        }
    }
    else
        pk= *pkeyp;
    
    if ((x509p == NULL) || (*x509p == NULL))
    {
        if ((x=X509_new()) == NULL)
            goto err;
    }
    else
        x= *x509p;
    
    rsa=RSA_generate_key(bits,RSA_F4,callback,NULL);
    if (!EVP_PKEY_assign_RSA(pk,rsa))
    {
        //abort();
        goto err;
    }
    rsa=NULL;
    
    X509_set_version(x,2);
    ASN1_INTEGER_set(X509_get_serialNumber(x),serial);
    X509_gmtime_adj(X509_get_notBefore(x),0);
    X509_gmtime_adj(X509_get_notAfter(x),(long)60*60*24*days);
    X509_set_pubkey(x,pk);
    
    name=X509_get_subject_name(x);
    
    /* This function creates and adds the entry, working out the
     * correct string type and performing checks on its length.
     * Normally we'd check the return value for errors...
     */
    
    const unsigned char *country = (const unsigned char *)[[self countryCode] UTF8String];
    const unsigned char *org = (const unsigned char *)[[self organization] UTF8String];
    const unsigned char *server = (const unsigned char *)[[self server] UTF8String];
    
    X509_NAME_add_entry_by_txt(name,"C",
                               MBSTRING_ASC, country, -1, -1, 0);
    X509_NAME_add_entry_by_txt(name,"CN",
                               MBSTRING_ASC, org, -1, -1, 0);
    X509_NAME_add_entry_by_txt(name, "O", MBSTRING_ASC, server, -1, -1, 0);
    
    /* Its self signed so set the issuer name to be the same as the
     * subject.
     */
    X509_set_issuer_name(x,name);
    
    /* Add various extensions: standard extensions */
    [self _add_extWithX509:x nid:NID_basic_constraints value:"critical,CA:TRUE"];
    //add_ext(x, NID_basic_constraints, "critical,CA:TRUE");
    [self _add_extWithX509:x nid:NID_key_usage value:"critical,keyCertSign,cRLSign"];
    // add_ext(x, NID_key_usage, "critical,keyCertSign,cRLSign");
    
    [self _add_extWithX509:x nid:NID_subject_key_identifier value:"hash"];
    // add_ext(x, NID_subject_key_identifier, "hash");
    
    /* Some Netscape specific extensions */
    [self _add_extWithX509:x nid:NID_netscape_cert_type value:"sslCA"];
    //add_ext(x, NID_netscape_cert_type, "sslCA");
    
    //add_ext(x, NID_netscape_comment, "example comment extension");
    
    if (!X509_sign(x,pk,EVP_md5()))
        goto err;
    
    *x509p=x;
    *pkeyp=pk;
    return(1);
err:
    return(0);
}

- (int)_mkreqWithX509:(X509_REQ **)req EVP_PKEY:(EVP_PKEY **)pkeyp bits:(int)bits serial:(int)serial days:(int)days
{
	X509_REQ *x;
	EVP_PKEY *pk;
	RSA *rsa;
	X509_NAME *name=NULL;
	//STACK_OF(X509_EXTENSION) *exts = NULL;
	
	if ((pk=EVP_PKEY_new()) == NULL)
		goto err;
    
	if ((x=X509_REQ_new()) == NULL)
		goto err;
    
	rsa=RSA_generate_key(bits,RSA_F4,callback,NULL);
	if (!EVP_PKEY_assign_RSA(pk,rsa))
		goto err;
    
	rsa=NULL;
    
	X509_REQ_set_pubkey(x,pk);
    
	name=X509_REQ_get_subject_name(x);
    
	/* This function creates and adds the entry, working out the
	 * correct string type and performing checks on its length.
	 * Normally we'd check the return value for errors...
	 */
	const unsigned char *country = (const unsigned char *)[[self countryCode] UTF8String];
    const unsigned char *org = (const unsigned char *)[[self organization] UTF8String];
    const unsigned char *server = (const unsigned char *)[[self server] UTF8String];
    
    X509_NAME_add_entry_by_txt(name,"C",
                               MBSTRING_ASC, country, -1, -1, 0);
    X509_NAME_add_entry_by_txt(name,"CN",
                               MBSTRING_ASC, org, -1, -1, 0);
    X509_NAME_add_entry_by_txt(name, "O", MBSTRING_ASC, server, -1, -1, 0);
    
#ifdef REQUEST_EXTENSIONS
	/* Certificate requests can contain extensions, which can be used
	 * to indicate the extensions the requestor would like added to 
	 * their certificate. CAs might ignore them however or even choke
	 * if they are present.
	 */
    
	/* For request extensions they are all packed in a single attribute.
	 * We save them in a STACK and add them all at once later...
	 */
    
	exts = sk_X509_EXTENSION_new_null();
	/* Standard extenions */
    
	add_ext(exts, NID_key_usage, "critical,digitalSignature,keyEncipherment");
    
	/* This is a typical use for request extensions: requesting a value for
	 * subject alternative name.
	 */
    
	add_ext(exts, NID_subject_alt_name, "email:steve@openssl.org");
    
	/* Some Netscape specific extensions */
	add_ext(exts, NID_netscape_cert_type, "client,email");
    
    
    
#ifdef CUSTOM_EXT
	/* Maybe even add our own extension based on existing */
	{
		int nid;
		nid = OBJ_create("1.2.3.4", "MyAlias", "My Test Alias Extension");
		X509V3_EXT_add_alias(nid, NID_netscape_comment);
		add_ext(x, nid, "example comment alias");
	}
#endif
    
	/* Now we've created the extensions we add them to the request */
    
	X509_REQ_add_extensions(x, exts);
    
	sk_X509_EXTENSION_pop_free(exts, X509_EXTENSION_free);
    
#endif
	
	if (!X509_REQ_sign(x,pk,EVP_sha1()))
		goto err;
    
	*req=x;
	*pkeyp=pk;
	return(1);
err:
	return(0);
}

/* Add extension using V3 code: we can set the config file as NULL
 * because we wont reference any other sections.
 */

- (int)_add_extWithX509:(X509 *)cert nid:(int)nid value:(char *)value
{
    X509_EXTENSION *ex;
    X509V3_CTX ctx;
    /* This sets the 'context' of the extensions. */
    /* No configuration database */
    X509V3_set_ctx_nodb(&ctx);
    /* Issuer and subject certs: both the target since it is self signed,
     * no request and no CRL
     */
    X509V3_set_ctx(&ctx, cert, cert, NULL, NULL, 0);
    ex = X509V3_EXT_conf_nid(NULL, &ctx, nid, value);
    if (!ex)
        return 0;
    
    X509_add_ext(cert,ex,-1);
    X509_EXTENSION_free(ex);
    return 1;
}

@end
