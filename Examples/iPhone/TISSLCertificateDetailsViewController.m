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

#import "TISSLCertificateDetailsViewController.h"


@interface TISSLCertificateDetailsViewController (TISSLCertificateDetailsViewControllerPrivate)

- (NSArray *)_countriesArray;

@end

NSString *kTISSLCertificateCountryCodeKey = @"kTISSLCertificateCountryCodeKey";
NSString *kTISSLCertificateCountryStringKey = @"kTISSLCertificateCountryStringKey";

@implementation TISSLCertificateDetailsViewController

@synthesize delegate = _delegate;
@synthesize serverNameTextField = _serverNameTextField, organizationNameTextField = _organizationNameTextField;
@synthesize countryPicker = _countryPicker;

- (id)initWithDelegate:(NSObject <TISSLCertificateDetailsViewControllerDelegate> *)aDelegate
{
    self = [super initWithNibName:@"TISSLCertificateDetailsViewController" bundle:nil];
    if (self != nil) {
        _delegate = aDelegate;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIBarButtonItem *doneButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneAction:)] autorelease];
    self.navigationItem.rightBarButtonItem = doneButton;
    
    UIBarButtonItem *cancelButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelAction:)] autorelease];
    self.navigationItem.leftBarButtonItem = cancelButton;
    
    self.title = @"Certificate Info";
}

- (void)doneAction:(id)sender
{
    if( [[self delegate] respondsToSelector:@selector(sslCertificateDetailsViewControllerShouldEnd:)] )
        [[self delegate] sslCertificateDetailsViewControllerShouldEnd:self];
}

- (void)cancelAction:(id)sender
{
    if( [[self delegate] respondsToSelector:@selector(sslCertificateDetailsViewControllerShouldCancel:)] )
        [[self delegate] sslCertificateDetailsViewControllerShouldCancel:self];
}

- (NSString *)serverName { return [[self serverNameTextField] text]; }
- (NSString *)organizationName { return [[self organizationNameTextField] text]; }

- (NSString *)country
{
    return [[[self _countriesArray] objectAtIndex:[[self countryPicker] selectedRowInComponent:0]] valueForKey:kTISSLCertificateCountryCodeKey];
}

/* The picker displays a list of countries stored in countryCodes.plist. */
- (NSArray *)_countriesArray
{
    static NSArray *countriesArray = nil;
    
    if( !countriesArray )
        countriesArray = [[NSArray alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"countryCodes" ofType:@"plist"]];

    return countriesArray;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [[[self _countriesArray] objectAtIndex:row] valueForKey:kTISSLCertificateCountryStringKey];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [[self _countriesArray] count];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if( textField == [self serverNameTextField] )
        [[self organizationNameTextField] becomeFirstResponder];
    else
        [textField resignFirstResponder];
    
    return YES;
}

@end
