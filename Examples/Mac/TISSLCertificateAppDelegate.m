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

#import "TISSLCertificateAppDelegate.h"
#import "TISSLCertificateMaker.h"

@interface TISSLCertificateAppDelegate (TISSLCertificateAppDelegatePrivate)

- (NSArray *)_countriesArray;
- (NSString *)_selectedCountryCode;

@end

NSString *kTISSLCertificateCountryCodeKey = @"kTISSLCertificateCountryCodeKey";
NSString *kTISSLCertificateCountryStringKey = @"kTISSLCertificateCountryStringKey";

@implementation TISSLCertificateAppDelegate

@synthesize window;
@synthesize serverNameTextField = _serverNameTextField, organizationNameTextField = _organizationTextField;
@synthesize countryComboBox = _countryComboBox, informationTextView = _informationTextView;
@synthesize certificateTextView = _certificateTextView, requestTextView = _requestTextView;

- (IBAction)generateCertificateAndRequest:(id)sender
{
    // Clear all the text views
    [[self informationTextView] setString:@""];
    [[self certificateTextView] setString:@""];
    [[self requestTextView] setString:@""];
    
    // Create the certificate maker using the contents of the relevant text fields
    TISSLCertificateMaker *cert = [TISSLCertificateMaker certificateMakerWithCountryCode:[self _selectedCountryCode]
                                                                            organization:[[self organizationNameTextField] stringValue]
                                                                                  server:[[self serverNameTextField] stringValue]];
    
    // Generate both the certificate and the request
    BOOL success = [cert generateCertificateAndCertificateRequest];
    if( !success )
        NSLog(@"There was an error generating the certificate: %@", [cert mostRecentError]);
    else {
        // Set the contents of the text views
        NSString *certificate = [cert certificatePrivateKeyString];
        certificate = [certificate stringByAppendingString:[cert certificateString]];
        
        [[self informationTextView] setString:[cert certificateInfoString]];
        [[self certificateTextView] setString:certificate];
        [[self requestTextView] setString:[cert requestString]];
    }
}

- (NSArray *)_countriesArray
{
    static NSArray *countriesArray = nil;
    
    if( !countriesArray )
        countriesArray = [[NSArray alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"countryCodes" ofType:@"plist"]];
    
    return countriesArray;
}

- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(NSInteger)index
{
    return [[[self _countriesArray] objectAtIndex:index] valueForKey:kTISSLCertificateCountryStringKey];
}

- (NSInteger)numberOfItemsInComboBox:(NSComboBox *)aComboBox
{
    return [[self _countriesArray] count];
}

- (NSString *)_selectedCountryCode
{
    int selectedItemIndex = [[self countryComboBox] indexOfSelectedItem];
    
    if( selectedItemIndex > -1 )
        return [[[self _countriesArray] objectAtIndex:selectedItemIndex] valueForKey:kTISSLCertificateCountryCodeKey];
    
    return @"";
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	[[self informationTextView] setFont:[NSFont systemFontOfSize:9]];
    [[self certificateTextView] setFont:[NSFont systemFontOfSize:9]];
    [[self requestTextView] setFont:[NSFont systemFontOfSize:9]];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return YES;
}

@end
