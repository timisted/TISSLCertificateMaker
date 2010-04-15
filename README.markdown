#TISSLCertificateMaker
*A utility class to generate x509 certificates and signing requests, based on OpenSSL demo code*  
([http://cvs.openssl.org/dir?d=openssl/demos/x509](http://cvs.openssl.org/dir?d=openssl/demos/x509))

Tim Isted  
[http://www.timisted.net](http://www.timisted.net)  
Twitter: @[timisted](http://twitter.com/timisted)

##License
`TISSLCertificateMaker` is offered under the **MIT** license.

##Summary
`TISSLCertificateMaker` is an Objective-C class based around the demo source code from OpenSSL.

It generates x509 private keys and certificates, as well as certificate signing requests (CSRs).

To use `TISSLCertificateMaker`, you'll need to create an instance, and provide the country code, organization name, and server name for the certificate. Use one of the factory methods to avoid having to set the properties individually. The default is to provide a 1024-bit certificate, although you can specify a different number if you wish.

##Basic Usage
Copy all the files in the `TISSLCertificateMaker` directory (including those inside the `openssl` directory) into your project.

Create an instance of `TISSLCertificateMaker`, and provide the relevant info:
    TISSLCertificateMaker *certMaker = [TISSLCertificateMaker 
                                sslCertificateWithCountryCode:@"GB"
                                                 organization:@"Acme SSL Certificate Requirers for Global Domination, Inc"
                                                       server:@"www.example.com"];

Call the relevant generation method to create the certificate or request:
    BOOL success = [certMaker generateCertificateAndCertificateRequest];
This will return `YES` if generation was successful, otherwise `NO` to indicate that one of the operations failed. If one or more operations failed, access the `mostRecentError` `NSError` property to find out what happened (`NSError` generation has not been properly tested yet, sorry).

If generation was successful, you can access the raw data using the relevant property. There are also convenience accessors which return autoreleased `NSString` objects, initialized with the data.

##OpenSSL Linked Libraries and Binaries
###Mac
On the Mac, you'll need to link in the `libcrypto.dylib` and `libssl.dylib` dynamic libraries. 

###iPhone
The iPhone SDK doesn't include the OpenSSL libraries, so you'll need to include the relevant binaries in your project; these are included with the iPhone example. Use the `arm` variants for iPhone OS device targets and `i386` for the iPhone Simulator. The sample iPhone application uses two separate targets to differentiate between the libraries to include.

##Included Examples
Sample Mac and iPhone examples are included.

##To Do List
* Refactoring of internal certificate generation, currently using code verbatim from openssl demos.
* Check that `NSError` generation works