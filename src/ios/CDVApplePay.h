#import <UIKit/UIKit.h>
#import <Cordova/CDVPlugin.h>

#import <PassKit/PassKit.h>


@interface CDVApplePay : CDVPlugin <PKPaymentAuthorizationViewControllerDelegate>
{
    NSString *merchantId;
    NSArray<NSString *> *supportedNetworks;
    NSString *paymentStatus;
    NSMutableArray *shippingMethods;
    NSMutableArray *summaryItems;
}

@property (nonatomic, strong) NSString* paymentCallbackId;

- (void)setMerchantId:(CDVInvokedUrlCommand*)command;
- (void)makePaymentRequest:(CDVInvokedUrlCommand*)command;

@end
