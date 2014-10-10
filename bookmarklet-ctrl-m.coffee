injectSrc = chrome.extension.getURL("inject.js")

setup = (injectSrc)->
  loadUp = ->
    ((s) ->
      s.id = "coffeeconsoleinject"
      s.src = injectSrc
      document.body.appendChild s
      return
    ) document.createElement("script")

  h = (e)->
    # Remap Ctrl-M
    if (e.keyCode == 77 && (navigator.platform.match("Mac") then e.metaKey else e.ctrlKey))
      e.preventDefault();
      loadUp()

  document.addEventListener("keydown", h, false)

s = document.createElement "SCRIPT"
setup = setup.toString()
setup = "(" + setup + ")(" + JSON.stringify(injectSrc) + ")"
s.innerHTML = setup
document.body.appendChild(s)
