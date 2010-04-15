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

#import "TISSLCertificateViewController.h"
#import "TISSLCertificateMaker.h"
#import "TISSLCertificateDetailsViewController.h"

@implementation TISSLCertificateViewController

@synthesize certInfoTextView = _certInfoTextView, certTextView = _certTextView, csrTextView = _csrTextView;

/* Called when the user presses the Generate button */
- (IBAction)makeCertificate:(id)sender
{
    TISSLCertificateDetailsViewController *certDetailVC = [[TISSLCertificateDetailsViewController alloc] initWithDelegate:self];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:certDetailVC];
    [self presentModalViewController:navController animated:YES];
    [navController release];
    [certDetailVC release];
}

- (void)sslCertificateDetailsViewControllerShouldEnd:(TISSLCertificateDetailsViewController *)aController
{
    [self dismissModalViewControllerAnimated:YES];
    
    // Clear all the text views
    [[self certInfoTextView] setText:@""];
    [[self certTextView] setText:@""];
    [[self csrTextView] setText:@""];
    
    // Create the certificate maker using the contents of the relevant text fields
    TISSLCertificateMaker *certMaker = [TISSLCertificateMaker certificateMakerWithCountryCode:[aController country]
                                                                                 organization:[aController organizationName]
                                                                                       server:[aController serverName]];
    
    // Generate both the certificate and the request
    BOOL success = [certMaker generateCertificateAndCertificateRequest];
    if( !success )
        NSLog(@"There was an error generating the certificate: %@", [certMaker mostRecentError]);
    else {
        // Set the contents of the text views
        NSString *certificateString = [certMaker certificatePrivateKeyString];
        certificateString = [certificateString stringByAppendingString:[certMaker certificateString]];
        [[self certInfoTextView] setText:[certMaker certificateInfoString]];
        [[self certTextView] setText:certificateString];
        
        NSString *certificateRequest = [certMaker requestString];
        [[self csrTextView] setText:certificateRequest];
    }
}

- (void)sslCertificateDetailsViewControllerShouldCancel:(TISSLCertificateDetailsViewController *)aController
{
    [self dismissModalViewControllerAnimated:YES];
}

@end
