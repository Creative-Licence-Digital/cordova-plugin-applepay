#import "CDVApplePay.h"

@implementation CDVApplePay

@synthesize paymentCallbackId;

static NSString *const SHIPPING_FEES_LABEL = @"Shipping fees";


- (void) pluginInitialize {
    supportedNetworks = @[PKPaymentNetworkAmex, PKPaymentNetworkMasterCard, PKPaymentNetworkVisa, PKPaymentNetworkDiscover];
}


- (void) setMerchantInformations:(CDVInvokedUrlCommand*)command {
    merchantId = [command.arguments objectAtIndex:0];
    merchantName = [command.arguments objectAtIndex:1];
    NSLog(@"ApplePay merchant informations %@, %@", merchantId, merchantName);
}


- (void) canMakePayments:(CDVInvokedUrlCommand*)command {
    BOOL canPay = [PKPaymentAuthorizationViewController canMakePaymentsUsingNetworks:supportedNetworks];
    NSLog(@"ApplePay canMakePaymentsUsingNetworks == %s", canPay ? "true" : "false");

    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                            messageAsDictionary:@{@"success":[NSNumber numberWithBool:canPay]}];

    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}


- (void) makePaymentRequest:(CDVInvokedUrlCommand*)command {
    self.paymentCallbackId = command.callbackId;

    if (merchantId == nil) {
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                    messageAsString: @"Please call setMerchantId() with your Apple-given merchant ID."];

        [self.commandDelegate sendPluginResult:result callbackId:self.paymentCallbackId];
        return;
    }

    if ([PKPaymentAuthorizationViewController canMakePaymentsUsingNetworks:supportedNetworks] == NO) {
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                    messageAsString: @"This device cannot make payments."];

        [self.commandDelegate sendPluginResult:result callbackId:self.paymentCallbackId];
        return;
    }

    PKPaymentRequest *request = [PKPaymentRequest new];

    // Must be configured in Apple Developer Member Center
    request.merchantIdentifier = merchantId;

    NSArray *shippingDescriptions = [[command.arguments objectAtIndex:0] objectForKey:@"shippingMethods"];
    [request setShippingMethods:[self makeShippingMethods:shippingDescriptions]];

    NSDictionary *firstShippingMethod = shippingDescriptions.firstObject;
    NSDecimalNumber *shippingFees = [NSDecimalNumber decimalNumberWithDecimal:[[firstShippingMethod objectForKey:@"amount"] decimalValue]];
    NSArray *itemDescriptions = [[command.arguments objectAtIndex:0] objectForKey:@"items"];
    [request setPaymentSummaryItems:[self makeSummaryItems:itemDescriptions withShippingFees:shippingFees]];

    request.supportedNetworks = supportedNetworks;

    // What type of info you need (eg email, phone, address, etc);
    request.requiredBillingAddressFields = PKAddressFieldName | PKAddressFieldPostalAddress;
    request.requiredShippingAddressFields = PKAddressFieldPostalAddress | PKAddressFieldEmail;

    // Which payment processing protocol the vendor supports
    // This value depends on the back end, looks like there are two possibilities
    request.merchantCapabilities = PKMerchantCapability3DS; //PKMerchantCapabilityEMV;

    request.countryCode = @"US";
    request.currencyCode = @"USD";

    NSLog(@"ApplePay request == %@", request);

    PKPaymentAuthorizationViewController *authVC = [[PKPaymentAuthorizationViewController alloc] initWithPaymentRequest:request];

    authVC.delegate = self;

    if (authVC == nil) {
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: @"PKPaymentAuthorizationViewController was nil."];
        [self.commandDelegate sendPluginResult:result callbackId:self.paymentCallbackId];
        return;
    }

    [self.viewController presentViewController:authVC animated:YES completion:nil];
}


// MARK: - Helpers

