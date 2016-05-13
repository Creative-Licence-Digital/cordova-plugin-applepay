
var argscheck = require('cordova/argscheck'),
    utils = require('cordova/utils'),
    exec = require('cordova/exec');

var ApplePay = {

    // add function to check if we can make and can make with providers

    setMerchantInformations: function(merchantId, merchantName) {
        cordova.exec(null, null, "ApplePay", "setMerchantInformations", [merchantId, merchantName]);
    },

    makePaymentRequest: function(successCallback, errorCallback, order) {
        cordova.exec(successCallback, errorCallback, "ApplePay", "makePaymentRequest", [order]);
    }

};

module.exports = ApplePay;
