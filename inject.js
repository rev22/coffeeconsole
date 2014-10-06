(function (window, document) {
  var iframe, doc;

  var baseURL = document.getElementById('coffeeconsoleinject').src.replace('/inject.js', '');

  window.COFFEECONSOLE = {
    contentWindow: window,
    contentDocument: document,
    baseURL: baseURL
  };

  if (iframe = document.getElementById('coffeeconsole')) {
    window.COFFEECONSOLE.console = iframe;
    document.getElementById('coffeeconsole').style.display = 'block';
  } else {
    iframe = document.createElement('iframe');
    window.COFFEECONSOLE.console = iframe;

    document.body.appendChild(iframe);

    iframe.id = 'coffeeconsole';
    iframe.style.display = 'block';
    iframe.style.background = '#fff';
    iframe.style.zIndex = '9999';
    iframe.style.position = 'absolute';
    iframe.style.top = '0px';
    iframe.style.left = '0px';
    iframe.style.width = '100%';
    iframe.style.height = '100%';
    iframe.style.border = '0';

    doc = iframe.contentDocument || iframe.contentWindow.document;

    doc.open();
    doc.write('<!DOCTYPE html><html id="coffeeconsole"><head><title>coffeeconsole</title><meta id="meta" name="viewport" content="width=device-width; height=device-height; user-scalable=no; initial-scale=1.0" /><link rel="stylesheet" href="' + baseURL + '/console.css" type="text/css" /></head><body><form><textarea autofocus id="exec" spellcheck="false" autocapitalize="off" autofocus rows="1"></textarea></form><div id="console"><ul id="output"></ul></div><div id="footer"><a href="http://github.com/rev22/coffeeconsole">Fork Coffeeconsole on Github</a></div><script src="' + baseURL + '/prettify.js"></script><script src="' + baseURL + '/coffee-script.js"></script><script src="' + baseURL + '/console.js?' + Math.random() + '"></script></body></html>');
    doc.close();
    
    iframe.contentWindow.onload = function () {
      this.document.getElementById('exec').focus();
    } 
  }
})(this, document);
