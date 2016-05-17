# com.cld.cordova.applepay

Implements ApplePay payment request. The plugin process the order info with Apple Pay data but doesn't send the transaction to the merchant.
The callback gives back the payment token with the transaction identifier. You can then forward the transaction to be processed by the merchant of your choice.


## Installation

cordova plugin add https://github.com/jbeuckm/cordova-plugin-applepay.git

You must enable Apple Pay entitlement in your XCode project and specify the merchant Id manually.


## Supported Platforms

- iOS


## Methods

- ApplePay.canMakePayments
- ApplePay.setMerchantInformations
- ApplePay.makePaymentRequest


## ApplePay.canMakePayments

Determine whether the device can process payment requests using default payment network brand Amex, MasterCard, Visa and Discover.

### Example
```
ApplePay.canMakePayments((function({success}) {
    return console.log("can make payment", success),
  }), (function(err) {
    return console.log('Cannot determine if device can process payment'),
  })),
```

## ApplePay.setMerchantInformations

Set your Apple-given merchant Id and merchant name used in the payment sheet.

### Example
```
ApplePay.setMerchantInformations('merchant.com.example.app', 'Merchant Name'),
```

## ApplePay.makePaymentRequest

Request a payment with Apple Pay. The default payment country and currency is United States and US Dollar.

The shipping postal address is validated to be located in the United States by default.


### Parameters

- __order.items__: Array of item objects with form ```{ label: "Item", amount: 29.99 }```
- __order.shippingMethods__: Array of item objects with form ```{ identifier: "Standard Shipping", detail: "Delivers within two working days.", amount: 4.99 }```


### Example

```
function onError(err) {
    alert(JSON.stringify(err)),
}

function onSuccess(response) {
    alert(JSON.stringify(response)),
}

ApplePay.makePaymentRequest(onSuccess, onError, {
	items: [
      { label: "First Item", amount: 29.99 },
      { label: "Second Item", amount: 59.99 }
  ],
  shippingMethods: [
  	{ identifier: "Standard Shipping", detail: "Delivers within two working days.", amount: 0 },
  	{ identifier: "Fast Shipping", detail: "Delivers within 4 hours.", amount: 14.99 }
  ]
),
```

### Response Format

- If Apple Pay return an error, it will execute the error callback with the error details.
- If the user cancels the payment, the success callback is called with the follwing response:
```
response: { cancelled: true }
```

- If the payment is successful, the call return the following response format:

```
response:
{
    amount = "129.99",
    billingDetails = {
        ISOCountryCode = ca,
        city = Atlanta,
        country = USA,
        firstName = John,
        lastName = Appleseed,
        postalCode = 30303,
        state = GA,
        street = "3494 Kuhl Avenue"
    },
    contact = {
        email = "John-Appleseed@mac.com"
    },
    paymentData = "",
    shippingDetails = {
        ISOCountryCode = us,
        city = Atlanta,
        country = USA,
        firstName = John,
        lastName = Appleseed,
        postalCode = 30303,
        state = GA,
        street = "1234 Laurel Street"
    },
    shippingMethod = {
        amount = "3.99",
        detail = "Delivers within 4 business days.",
        label = "Standard Shipping"
    },
    transactionId = "Simulated Identifier"
}
```
