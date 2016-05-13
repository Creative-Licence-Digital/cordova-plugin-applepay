
var argscheck = require('cordova/argscheck'),
    utils = require('cordova/utils'),
    exec = require('cordova/exec');

var ApplePay = {

    setMerchantInformations: function(merchantId, merchantName) {
        cordova.exec(null, null, "ApplePay", "setMerchantInformations", [merchantId, merchantName]);
    },

    canMakePayments: function(successCallback, errorCallback) {
        cordova.exec(successCallback, errorCallback, "ApplePay", "canMakePayments", null);
    },

    makePaymentRequest: function(successCallback, errorCallback, order) {
        cordova.exec(successCallback, errorCallback, "ApplePay", "makePaymentRequest", [order]);
    }

};

module.exports = ApplePay;