- (NSArray *) makeSummaryItems:(NSArray *)itemDescriptions withShippingFees:(NSDecimalNumber *)shippingFees {

    summaryItems = [[NSMutableArray alloc] init];

    PKPaymentSummaryItem *totalSummaryItem = [PKPaymentSummaryItem summaryItemWithLabel:merchantName amount:NSDecimalNumber.zero];

    // add all the items to the summary items
    for (NSDictionary *item in itemDescriptions) {
        NSString *label = [item objectForKey:@"label"];
        NSDecimalNumber *amount = [NSDecimalNumber decimalNumberWithDecimal:[[item objectForKey:@"amount"] decimalValue]];
        PKPaymentSummaryItem *newItem = [PKPaymentSummaryItem summaryItemWithLabel:label amount:amount];
        totalSummaryItem.amount = [totalSummaryItem.amount decimalNumberByAdding:amount];
        [summaryItems addObject:newItem];
    }

    // add shipping fees if needed
    if ([shippingFees compare:NSDecimalNumber.zero] == NSOrderedDescending) {
        PKPaymentSummaryItem *feesItem = [PKPaymentSummaryItem summaryItemWithLabel:SHIPPING_FEES_LABEL amount:shippingFees];
        totalSummaryItem.amount = [totalSummaryItem.amount decimalNumberByAdding:shippingFees];
        [summaryItems addObject:feesItem];
    }

    totalPayment = totalSummaryItem.amount;
    [summaryItems addObject:totalSummaryItem];
    return summaryItems;
}


- (PKShippingMethod *) shippingMethodWithIdentifier:(NSString *)idenfifier detail:(NSString *)detail amount:(NSDecimalNumber *)amount {
    PKShippingMethod *shippingMethod = [PKShippingMethod new];
    shippingMethod.identifier = idenfifier;
    shippingMethod.label = idenfifier;
    shippingMethod.detail = detail;
    shippingMethod.amount = amount;
    return shippingMethod;
}


- (NSArray *) makeShippingMethods:(NSArray *)shippingDescriptions {

    shippingMethods = [[NSMutableArray alloc] init];

     for (NSDictionary *desc in shippingDescriptions) {
         NSString *identifier = [desc objectForKey:@"identifier"];
         NSString *detail = [desc objectForKey:@"detail"];
         NSDecimalNumber *amount = [NSDecimalNumber decimalNumberWithDecimal:[[desc objectForKey:@"amount"] decimalValue]];
         PKPaymentSummaryItem *newMethod = [self shippingMethodWithIdentifier:identifier detail:detail amount:amount];
         [shippingMethods addObject:newMethod];
     }

     return shippingMethods;
}


- (NSDictionary *) parseContactDetails:(PKContact *)contact {
    NSDictionary *name =  @{@"firstName": contact.name.givenName, @"lastName": contact.name.familyName};
    NSDictionary *address = [contact.postalAddress dictionaryWithValuesForKeys:@[@"street", @"city", @"state", @"postalCode", @"country", @"ISOCountryCode"]];

    NSMutableDictionary *contactDetails = [[NSMutableDictionary alloc] initWithDictionary:name];
    [contactDetails addEntriesFromDictionary:address];

    return contactDetails;
}

- (BOOL) isValidPaymentInformation:(NSDictionary *)form {

    NSString *country = form[@"country"];
    NSString *countryCode = form[@"ISOCountryCode"];
    if (country && country.length == 0 && countryCode.length == 0) {
        return NO;
    }

    for (NSString* key in form.keyEnumerator) {
        if (![key isEqualToString:@"country"] && ![key isEqualToString:@"ISOCountryCode"]) {
            NSString *value = [form objectForKey:key];
            if (!value || value.length == 0) {
                return NO;
            }
        }
    }
    return YES;
}


- (BOOL) isValidEmail:(NSString *)email {

    NSString *emailRegex = @"[A-Z0-9a-z][A-Z0-9a-z._%+-]*@[A-Za-z0-9][A-Za-z0-9.-]*\\.[A-Za-z]{2,6}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];

    if([emailTest evaluateWithObject:email]) {
        return YES;
    } else {
        return NO;
    }
}



// MARK: - PKPaymentAuthorizationViewControllerDelegate

/*
    Whenever the user changed their shipping information we will receive a
    callback here.

    Note that for privacy reasons the contact we receive will be redacted,
    and only have a city, ZIP, and country.

    You can use this method to estimate additional shipping charges and update
    the payment summary items.
*/
- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller didSelectShippingContact:(PKContact *)contact completion:(void (^)(PKPaymentAuthorizationStatus, NSArray<PKShippingMethod *> * _Nonnull, NSArray<PKPaymentSummaryItem *> * _Nonnull))completion {

    // check the shipping postal address is in the US by default.
    if([contact.postalAddress.ISOCountryCode caseInsensitiveCompare:@"us"] == NSOrderedSame ||
       [contact.postalAddress.country caseInsensitiveCompare:@"united states"] == NSOrderedSame ||
       [contact.postalAddress.country caseInsensitiveCompare:@"usa"] == NSOrderedSame)
    {
        completion(PKPaymentAuthorizationStatusSuccess, shippingMethods, summaryItems);
    } else {
        completion(PKPaymentAuthorizationStatusInvalidShippingPostalAddress, shippingMethods, summaryItems);
    }
}


