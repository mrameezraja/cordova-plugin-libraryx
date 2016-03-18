var argscheck = require('cordova/argscheck'),
    utils = require('cordova/utils'),
    exec = require('cordova/exec');

var LibraryX = function(){

}

LibraryX.prototype = {
  getAll: function(successCallback, errorCallback){
      cordova.exec(successCallback, errorCallback, "LibraryX", "showGallery", []);
  },
  getAsync: function(successCallback, errorCallback){
      cordova.exec(successCallback, errorCallback, "LibraryX", "getAsync", []);
  }
}

module.exports = new LibraryX();
