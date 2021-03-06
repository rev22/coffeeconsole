code =
  ''''
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
      doc.write DOCUMENT
      doc.close()
      iframe.contentWindow.onload = ->
        @document.getElementById("exec").focus()
        return
    return
  ) this, document
#
d =
  ''''
  "<!DOCTYPE html><html id=coffeeconsole style=height:100%><meta charset=utf-8><title>Coffeeconsole!</title><meta id=meta name=viewport content=\"width=device-width,user-scalable=no,initial-scale=1\"><link rel=icon href=favicon.png type=image/png><link rel=apple-touch-icon href=favicon.png><meta name=apple-mobile-web-app-capable content=yes><meta name=apple-mobile-web-app-status-bar-style content=black><link rel=stylesheet href=\"#{baseURL}/console.css\"><body style=height:100%;margin:0;overflow:hidden><div id=console tabindex=0 style=height:100%;display:table;width:100%><form><textarea autofocus id=exec spellcheck autocapitalize=off rows=1 autocorrect=off></textarea></form><div style=position:relative;height:100%;overflow:hidden><div style=position:relative;width:100%;height:100%><div style=position:absolute;top:0;right:0;left:0;bottom:0;overflow:auto><div id=console><ul id=output></ul></div></div></div></div><div id=footer><a href=http://github.com/rev22/coffeeconsole>Fork Coffeeconsole on Github</a></div></div><script src=\"#{baseURL}/prettify.js\"></script><script src=\"#{baseURL}/EventSource.js\"></script><script src=\"#{baseURL}/coffee-script.js\"></script><script src=\"#{baseURL}/console.js\"></script>"
#
fs = require 'fs'

if fs.existsSync "index.html"
  d = fs.readFileSync "index.html"
  d = d.toString()
  d = JSON.stringify(d)
  d = d.replace /(src|href)=\\\"([^\"]*)\\\"/g, (m, a, b)->
    "#{a}=\\\"#{
      '#{baseURL}/' + b
    }\\\""

# fs.existsSync "" then

# document 

console.log code.replace "DOCUMENT", d