/*
    Whenever the user changed their shipping method we will receive a
    callback here.

    You can use this method to update to total fees according to the selected shipping method.
*/
- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller didSelectShippingMethod:(PKShippingMethod *)shippingMethod completion:(void (^)(PKPaymentAuthorizationStatus, NSArray<PKPaymentSummaryItem *> * _Nonnull))completion {

    // update shipping fees item and recalculate total
    NSDecimalNumber *difference;

    for (PKPaymentSummaryItem *item in summaryItems) {

        if ([item.label isEqualToString:SHIPPING_FEES_LABEL]) {
            difference = [shippingMethod.amount decimalNumberBySubtracting:item.amount];
            item.amount = shippingMethod.amount;
        }
        else if ([item.label isEqualToString:merchantName]) {
            item.amount = [item.amount decimalNumberByAdding:difference];
            totalPayment = item.amount;
        }
    }

    completion(PKPaymentAuthorizationStatusSuccess, summaryItems);
}


/*
    This is where you would send your payment to be processed - here we will
    simply present a confirmation screen. If your payment processor failed the
    payment you would return `completion(.Failure)` instead. Remember to never
    attempt to decrypt the payment token on device.
*/
- (void) paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller
                        didAuthorizePayment:(PKPayment *)payment
                                 completion:(void (^)(PKPaymentAuthorizationStatus status))completion {
    NSLog(@"CDVApplePay: didAuthorizePayment");

    PKPaymentToken *paymentToken = payment.token;
    NSLog(@"Transaction identifier: %@", paymentToken.transactionIdentifier);

    if (paymentToken.paymentData) {
        NSString *data = [paymentToken.paymentData base64EncodedStringWithOptions:0];

        NSDictionary *billing = [self parseContactDetails:payment.billingContact];
        if (![self isValidPaymentInformation:billing]) {
            completion(PKPaymentAuthorizationStatusInvalidBillingPostalAddress);
            return;
        }

        NSDictionary *shipping = [self parseContactDetails:payment.shippingContact];
        if (![self isValidPaymentInformation:shipping]) {
            completion(PKPaymentAuthorizationStatusInvalidShippingPostalAddress);
            return;
        }

        NSDictionary *contact = @{@"email": payment.shippingContact.emailAddress};
        if (![self isValidEmail:contact[@"email"]]) {
            completion(PKPaymentAuthorizationStatusInvalidShippingContact);
            return;
        }

        NSDictionary *shippingMethod = [payment.shippingMethod dictionaryWithValuesForKeys:@[@"label", @"detail", @"amount"]];

        NSString *amount = [NSString stringWithFormat:@"%@", totalPayment];

        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                messageAsDictionary:@{@"paymentData":data,
                                                                      @"transactionId":paymentToken.transactionIdentifier,
                                                                      @"contact": contact,
                                                                      @"billingDetails": billing,
                                                                      @"shippingDetails": shipping,
                                                                      @"shippingMethod": shippingMethod,
                                                                      @"amount": amount}];

        paymentStatus = @"success";
        completion(PKPaymentAuthorizationStatusSuccess);

        [self.commandDelegate sendPluginResult:result callbackId:self.paymentCallbackId];
    } else {
        paymentStatus = @"failure";
        completion(PKPaymentAuthorizationStatusFailure);
    }
}


/*
    Use this method to dismiss the payment authorization view controller and update any other app state.

    When the user authorizes a payment request, this method is called after the status from the
    paymentAuthorizationViewController:didAuthorizePayment:completion: method’s completion block
    has been shown to the user.

    When the user cancels without authorizing the payment request, only paymentAuthorizationViewControllerDidFinish: is called.
*/
- (void) paymentAuthorizationViewControllerDidFinish:(PKPaymentAuthorizationViewController *)controller {
    [self.viewController dismissViewControllerAnimated:YES completion:nil];

    CDVPluginResult* result;
    if ([paymentStatus isEqualToString:@"success"]) {
        paymentStatus = nil;
    } else if ([paymentStatus isEqualToString:@"failure"]) {
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: @"Fail to make payment request."];
    } else {
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:@{@"cancelled":@true}];
    }

    paymentStatus = nil;
    if (result) {
        [self.commandDelegate sendPluginResult:result callbackId:self.paymentCallbackId];
    }
}


@end
