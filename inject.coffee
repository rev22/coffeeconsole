((window, document)->
  baseURL = document.getElementById("coffeeconsoleinject").src.replace("/inject.js", "")
  window.COFFEECONSOLE =
    contentWindow: window
    contentDocument: document
    baseURL: baseURL

  if iframe = document.getElementById("coffeeconsole")
    window.COFFEECONSOLE.console = iframe
    document.getElementById("coffeeconsole").style.display = "block"
  else
    iframe = document.createElement("iframe")
    window.COFFEECONSOLE.console = iframe
    document.body.appendChild iframe
    iframe.id = "coffeeconsole"
    iframe.style.display = "block"
    iframe.style.background = "#fff"
    iframe.style.zIndex = "9999"
    iframe.style.position = "absolute"
    iframe.style.top = "0px"
    iframe.style.left = "0px"
    iframe.style.width = "100%"
    iframe.style.height = "100%"
    iframe.style.border = "0"
    doc = iframe.contentDocument or iframe.contentWindow.document
    doc.open()
    doc.write "\n<html lang=\"en\" manifest=\"coffeeconsole.appcache\" style=\"height:100%\">\n    <meta charset=\"utf-8\">\n    <title>Coffeeconsole!</title>\n    <meta id=\"meta\" name=\"viewport\" content=\"width=device-width, user-scalable=no, initial-scale=1\">\n    <link rel=\"icon\" href=\"#{baseURL}/favicon.png\" type=\"image/png\">\n    <link rel=\"apple-touch-icon\" href=\"#{baseURL}/favicon.png\">\n    <meta name=\"apple-mobile-web-app-capable\" content=\"yes\">\n    <meta name=\"apple-mobile-web-app-status-bar-style\" content=\"black\">\n    <link rel=\"stylesheet\" href=\"#{baseURL}/console.css\">\n    <body style=\"height:100%;margin:0;overflow:hidden\">\n        <div id=\"console\" tabindex=\"0\" style=\"height:100%;display:table;width:100%\">\n            <div style=\"display:table-row;min-height:1em\">\n                <div style=\"max-height:5em;overflow:hidden;position:relative;display:block\">\n                    <div style=\"float:left;width:100%\">\n                        <form class=\"consoleHeader\">\n                            <textarea autofocus=\"\" id=\"exec\" spellcheck=\"false\" autocapitalize=\"off\" rows=\"1\" autocorrect=\"off\"></textarea>\n                        </form>\n                    </div>\n                </div>\n            </div>\n            <div style=\"position:relative;height:100%;overflow:hidden;display:table-row\">\n                <div style=\"position:relative;width:100%;height:100%;\">\n                    <div style=\"position:absolute;top:0;right:0;left:0;bottom:0;overflow:auto\">\n                        <div>\n                            <ul id=\"output\"></ul>\n                        </div>\n                    </div>\n                </div>\n            </div>\n            <div id=\"footer\" style=\"display:table-row\">\n                <a href=\"#{baseURL}/http://github.com/rev22/coffeeconsole\">Fork Coffeeconsole on Github</a>\n            </div>\n        </div>\n        <script src=\"#{baseURL}/prettify.packed.js\"></script>\n        <script src=\"#{baseURL}/EventSource.js\"></script>\n        <script src=\"#{baseURL}/coffee-script.js\"></script>\n        <script src=\"#{baseURL}/console.js\"></script>\n    </body>\n</html>"
    doc.close()
    iframe.contentWindow.onload = ->
      @document.getElementById("exec").focus()
      return
  return
) this, document
