
var argscheck = require('cordova/argscheck'),
    utils = require('cordova/utils'),
    exec = require('cordova/exec');

var ApplePay = {

    setMerchantId: function(merchantId) {
        cordova.exec(null, null, "ApplePay", "setMerchantId", [merchantId]);
    },

    makePaymentRequest: function(successCallback, errorCallback, order) {
        cordova.exec(successCallback, errorCallback, "ApplePay", "makePaymentRequest", [order]);
    }

};

module.exports = ApplePay;
