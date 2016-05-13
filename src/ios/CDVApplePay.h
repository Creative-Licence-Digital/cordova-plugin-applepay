#import <UIKit/UIKit.h>
#import <Cordova/CDVPlugin.h>

#import <PassKit/PassKit.h>


@interface CDVApplePay : CDVPlugin <PKPaymentAuthorizationViewControllerDelegate>
{
    NSString *merchantId;
    NSString *merchantName;
    NSArray<NSString *> *supportedNetworks;
    NSString *paymentStatus;
    NSMutableArray *shippingMethods;
    NSMutableArray *summaryItems;
}

@property (nonatomic, strong) NSString* paymentCallbackId;

- (void)setMerchantInformations:(CDVInvokedUrlCommand*)command;
- (void) canMakePayments:(CDVInvokedUrlCommand*)command;
- (void)makePaymentRequest:(CDVInvokedUrlCommand*)command;

@end
