((window) ->
  baseURL = undefined
  ccCache = undefined
  ccPosition = undefined
  exec = undefined
  form = undefined
  output = undefined
  cursor = undefined
  injected = undefined
  sandboxframe = undefined
  sandbox = undefined
  fakeConsole = undefined
  history = undefined
  liveHistory = undefined
  pos = undefined
  libraries = undefined
  body = undefined
  logAfter = undefined
  historySupported = undefined
  sse = undefined
  lastCmd = undefined
  remoteId = undefined
  codeCompleteTimer = undefined
  keypressTimer = undefined
  commands = undefined
  fakeInput = undefined
  iOSMobile = undefined
  enableCC = undefined
  modifierkeys = undefined
  fakeInputFocused = undefined
  dblTapTimer = undefined
  taps = undefined
  e = undefined
  sortci = (a, b) ->
    (if a.toLowerCase() < b.toLowerCase() then -1 else 1)
  
  # custom because I want to be able to introspect native browser objects *and* functions
  stringify = (o, simple, visited) ->
    do([e] = [ ])=>
      json = undefined
      i = undefined
      vi = undefined
      type = undefined
      parts = undefined
      names = undefined
      circular = undefined
      json = ""
      i = undefined
      vi = undefined
      type = ""
      parts = []
      names = []
      circular = false
      visited = visited or []
      try
        type = ({}).toString.call(o)
      catch e # only happens when typeof is protected (...randomly)
        type = "[object Object]"
      
      # check for circular references
      vi = 0
      while vi < visited.length
        if o is visited[vi]
          circular = true
          break
        vi++
      if circular
        json = "[circular]"
      else if type is "[object String]"
        json = "\"" + o.replace(/\"/g, "\\\"") + "\""
      else if type is "[object Array]"
        visited.push o
        json = "["
        i = 0
        while i < o.length
          parts.push stringify(o[i], simple, visited)
          i++
        json += parts.join(", ") + "]"
        json
      else if type is "[object Object]"
        visited.push o
        json = "{"
        for i of o
          names.push i
        names.sort sortci
        i = 0
        while i < names.length
          parts.push stringify(names[i], `undefined`, visited) + ": " + stringify(o[names[i]], simple, visited)
          i++
        json += parts.join(", ") + "}"
      else if type is "[object Number]"
        json = o + ""
      else if type is "[object Boolean]"
        json = (if o then "true" else "false")
      else if type is "[object Function]"
        json = o.toString()
      else if o is null
        json = "null"
      else if o is `undefined`
        json = "undefined"
      else unless simple?
        visited.push o
        json = type + "{\n"
        for i of o
          names.push i
        names.sort sortci
        i = 0
        while i < names.length
          try
            parts.push names[i] + ": " + stringify(o[names[i]], true, visited) # safety from max stack
          catch e
            if e.name is "NS_ERROR_NOT_IMPLEMENTED" then
          i++
        
        # do nothing - not sure it's useful to show this error when the variable is protected
        # parts.push(names[i] + ': NS_ERROR_NOT_IMPLEMENTED');
        json += parts.join(",\n") + "\n}"
      else
        try
          json = o + "" # should look like an object
        catch e
      json
  cleanse = (s) ->
    (s or "").replace /[<&]/g, (m) ->
      {
        "&": "&amp;"
        "<": "&lt;"
      }[m]

  run = (cmd) ->
    rawoutput = undefined
    className = undefined
    internalCmd = undefined
    rawoutput = null
    className = "response"
    internalCmd = internalCommand(cmd)
    if internalCmd
      [
        "info"
        internalCmd
      ]
    else if remoteId isnt null
      
      # send the remote event
      xhr = new XMLHttpRequest()
      params = "data=" + encodeURIComponent(cmd)
      xhr.open "POST", "/remote/" + remoteId + "/run", true
      xhr.setRequestHeader "Content-Type", "application/x-www-form-urlencoded"
      xhr.send params
      setCursorTo ""
      [
        "info"
        "sent remote command"
      ]
    else
      try
        if "CoffeeScript" of window
          cmd = window.CoffeeScript.compile(cmd,
            bare: true
          )
        else if "CoffeeScript" of sandboxframe.contentWindow
          
          # Maybe this should be removed or made optional 
          cmd = sandboxframe.contentWindow.CoffeeScript.compile(cmd,
            bare: true
          )
        rawoutput = sandboxframe.contentWindow.eval(cmd)
      catch e
        rawoutput = e.message
        className = "error"
      [
        className
        cleanse(stringify(rawoutput))
      ]
  post = (cmd, blind, response) -> # passed in when echoing from remote console
    do([e] = [ ])=>
      el = undefined
      li = undefined
      span = undefined
      parent = undefined
      cmd = trim(cmd)
      if blind is `undefined`
        history.push cmd
        setHistory history
        window.history.pushState cmd, cmd, "?" + encodeURIComponent(cmd)  if historySupported
      echo cmd  if not remoteId or response
      
      # order so it appears at the top
      el = document.createElement("div")
      li = document.createElement("li")
      span = document.createElement("span")
      parent = output.parentNode
      response = response or run(cmd)
      if response isnt `undefined`
        el.className = "response"
        span.innerHTML = response[1]
        prettyPrint [span]  unless response[0] is "info"
        el.appendChild span
        li.className = response[0]
        li.innerHTML = "<span class=\"gutter\"></span>"
        li.appendChild el
        appendLog li
        output.parentNode.scrollTop = 0
        unless body.className
          exec.value = ""
          if enableCC
            try
              document.getElementsByTagName("a")[0].focus()
              cursor.focus()
              document.execCommand "selectAll", false, null
              document.execCommand "delete", false, null
            catch e
      pos = history.length
      return
  log = (msg, className) ->
    li = undefined
    div = undefined
    li = document.createElement("li")
    div = document.createElement("div")
    div.innerHTML = msg
    prettyPrint [div]
    li.className = className or "log"
    li.innerHTML = "<span class=\"gutter\"></span>"
    li.appendChild div
    appendLog li
    return
  echo = (cmd) ->
    li = undefined
    lis = undefined
    len = undefined
    i = undefined
    li = document.createElement("li")
    li.className = "echo"
    li.innerHTML = "<span class=\"gutter\"></span><div>" + cleanse(cmd) + "<a href=\"" + baseURL + "/index.html?" + encodeURIComponent(cmd) + "\" class=\"permalink\" title=\"permalink\"></a></div>"
    logAfter = null
    if output.querySelector
      logAfter = output.querySelector("li.echo") or null
    else
      lis = document.getElementsByTagName("li")
      len = lis.length
      i = undefined
      i = 0
      while i < len
        if lis[i].className.indexOf("echo") isnt -1
          logAfter = lis[i]
          break
        i++
    
    # logAfter = output.querySelector('li.echo') || null;
    appendLog li, true
    return
  info = (cmd) ->
    li = undefined
    li = document.createElement("li")
    li.className = "info"
    li.innerHTML = "<span class=\"gutter\"></span><div>" + cleanse(cmd) + "</div>"
    
    # logAfter = output.querySelector('li.echo') || null;
    # appendLog(li, true);
    appendLog li
    return
  appendLog = (el, echo) ->
    if echo
      unless output.firstChild
        output.appendChild el
      else
        output.insertBefore el, output.firstChild
    else
      
      # if (!output.lastChild) {
      #   output.appendChild(el);
      #   // console.log('ok');
      # } else {
      # console.log(output.lastChild.nextSibling);
      output.insertBefore el, (if logAfter then logAfter else output.lastChild.nextSibling) #  ? output.lastChild.nextSibling : output.firstChild
    return
  # }
  changeView = (event) ->
    do([e] = [ ])=>
      which = undefined
      return  if false and enableCC
      which = event.which or event.keyCode
      if which is 38 and event.shiftKey is true
        body.className = ""
        cursor.focus()
        try
          localStorage.large = 0
        catch e

        false
      else if which is 40 and event.shiftKey is true
        body.className = "large"
        try
          localStorage.large = 1
        catch e

        cursor.focus()
        false
  internalCommand = (cmd) ->
    parts = undefined
    c = undefined
    parts = []
    c = undefined
    if cmd.substr(0, 1) is ":"
      parts = cmd.substr(1).split(" ")
      c = parts.shift()
      (commands[c] or noop).apply this, parts
  noop = ->
  showhelp = ->
    do([commands] = [ ])=>
      commands = [
        ":load &lt;url&gt; - to inject new DOM"
        ":load &lt;script_url&gt; - to inject external library"
        "      load also supports following shortcuts: <br />      jquery, underscore, prototype, mootools, dojo, rightjs, coffeescript, yui.<br />      eg. :load jquery"
        ":listen [id] - to start <a href=\"/remote-debugging.html\">remote debugging</a> session"
        ":clear - to clear the history (accessed using cursor keys)"
        ":history - list current session history"
        ":about"
        ""
        "Directions to <a href=\"" + baseURL + "/inject.html\">inject</a> CoffeeConsole in to any page (useful for mobile debugging)"
      ]
      commands.push ":close - to hide the console"  if injected
      
      # commands = commands.concat([
      #   'up/down - cycle history',
      #   'shift+up - single line command',
      #   'shift+down - multiline command', 
      #   'shift+enter - to run command in multiline mode'
      # ]);
      commands.join "\n"
  load = (url) ->
    if navigator.onLine
      if arguments.length > 1 or libraries[url] or url.indexOf(".js") isnt -1
        loadScript.apply this, arguments
      else
        loadDOM url
    else
      "You need to be online to use :load"
  loadScript = ->
    doc = undefined
    doc = sandboxframe.contentDocument or sandboxframe.contentWindow.document
    i = 0

    while i < arguments.length
      ((url) ->
        script = document.createElement("script")
        script.src = url
        script.onload = ->
          info "Loaded " + url, "http://" + window.location.hostname
          info "Now you can type CoffeeScript instead of plain old JS!"  if url is libraries.coffeescript
          return

        script.onerror = ->
          log "Failed to load " + url, "error"
          return

        doc.body.appendChild script
        return
      ) libraries[arguments[i]] or arguments[i]
      i++
    "Loading script..."
  loadDOM = (url) ->
    doc = undefined
    script = undefined
    cb = undefined
    doc = sandboxframe.contentWindow.document
    script = document.createElement("script")
    cb = "loadDOM" + +new Date
    script.src = "http://query.yahooapis.com/v1/public/yql?q=select%20*%20from%20html%20where%20url%3D%22" + encodeURIComponent(url) + "%22&format=xml&callback=" + cb
    window[cb] = (yql) ->
      do([e] = [ ])=>
        html = undefined
        if yql.results.length
          html = yql.results[0].replace(/type=\"text\/javascript\"/gi, "type=\"x\"").replace(/<body.*?>/, "").replace(/<\/body>/, "")
          doc.body.innerHTML = html
          info "DOM load complete"
        else
          log "Failed to load DOM", "error"
        try
          window[cb] = null
          delete window[cb]
        catch e

        return

    document.body.appendChild script
    "Loading url into DOM..."
  checkTab = (evt) ->
    t = undefined
    ss = undefined
    se = undefined
    tab = undefined
    pre = undefined
    sel = undefined
    post = undefined
    t = evt.target
    ss = t.selectionStart
    se = t.selectionEnd
    tab = "  "
    
    # Tab key - insert tab expansion
    if evt.keyCode is 9
      evt.preventDefault()
      
      # Special case of multi line selection
      if ss isnt se and t.value.slice(ss, se).indexOf("\n") isnt -1
        
        # In case selection was not of entire lines (e.g. selection begins in the middle of a line)
        # we ought to tab at the beginning as well as at the start of every following line.
        pre = t.value.slice(0, ss)
        sel = t.value.slice(ss, se).replace(/\n/g, "\n" + tab)
        post = t.value.slice(se, t.value.length)
        t.value = pre.concat(tab).concat(sel).concat(post)
        t.selectionStart = ss + tab.length
        t.selectionEnd = se + tab.length
      
      # "Normal" case (no selection or selection on one line only)
      else
        t.value = t.value.slice(0, ss).concat(tab).concat(t.value.slice(ss, t.value.length))
        if ss is se
          t.selectionStart = t.selectionEnd = ss + tab.length
        else
          t.selectionStart = ss + tab.length
          t.selectionEnd = se + tab.length
    
    # Backspace key - delete preceding tab expansion, if exists
    else if evt.keyCode is 8 and t.value.slice(ss - 4, ss) is tab
      evt.preventDefault()
      t.value = t.value.slice(0, ss - 4).concat(t.value.slice(ss, t.value.length))
      t.selectionStart = t.selectionEnd = ss - tab.length
    
    # Delete key - delete following tab expansion, if exists
    else if evt.keyCode is 46 and t.value.slice(se, se + 4) is tab
      evt.preventDefault()
      t.value = t.value.slice(0, ss).concat(t.value.slice(ss + 4, t.value.length))
      t.selectionStart = t.selectionEnd = ss
    
    # Left/right arrow keys - move across the tab in one go
    else if evt.keyCode is 37 and t.value.slice(ss - 4, ss) is tab
      evt.preventDefault()
      t.selectionStart = t.selectionEnd = ss - 4
    else if evt.keyCode is 39 and t.value.slice(ss, ss + 4) is tab
      evt.preventDefault()
      t.selectionStart = t.selectionEnd = ss + 4
    return
  trim = (s) ->
    (s or "").replace /^\s+|\s+$/g, ""
  getProps = (cmd, filter) ->
    do([e] = [ ])=>
      surpress = undefined
      props = undefined
      surpress = {}
      props = []
      unless ccCache[cmd]
        try
          
          # surpress alert boxes because they'll actually do something when we're looking
          # up properties inside of the command we're running
          surpress.alert = sandboxframe.contentWindow.alert
          sandboxframe.contentWindow.alert = ->

          
          # loop through all of the properties available on the command (that's evaled)
          ccCache[cmd] = sandboxframe.contentWindow.eval("console.props(" + cmd + ")").sort()
          
          # return alert back to it's former self
          delete sandboxframe.contentWindow.alert
        catch e
          ccCache[cmd] = []
        
        # if the return value is undefined, then it means there's no props, so we'll 
        # empty the code completion
        ccOptions[cmd] = []  if ccCache[cmd][0] is "undefined"
        ccPosition = 0
        props = ccCache[cmd]
      else if filter
        
        # console.log('>>' + filter, cmd);
        i = 0
        p = undefined

        while (i < ccCache[cmd].length; p = ccCache[cmd][i])
          props.push p.substr(filter.length, p.length)  unless p is filter  if p.indexOf(filter) is 0
          i++
      else
        props = ccCache[cmd]
      props
  codeComplete = (event) ->
    cmd = undefined
    parts = undefined
    which = undefined
    cc = undefined
    props = undefined
    cmd = cursor.textContent.split(/[;\s]+/g).pop()
    parts = cmd.split(".")
    which = whichKey(event)
    cc = undefined
    props = []
    if cmd
      
      # get the command without the dot to allow us to introspect
      if cmd.substr(-1) is "."
        
        # get the command without the '.' so we can eval it and lookup the properties
        cmd = cmd.substr(0, cmd.length - 1)
        
        # returns an array of all the properties from the command
        props = getProps(cmd)
      else
        props = getProps(parts.slice(0, parts.length - 1).join(".") or "window", parts[parts.length - 1])
      if props.length
        if which is 9 # tabbing cycles through the code completion
          # however if there's only one selection, it'll auto complete
          if props.length is 1
            ccPosition = false
          else
            if event.shiftKey
              
              # backwards
              ccPosition = (if ccPosition is 0 then props.length - 1 else ccPosition - 1)
            else
              ccPosition = (if ccPosition is props.length - 1 then 0 else ccPosition + 1)
        else
          ccPosition = 0
        if ccPosition is false
          completeCode()
        else
          
          # position the code completion next to the cursor
          unless cursor.nextSibling
            cc = document.createElement("span")
            cc.className = "suggest"
            exec.appendChild cc
          cursor.nextSibling.innerHTML = props[ccPosition]
          exec.value = exec.textContent
        return false  if which is 9
      else
        ccPosition = false
    else
      ccPosition = false
    removeSuggestion()  if ccPosition is false and cursor.nextSibling
    exec.value = exec.textContent
    return
  removeSuggestion = ->
    exec.setAttribute "rows", 1  unless enableCC
    cursor.parentNode.removeChild cursor.nextSibling  if enableCC and cursor.nextSibling
    return
  showHistory = ->
    h = undefined
    h = getHistory()
    h.shift()
    h.join "\n"
  getHistory = ->
    do([history,e] = [ ])=>
      history = [""]
      return history  if typeof JSON is "undefined"
      try
        
        # because FF with cookies disabled goes nuts, and because sometimes WebKit goes nuts too...
        history = JSON.parse(sessionStorage.getItem("history") or "[\"\"]")
      catch e

      history
  
  # I should do this onunload...but I'm being lazy and hacky right now
  setHistory = (history) ->
    do([e] = [ ])=>
      return  if typeof JSON is "undefined"
      try
        
        # because FF with cookies disabled goes nuts, and because sometimes WebKit goes nuts too...
        sessionStorage.setItem "history", JSON.stringify(history)
      catch e

      return
  about = ->
    "Built by <a target=\"_new\" href=\"http://twitter.com/rem\">@rem</a>"
  
  # loadjs: loadScript, 
  
  # place script request for new listen ID and start SSE
  # fiddle to remove the [] around the repsonse
  
  # I hate that I'm browser sniffing, but there's issues with Firefox and execCommand so code completion won't work
  
  # FIXME Remy, seriously, don't sniff the agent like this, it'll bite you in the arse.
  
  # stupid jumping through hoops if Firebug is open, since overwriting console throws error
  
  # tweaks to interface to allow focus
  # if (!('autofocus' in document.createElement('input'))) exec.focus();
  whichKey = (event) ->
    keys = undefined
    keys =
      38: 1
      40: 1
      Up: 38
      Down: 40
      Enter: 10
      "U+0009": 9
      "U+0008": 8
      "U+0190": 190
      Right: 39
      
      # these two are ignored
      "U+0028": 57
      "U+0026": 55

    keys[event.keyIdentifier] or event.which or event.keyCode
  setCursorTo = (str) ->
    rows = undefined
    str = (if enableCC then cleanse(str) else str)
    exec.value = str
    if enableCC
      document.execCommand "selectAll", false, null
      document.execCommand "delete", false, null
      document.execCommand "insertHTML", false, str
    else
      rows = str.match(/\n/g)
      exec.setAttribute "rows", (if rows isnt null then rows.length + 1 else 1)
    cursor.focus()
    window.scrollTo 0, 0
    return
  
  # disabled for now
  
  # this causes the field to lose focus - I'll leave it here for a while, see how we get on.
  # what I need to do is rip out the contenteditable and replace it with something entirely different
  
  # setCursorTo(cursor.innerText);
  findNode = (list, node) ->
    do([pos] = [ ])=>
      pos = 0
      i = 0

      while i < list.length
        return pos  if list[i] is node
        pos += list[i].nodeValue.length
        i++
      -1
  # history cycle
  # cycle up
  #history.length - 1;
  # down
  #0;
  # enter (what about the other one)
  
  # manually expand the textarea when we don't have code completion turned on
  # complete code
  # try code completion
  # cycles available completions
  
  # window.scrollTo(0,0);
  completeCode = (focus) ->
    tmp = undefined
    l = undefined
    range = undefined
    selection = undefined
    tmp = exec.textContent
    l = tmp.length
    removeSuggestion()
    cursor.innerHTML = tmp
    ccPosition = false
    
    # daft hack to move the focus elsewhere, then back on to the cursor to
    # move the cursor to the end of the text.
    document.getElementsByTagName("a")[0].focus()
    cursor.focus()
    range = undefined
    selection = undefined
    if document.createRange #Firefox, Chrome, Opera, Safari, IE 9+
      range = document.createRange() #Create a range (a range is a like the selection but invisible)
      range.selectNodeContents cursor #Select the entire contents of the element with the range
      range.collapse false #collapse the range to the end point. false means collapse to end rather than the start
      selection = window.getSelection() #get the selection object (allows you to change selection)
      selection.removeAllRanges() #remove any selections already made
      selection.addRange range #make the range you have just created the visible selection
    else if document.selection #IE 8 and lower
      range = document.body.createTextRange() #Create a range (a range is a like the selection but invisible)
      range.moveToElementText cursor #Select the entire contents of the element with the range
      range.collapse false #collapse the range to the end point. false means collapse to end rather than the start
      range.select() #Select the range (make it the visible selection
    return
  baseURL = (if window.top.COFFEECONSOLE then window.top.COFFEECONSOLE.baseURL else window.location.href.split(/[#?]/)[0].replace(/\/[^\/]*$/, ""))
  window.info = info
  ccCache = {}
  ccPosition = false
  window._console =
    log: ->
      l = undefined
      i = undefined
      l = arguments.length
      i = 0
      while i < l
        log stringify(arguments[i], true)
        i++
      return

    dir: ->
      l = undefined
      i = undefined
      l = arguments.length
      i = 0
      while i < l
        log stringify(arguments[i])
        i++
      return

    props: (obj) ->
      do([e] = [ ])=>
        props = undefined
        realObj = undefined
        props = []
        realObj = undefined
        try
          for p of obj
            props.push p
        catch e

        props

  (if document.addEventListener then window.addEventListener("message", (event) ->
    post event.data
    return
  , false) else window.attachEvent("onmessage", ->
    post window.event.data
    return
  ))
  exec = document.getElementById("exec")
  form = exec.form or {}
  output = document.getElementById("output")
  cursor = document.getElementById("exec")
  injected = typeof window.top["COFFEECONSOLE"] isnt "undefined"
  sandboxframe = (if injected then window.top["COFFEECONSOLE"] else document.createElement("iframe"))
  sandbox = null
  fakeConsole = "window.top._console"
  history = getHistory()
  liveHistory = (window.history.pushState isnt `undefined`)
  pos = 0
  libraries =
    jquery: "http://ajax.googleapis.com/ajax/libs/jquery/1/jquery.min.js"
    prototype: "http://ajax.googleapis.com/ajax/libs/prototype/1/prototype.js"
    dojo: "http://ajax.googleapis.com/ajax/libs/dojo/1/dojo/dojo.xd.js"
    mootools: "http://ajax.googleapis.com/ajax/libs/mootools/1/mootools-yui-compressed.js"
    underscore: "http://documentcloud.github.com/underscore/underscore-min.js"
    rightjs: "http://rightjs.org/hotlink/right.js"
    yui: "http://yui.yahooapis.com/3.2.0/build/yui/yui-min.js"

  body = document.getElementsByTagName("body")[0]
  logAfter = null
  historySupported = !!(window.history and window.history.pushState)
  sse = null
  lastCmd = null
  remoteId = null
  codeCompleteTimer = null
  keypressTimer = null
  commands =
    help: showhelp
    about: about
    load: load
    history: showHistory
    clear: ->
      setTimeout (->
        output.innerHTML = ""
        return
      ), 10
      "clearing..."

    close: ->
      if injected
        sandboxframe.console.style.display = "none"
        "hidden"
      else
        "noop"

    listen: (id) ->
      script = document.createElement("script")
      callback = "_cb" + +new Date
      script.src = "/remote/" + (id or "") + "?callback=" + callback
      window[callback] = (id) ->
        remoteId = id
        sse.close()  if sse isnt null
        sse = new EventSource("/remote/" + id + "/log")
        sse.onopen = ->
          remoteId = id
          info "Connected to \"" + id + "\"\n\n<script id=\"coffeeconsoleremote\" src=\"" + baseURL + "/remote.js?" + id + "\"></script>"
          return

        sse.onmessage = (event) ->
          data = JSON.parse(event.data)
          if data.type and data.type is "error"
            post data.cmd, true, [
              "error"
              data.response
            ]
          else if data.type and data.type is "info"
            info data.response
          else
            data.response = data.response.substr(1, data.response.length - 2)  unless data.cmd is "remote console.log"
            echo data.cmd
            log data.response, "response"
          return

        sse.onclose = ->
          info "Remote connection closed"
          remoteId = null
          return

        try
          body.removeChild script
          delete window[callback]
        catch e

        return

      body.appendChild script
      "Creating connection..."

  fakeInput = null
  iOSMobile = navigator.userAgent.indexOf("AppleWebKit") isnt -1 and navigator.userAgent.indexOf("Mobile") isnt -1
  enableCC = navigator.userAgent.indexOf("AppleWebKit") isnt -1 and navigator.userAgent.indexOf("Mobile") is -1 or navigator.userAgent.indexOf("OS 5_") isnt -1
  if enableCC
    exec.parentNode.innerHTML = "<div autofocus id=\"exec\" autocapitalize=\"off\" spellcheck=\"false\"><span id=\"cursor\" spellcheck=\"false\" autocapitalize=\"off\" autocorrect=\"off\"" + ((if iOSMobile then "" else " contenteditable")) + "></span></div>"
    exec = document.getElementById("exec")
    cursor = document.getElementById("cursor")
  if enableCC and iOSMobile
    fakeInput = document.createElement("input")
    fakeInput.className = "fakeInput"
    fakeInput.setAttribute "spellcheck", "false"
    fakeInput.setAttribute "autocorrect", "off"
    fakeInput.setAttribute "autocapitalize", "off"
    exec.parentNode.appendChild fakeInput
  unless injected
    body.appendChild sandboxframe
    sandboxframe.setAttribute "id", "sandbox"
  sandbox = sandboxframe.contentDocument or sandboxframe.contentWindow.document
  unless injected
    sandbox.open()
    sandbox.write "<script>(function () { var fakeConsole = " + fakeConsole + "; if (console != undefined) { for (var k in fakeConsole) { console[k] = fakeConsole[k]; } } else { console = fakeConsole; } })();</script>"
    sandbox.close()
  cursor.focus()
  output.parentNode.tabIndex = 0
  output.ontouchstart = output.onclick = (event) ->
    command = undefined
    event = event or window.event
    if event.target.nodeName is "A" and event.target.className is "permalink"
      command = decodeURIComponent(event.target.search.substr(1))
      setCursorTo command
      window.history.pushState command, command, event.target.href  if liveHistory
      false

  exec.ontouchstart = ->
    window.scrollTo 0, 0
    return

  exec.onkeyup = (event) ->
    which = undefined
    which = whichKey(event)
    if enableCC and which isnt 9 and which isnt 16
      clearTimeout codeCompleteTimer
      codeCompleteTimer = setTimeout(->
        codeComplete event
        return
      , 200)
    return

  if enableCC
    cursor.__onpaste = (event) ->
      setTimeout (->
        cursor.innerHTML = cursor.innerText
        return
      ), 10
      return
  modifierkeys =
    0: 1
    16: 1

  exec.onkeydown = (event) ->
    keys = undefined
    wide = undefined
    which = undefined
    event = event or window.event
    keys =
      38: 1
      40: 1

    wide = body.className is "large"
    which = whichKey(event)
    which = which.replace(/\/U\+/, "\\u")  if typeof which is "string"
    if keys[which]
      if event.shiftKey
        changeView event
      else unless wide
        if enableCC and window.getSelection
          window.selObj = window.getSelection()
          selRange = selObj.getRangeAt(0)
          cursorPos = findNode(selObj.anchorNode.parentNode.childNodes, selObj.anchorNode) + selObj.anchorOffset
          value = exec.value
          firstnl = value.indexOf("\n")
          lastnl = value.lastIndexOf("\n")
          if firstnl isnt -1
            if which is 38 and cursorPos > firstnl
              return
            else return  if which is 40 and cursorPos < lastnl
        if which is 38
          pos--
          pos = 0  if pos < 0
        else if which is 40
          pos++
          pos = history.length  if pos >= history.length
        if history[pos]? and history[pos] isnt ""
          removeSuggestion()
          setCursorTo history[pos]
          return false
        else if pos is history.length
          removeSuggestion()
          setCursorTo ""
          return false
    else if (which is 13 or which is 10) and event.shiftKey is false
      removeSuggestion()
      if event.shiftKey is true or event.metaKey or event.ctrlKey or not wide
        command = exec.textContent or exec.value
        post command  if command.length
        return false
    else if (which is 13 or which is 10) and not enableCC and event.shiftKey is true
      rows = exec.value.match(/\n/g)
      rows = (if rows? then rows.length + 2 else 2)
      exec.setAttribute "rows", rows
    else if which is 9 and wide
      checkTab event
    else if event.shiftKey and event.metaKey and which is 8
      output.innerHTML = ""
    else if (which is 39 or which is 35) and ccPosition isnt false
      completeCode()
    else if event.ctrlKey and which is 76
      output.innerHTML = ""
    else if enableCC
      if ccPosition isnt false and which is 9
        codeComplete event
        return false
      else removeSuggestion()  if ccPosition isnt false and cursor.nextSibling and not modifierkeys[which]
    return

  if enableCC and iOSMobile
    fakeInput.onkeydown = (event) ->
      which = undefined
      removeSuggestion()
      which = whichKey(event)
      if which is 13 or which is 10
        post @value
        @value = ""
        cursor.innerHTML = ""
        false

    fakeInput.onkeyup = (event) ->
      which = undefined
      cursor.innerHTML = cleanse(@value)
      which = whichKey(event)
      if enableCC and which isnt 9 and which isnt 16
        clearTimeout codeCompleteTimer
        codeCompleteTimer = setTimeout(->
          codeComplete event
          return
        , 200)
      return

    fakeInputFocused = false
    dblTapTimer = null
    taps = 0
    form.addEventListener "touchstart", (event) ->
      if ccPosition isnt false
        event.preventDefault()
        clearTimeout dblTapTimer
        taps++
        if taps is 2
          completeCode()
          fakeInput.value = cursor.textContent
          removeSuggestion()
          fakeInput.focus()
        else
          dblTapTimer = setTimeout(->
            taps = 0
            codeComplete which: 9
            return
          , 200)
      false

  form.onsubmit = (event) ->
    event = event or window.event
    event.preventDefault and event.preventDefault()
    removeSuggestion()
    post exec.textContent or exec.value
    false

  document.onkeydown = (event) ->
    which = undefined
    event = event or window.event
    which = event.which or event.keyCode
    if event.shiftKey and event.metaKey and which is 8
      output.innerHTML = ""
      cursor.focus()
    # space
    else output.parentNode.scrollTop += 5 + output.parentNode.offsetHeight * ((if event.shiftKey then -1 else 1))  if event.target is output.parentNode and which is 32
    changeView event

  exec.onclick = ->
    cursor.focus()
    return

  if window.location.search
    post decodeURIComponent(window.location.search.substr(1))
  else
    post ":help", true
  window.onpopstate = (event) ->
    setCursorTo event.state or ""
    return

  setTimeout (->
    window.scrollTo 0, 1
    return
  ), 500
  setTimeout (->
    document.getElementById("footer").className = "hidden"
    return
  ), 5000
  getProps "window" # cache
  try
    document.body.className = "large"  unless not (localStorage.large * 1)
  catch e

  if document.addEventListener
    document.addEventListener "deviceready", (->
      cursor.focus()
      return
    ), false
  
  # if (iOSMobile) {
  #   document.getElementById('footer').style.display = 'none';
  #   alert('hidden');
  # }
  if injected
    (->
      x = window._console
      y = window.top.console
      k = undefined
      if y
        for k of x
          y[k] = x[k]
      else
        window.top.console = x
      return
    )()
  return
) this
