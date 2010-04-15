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

#import <UIKit/UIKit.h>

@class TISSLCertificateDetailsViewController;

@protocol TISSLCertificateDetailsViewControllerDelegate

- (void)sslCertificateDetailsViewControllerShouldEnd:(TISSLCertificateDetailsViewController *)aController;
- (void)sslCertificateDetailsViewControllerShouldCancel:(TISSLCertificateDetailsViewController *)aController;

@end


@interface TISSLCertificateDetailsViewController : UIViewController <UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate> {
    NSObject <TISSLCertificateDetailsViewControllerDelegate> *_delegate;
    
    UITextField *_serverNameTextField;
    UITextField *_organizationNameTextField;
    UIPickerView *_countryPicker;
}

- (id)initWithDelegate:(NSObject <TISSLCertificateDetailsViewControllerDelegate> *)aDelegate;

@property (assign) NSObject <TISSLCertificateDetailsViewControllerDelegate> *delegate;

@property (nonatomic, retain) IBOutlet UITextField *serverNameTextField;
@property (nonatomic, retain) IBOutlet UITextField *organizationNameTextField;
@property (nonatomic, retain) IBOutlet UIPickerView *countryPicker;

@property (readonly) NSString *serverName;
@property (readonly) NSString *organizationName;
@property (readonly) NSString *country;

@end
