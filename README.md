cordova-plugin-libraryx
====================

Get camera roll with gps info

Installation
------------

<code> cordova plugin add https://github.com/mrameezraja/cordova-plugin-libraryx </code>


Methods
-------
- cordova.plugins.libraryX.getAll
- cordova.plugins.libraryX.getAsync


cordova.plugins.libraryX.getAll
-------------------------------------------

Gets all photos at once.

<pre>
<code>
  cordova.plugins.libraryX.getAll(function(photos){
    console.log(JSON.stringify(photos));
  }, function(error){
    console.log(error);
  })
</code>
</pre>

Readings:
- imageUrl
- hasGPS
- latitude
- longitude

cordova.plugins.libraryX.getAsync
--------------------------------

Get photo one by one

<pre>
<code>
  cordova.plugins.libraryX.getAsync(function(photo){
      console.log(photo);
  }, function(error){
    console.log(error);
  })
</code>
</pre>


Supported Platforms
-------------------

- IOS
- Android (In Progress)
