#import <UIKit/UIKit.h>
#import <Cordova/CDVPlugin.h>

#import <PassKit/PassKit.h>


@interface CDVApplePay : CDVPlugin <PKPaymentAuthorizationViewControllerDelegate>
{
    NSString *merchantId;
    NSString *merchantName;
    NSMutableArray<NSString *> *supportedNetworks;
    NSString *paymentStatus;

    NSMutableArray *shippingMethods;
    NSMutableArray *summaryItems;     // Items, Shipping fees, (Tax), (Discount), Total
    NSArray *stateTaxes;              // optional
    NSArray *stateDiscounts;          // optional

    BOOL hasShippingMethods;          // shipping method is provided
}

@property (nonatomic, strong) NSString* paymentCallbackId;

- (void)setMerchantInformations:(CDVInvokedUrlCommand*)command;
- (void)canMakePayments:(CDVInvokedUrlCommand*)command;
- (void)makePaymentRequest:(CDVInvokedUrlCommand*)command;


@end
