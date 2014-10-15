(function (window) {
  var about, appendLog, baseURL, body, ccCache, ccPosition, changeView, checkTab, cleanse, codeComplete, codeCompleteTimer, commands, completeCode, cursor, dblTapTimer, e, echo, enableCC, exec, fakeConsole, fakeInput, fakeInputFocused, findNode, form, getHistory, getProps, history, historySupported, iOSMobile, info, injected, internalCommand, keypressTimer, lastCmd, libraries, liveHistory, load, loadDOM, loadScript, log, logAfter, modifierkeys, noop, output, pos, post, remoteId, removeSuggestion, run, sandbox, sandboxframe, setCursorTo, setHistory, showHistory, showhelp, sortci, sse, stringify, taps, trim, whichKey;
  baseURL = void 0;
  ccCache = void 0;
  ccPosition = void 0;
  exec = void 0;
  form = void 0;
  output = void 0;
  cursor = void 0;
  injected = void 0;
  sandboxframe = void 0;
  sandbox = void 0;
  fakeConsole = void 0;
  history = void 0;
  liveHistory = void 0;
  pos = void 0;
  libraries = void 0;
  body = void 0;
  logAfter = void 0;
  historySupported = void 0;
  sse = void 0;
  lastCmd = void 0;
  remoteId = void 0;
  codeCompleteTimer = void 0;
  keypressTimer = void 0;
  commands = void 0;
  fakeInput = void 0;
  iOSMobile = void 0;
  enableCC = void 0;
  modifierkeys = void 0;
  fakeInputFocused = void 0;
  dblTapTimer = void 0;
  taps = void 0;
  e = void 0;
  sortci = function(a, b) {
    return (a.toLowerCase() < b.toLowerCase() ? -1 : 1);
  };
  stringify = function(o, simple, visited) {
    return (function(_this) {
      return function(_arg) {
        var circular, e, i, json, names, parts, type, vi;
        e = _arg[0];
        json = void 0;
        i = void 0;
        vi = void 0;
        type = void 0;
        parts = void 0;
        names = void 0;
        circular = void 0;
        json = "";
        i = void 0;
        vi = void 0;
        type = "";
        parts = [];
        names = [];
        circular = false;
        visited = visited || [];
        try {
          type = {}.toString.call(o);
        } catch (_error) {
          e = _error;
          type = "[object Object]";
        }
        vi = 0;
        while (vi < visited.length) {
          if (o === visited[vi]) {
            circular = true;
            break;
          }
          vi++;
        }
        if (circular) {
          json = "[circular]";
        } else if (type === "[object String]") {
          json = "\"" + o.replace(/\"/g, "\\\"") + "\"";
        } else if (type === "[object Array]") {
          visited.push(o);
          json = "[";
          i = 0;
          while (i < o.length) {
            parts.push(stringify(o[i], simple, visited));
            i++;
          }
          json += parts.join(", ") + "]";
          json;
        } else if (type === "[object Object]") {
          visited.push(o);
          json = "{";
          for (i in o) {
            names.push(i);
          }
          names.sort(sortci);
          i = 0;
          while (i < names.length) {
            parts.push(stringify(names[i], undefined, visited) + ": " + stringify(o[names[i]], simple, visited));
            i++;
          }
          json += parts.join(", ") + "}";
        } else if (type === "[object Number]") {
          json = o + "";
        } else if (type === "[object Boolean]") {
          json = (o ? "true" : "false");
        } else if (type === "[object Function]") {
          json = o.toString();
        } else if (o === null) {
          json = "null";
        } else if (o === undefined) {
          json = "undefined";
        } else if (simple == null) {
          visited.push(o);
          json = type + "{\n";
          for (i in o) {
            names.push(i);
          }
          names.sort(sortci);
          i = 0;
          while (i < names.length) {
            try {
              parts.push(names[i] + ": " + stringify(o[names[i]], true, visited));
            } catch (_error) {
              e = _error;
              if (e.name === "NS_ERROR_NOT_IMPLEMENTED") {

              }
            }
            i++;
          }
          json += parts.join(",\n") + "\n}";
        } else {
          try {
            json = o + "";
          } catch (_error) {
            e = _error;
          }
        }
        return json;
      };
    })(this)([]);
  };

  cleanse = function(s) {
    return (s || "").replace(/[<&]/g, function(m) {
      return {
        "&": "&amp;",
        "<": "&lt;"
      }[m];
    });
  };
  run = function(cmd) {
    var className, internalCmd, params, rawoutput, xhr;
    rawoutput = void 0;
    className = void 0;
    internalCmd = void 0;
    rawoutput = null;
    className = "response";
    internalCmd = internalCommand(cmd);
    if (internalCmd) {
      return ["info", internalCmd];
    } else if (remoteId !== null) {
      xhr = new XMLHttpRequest();
      params = "data=" + encodeURIComponent(cmd);
      xhr.open("POST", "/remote/" + remoteId + "/run", true);
      xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
      xhr.send(params);
      setCursorTo("");
      return ["info", "sent remote command"];
    } else {
      try {
        if ("CoffeeScript" in window) {
          cmd = window.CoffeeScript.compile(cmd, {
            bare: true
          });
        } else if ("CoffeeScript" in sandboxframe.contentWindow) {
          cmd = sandboxframe.contentWindow.CoffeeScript.compile(cmd, {
            bare: true
          });
        }
        rawoutput = sandboxframe.contentWindow["eval"](cmd);
      } catch (_error) {
        e = _error;
        rawoutput = e.message;
        className = "error";
      }
      return [className, cleanse(stringify(rawoutput))];
    }
  };
  post = function(cmd, blind, response) {
    return (function(_this) {
      return function(_arg) {
        var e, el, li, parent, span;
        e = _arg[0];
        el = void 0;
        li = void 0;
        span = void 0;
        parent = void 0;
        cmd = trim(cmd);
        if (blind === undefined) {
          history.push(cmd);
          setHistory(history);
          if (historySupported) {
            window.history.pushState(cmd, cmd, "?" + encodeURIComponent(cmd));
          }
        }
        if (!remoteId || response) {
          echo(cmd);
        }
        el = document.createElement("div");
        li = document.createElement("li");
        span = document.createElement("span");
        parent = output.parentNode;
        response = response || run(cmd);
        if (response !== undefined) {
          el.className = "response";
          span.innerHTML = response[1];
          if (response[0] !== "info") {
            prettyPrint([span]);
          }
          el.appendChild(span);
          li.className = response[0];
          li.innerHTML = "<span class=\"gutter\"></span>";
          li.appendChild(el);
          appendLog(li);
          output.parentNode.scrollTop = 0;
          if (!body.className) {
            exec.value = "";
            if (enableCC) {
              try {
                document.getElementsByTagName("a")[0].focus();
                cursor.focus();
                document.execCommand("selectAll", false, null);
                document.execCommand("delete", false, null);
              } catch (_error) {
                e = _error;
              }
            }
          }
        }
        pos = history.length;
      };
    })(this)([]);
  };

  log = function(msg, className) {
    var div, li;
    li = void 0;
    div = void 0;
    li = document.createElement("li");
    div = document.createElement("div");
    div.innerHTML = msg;
    prettyPrint([div]);
    li.className = className || "log";
    li.innerHTML = "<span class=\"gutter\"></span>";
    li.appendChild(div);
    appendLog(li);
  };
  echo = function(cmd) {
    var i, len, li, lis;
    li = void 0;
    lis = void 0;
    len = void 0;
    i = void 0;
    li = document.createElement("li");
    li.className = "echo";
    li.innerHTML = "<span class=\"gutter\"></span><div>" + cleanse(cmd) + "<a href=\"" + baseURL + "/index.html?" + encodeURIComponent(cmd) + "\" class=\"permalink\" title=\"permalink\"></a></div>";
    logAfter = null;
    if (output.querySelector) {
      logAfter = output.querySelector("li.echo") || null;
    } else {
      lis = document.getElementsByTagName("li");
      len = lis.length;
      i = void 0;
      i = 0;
      while (i < len) {
        if (lis[i].className.indexOf("echo") !== -1) {
          logAfter = lis[i];
          break;
        }
        i++;
      }
    }
    appendLog(li, true);
  };
  info = function(cmd) {
    var li;
    li = void 0;
    li = document.createElement("li");
    li.className = "info";
    li.innerHTML = "<span class=\"gutter\"></span><div>" + cleanse(cmd) + "</div>";
    appendLog(li);
  };
  appendLog = function(el, echo) {
    if (echo) {
      if (!output.firstChild) {
        output.appendChild(el);
      } else {
        output.insertBefore(el, output.firstChild);
      }
    } else {
      output.insertBefore(el, (logAfter ? logAfter : output.lastChild.nextSibling));
    }
  };

  changeView = function(event) {
    return (function(_this) {
      return function(_arg) {
        var e, which;
        e = _arg[0];
        which = void 0;
        if (false && enableCC) {
          return;
        }
        which = event.which || event.keyCode;
        if (which === 38 && event.shiftKey === true) {
          body.className = "";
          cursor.focus();
          try {
            localStorage.large = 0;
          } catch (_error) {
            e = _error;
          }
          return false;
        } else if (which === 40 && event.shiftKey === true) {
          body.className = "large";
          try {
            localStorage.large = 1;
          } catch (_error) {
            e = _error;
          }
          cursor.focus();
          return false;
        }
      };
    })(this)([]);
  };
  internalCommand = function(cmd) {
    var c, parts;
    parts = void 0;
    c = void 0;
    parts = [];
    c = void 0;
    if (cmd.substr(0, 1) === ":") {
      parts = cmd.substr(1).split(" ");
      c = parts.shift();
      return (commands[c] || noop).apply(this, parts);
    }
  };
  noop = function() {};
  showhelp = function() {
    return (function(_this) {
      return function(_arg) {
        var commands;
        commands = _arg[0];
        commands = [":load &lt;url&gt; - to inject new DOM", ":load &lt;script_url&gt; - to inject external library", "      load also supports following shortcuts: <br />      jquery, underscore, prototype, mootools, dojo, rightjs, coffeescript, yui.<br />      eg. :load jquery", ":listen [id] - to start <a href=\"/remote-debugging.html\">remote debugging</a> session", ":clear - to clear the history (accessed using cursor keys)", ":history - list current session history", ":about", "", "Directions to <a href=\"" + baseURL + "/inject.html\">inject</a> CoffeeConsole in to any page (useful for mobile debugging)"];
        if (injected) {
          commands.push(":close - to hide the console");
        }
        return commands.join("\n");
      };
    })(this)([]);
  };
  load = function(url) {
    if (navigator.onLine) {
      if (arguments.length > 1 || libraries[url] || url.indexOf(".js") !== -1) {
        return loadScript.apply(this, arguments);
      } else {
        return loadDOM(url);
      }
    } else {
      return "You need to be online to use :load";
    }
  };
  loadScript = function() {
    var doc, i;
    doc = void 0;
    doc = sandboxframe.contentDocument || sandboxframe.contentWindow.document;
    i = 0;
    while (i < arguments.length) {
      (function(url) {
        var script;
        script = document.createElement("script");
        script.src = url;
        script.onload = function() {
          info("Loaded " + url, "http://" + window.location.hostname);
          if (url === libraries.coffeescript) {
            info("Now you can type CoffeeScript instead of plain old JS!");
          }
        };
        script.onerror = function() {
          log("Failed to load " + url, "error");
        };
        doc.body.appendChild(script);
      })(libraries[arguments[i]] || arguments[i]);
      i++;
    }
    return "Loading script...";
  };
  loadDOM = function(url) {
    var cb, doc, script;
    doc = void 0;
    script = void 0;
    cb = void 0;
    doc = sandboxframe.contentWindow.document;
    script = document.createElement("script");
    cb = "loadDOM" + +(new Date);
    script.src = "http://query.yahooapis.com/v1/public/yql?q=select%20*%20from%20html%20where%20url%3D%22" + encodeURIComponent(url) + "%22&format=xml&callback=" + cb;
    window[cb] = function(yql) {
      return (function(_this) {
        return function(_arg) {
          var e, html;
          e = _arg[0];
          html = void 0;
          if (yql.results.length) {
            html = yql.results[0].replace(/type=\"text\/javascript\"/gi, "type=\"x\"").replace(/<body.*?>/, "").replace(/<\/body>/, "");
            doc.body.innerHTML = html;
            info("DOM load complete");
          } else {
            log("Failed to load DOM", "error");
          }
          try {
            window[cb] = null;
            delete window[cb];
          } catch (_error) {
            e = _error;
          }
        };
      })(this)([]);
    };
    document.body.appendChild(script);
    return "Loading url into DOM...";
  };
  checkTab = function(evt) {
    var pre, se, sel, ss, t, tab;
    t = void 0;
    ss = void 0;
    se = void 0;
    tab = void 0;
    pre = void 0;
    sel = void 0;
    post = void 0;
    t = evt.target;
    ss = t.selectionStart;
    se = t.selectionEnd;
    tab = "  ";
    if (evt.keyCode === 9) {
      evt.preventDefault();
      if (ss !== se && t.value.slice(ss, se).indexOf("\n") !== -1) {
        pre = t.value.slice(0, ss);
        sel = t.value.slice(ss, se).replace(/\n/g, "\n" + tab);
        post = t.value.slice(se, t.value.length);
        t.value = pre.concat(tab).concat(sel).concat(post);
        t.selectionStart = ss + tab.length;
        t.selectionEnd = se + tab.length;
      } else {
        t.value = t.value.slice(0, ss).concat(tab).concat(t.value.slice(ss, t.value.length));
        if (ss === se) {
          t.selectionStart = t.selectionEnd = ss + tab.length;
        } else {
          t.selectionStart = ss + tab.length;
          t.selectionEnd = se + tab.length;
        }
      }
    } else if (evt.keyCode === 8 && t.value.slice(ss - 4, ss) === tab) {
      evt.preventDefault();
      t.value = t.value.slice(0, ss - 4).concat(t.value.slice(ss, t.value.length));
      t.selectionStart = t.selectionEnd = ss - tab.length;
    } else if (evt.keyCode === 46 && t.value.slice(se, se + 4) === tab) {
      evt.preventDefault();
      t.value = t.value.slice(0, ss).concat(t.value.slice(ss + 4, t.value.length));
      t.selectionStart = t.selectionEnd = ss;
    } else if (evt.keyCode === 37 && t.value.slice(ss - 4, ss) === tab) {
      evt.preventDefault();
      t.selectionStart = t.selectionEnd = ss - 4;
    } else if (evt.keyCode === 39 && t.value.slice(ss, ss + 4) === tab) {
      evt.preventDefault();
      t.selectionStart = t.selectionEnd = ss + 4;
    }
  };
  trim = function(s) {
    return (s || "").replace(/^\s+|\s+$/g, "");
  };
  getProps = function(cmd, filter) {
    return (function(_this) {
      return function(_arg) {
        var e, i, p, props, surpress;
        e = _arg[0];
        surpress = void 0;
        props = void 0;
        surpress = {};
        props = [];
        if (!ccCache[cmd]) {
          try {
            surpress.alert = sandboxframe.contentWindow.alert;
            sandboxframe.contentWindow.alert = function() {};
            ccCache[cmd] = sandboxframe.contentWindow["eval"]("console.props(" + cmd + ")").sort();
            delete sandboxframe.contentWindow.alert;
          } catch (_error) {
            e = _error;
            ccCache[cmd] = [];
          }
          if (ccCache[cmd][0] === "undefined") {
            ccOptions[cmd] = [];
          }
          ccPosition = 0;
          props = ccCache[cmd];
        } else if (filter) {
          i = 0;
          p = void 0;
          while ((i < ccCache[cmd].length, p = ccCache[cmd][i])) {
            if (p.indexOf(filter) === 0) {
              if (p !== filter) {
                props.push(p.substr(filter.length, p.length));
              }
            }
            i++;
          }
        } else {
          props = ccCache[cmd];
        }
        return props;
      };
    })(this)([]);
  };

  codeComplete = function(event) {
    var cc, cmd, parts, props, which;
    cmd = void 0;
    parts = void 0;
    which = void 0;
    cc = void 0;
    props = void 0;
    cmd = cursor.textContent.split(/[;\s]+/g).pop();
    parts = cmd.split(".");
    which = whichKey(event);
    cc = void 0;
    props = [];
    if (cmd) {
      if (cmd.substr(-1) === ".") {
        cmd = cmd.substr(0, cmd.length - 1);
        props = getProps(cmd);
      } else {
        props = getProps(parts.slice(0, parts.length - 1).join(".") || "window", parts[parts.length - 1]);
      }
      if (props.length) {
        if (which === 9) {
          if (props.length === 1) {
            ccPosition = false;
          } else {
            if (event.shiftKey) {
              ccPosition = (ccPosition === 0 ? props.length - 1 : ccPosition - 1);
            } else {
              ccPosition = (ccPosition === props.length - 1 ? 0 : ccPosition + 1);
            }
          }
        } else {
          ccPosition = 0;
        }
        if (ccPosition === false) {
          completeCode();
        } else {
          if (!cursor.nextSibling) {
            cc = document.createElement("span");
            cc.className = "suggest";
            exec.appendChild(cc);
          }
          cursor.nextSibling.innerHTML = props[ccPosition];
          exec.value = exec.textContent;
        }
        if (which === 9) {
          return false;
        }
      } else {
        ccPosition = false;
      }
    } else {
      ccPosition = false;
    }
    if (ccPosition === false && cursor.nextSibling) {
      removeSuggestion();
    }
    exec.value = exec.textContent;
  };

  removeSuggestion = function() {
    if (!enableCC) {
      exec.setAttribute("rows", 1);
    }
    if (enableCC && cursor.nextSibling) {
      cursor.parentNode.removeChild(cursor.nextSibling);
    }
  };



  showHistory = function() {
    var h;
    h = void 0;
    h = getHistory();
    h.shift();
    return h.join("\n");
  };
  getHistory = function() {
    return (function(_this) {
      return function(_arg) {
        var e, history;
        history = _arg[0], e = _arg[1];
        history = [""];
        if (typeof JSON === "undefined") {
          return history;
        }
        try {
          history = JSON.parse(sessionStorage.getItem("history") || "[\"\"]");
        } catch (_error) {
          e = _error;
        }
        return history;
      };
    })(this)([]);
  };
  setHistory = function(history) {
    return (function(_this) {
      return function(_arg) {
        var e;
        e = _arg[0];
        if (typeof JSON === "undefined") {
          return;
        }
        try {
          sessionStorage.setItem("history", JSON.stringify(history));
        } catch (_error) {
          e = _error;
        }
      };
    })(this)([]);
  };
  about = function() {
    return "Built by <a target=\"_new\" href=\"http://twitter.com/rem\">@rem</a>";
  };
  whichKey = function(event) {
    var keys;
    keys = void 0;
    keys = {
      38: 1,
      40: 1,
      Up: 38,
      Down: 40,
      Enter: 10,
      "U+0009": 9,
      "U+0008": 8,
      "U+0190": 190,
      Right: 39,
      "U+0028": 57,
      "U+0026": 55
    };
    return keys[event.keyIdentifier] || event.which || event.keyCode;
  };
  setCursorTo = function(str) {
    var rows;
    rows = void 0;
    str = (enableCC ? cleanse(str) : str);
    exec.value = str;
    if (enableCC) {
      document.execCommand("selectAll", false, null);
      document.execCommand("delete", false, null);
      document.execCommand("insertHTML", false, str);
    } else {
      rows = str.match(/\n/g);
      exec.setAttribute("rows", (rows !== null ? rows.length + 1 : 1));
    }
    cursor.focus();
    window.scrollTo(0, 0);
  };
  findNode = function(list, node) {
    var _this = this;
    return (function(_arg) {
      var i, pos;
      pos = _arg[0];
      pos = 0;
      i = 0;
      while (i < list.length) {
        if (list[i] === node) {
          return pos;
        }
        pos += list[i].nodeValue.length;
        i++;
      }
      return -1;
    })([]);
  };
  completeCode = function(focus) {
    var l, range, selection, tmp;
    tmp = void 0;
    l = void 0;
    range = void 0;
    selection = void 0;
    tmp = exec.textContent;
    l = tmp.length;
    removeSuggestion();
    cursor.innerHTML = tmp;
    ccPosition = false;
    document.getElementsByTagName("a")[0].focus();
    cursor.focus();
    range = void 0;
    selection = void 0;
    if (document.createRange) {
      range = document.createRange();
      range.selectNodeContents(cursor);
      range.collapse(false);
      selection = window.getSelection();
      selection.removeAllRanges();
      selection.addRange(range);
    } else if (document.selection) {
      range = document.body.createTextRange();
      range.moveToElementText(cursor);
      range.collapse(false);
      range.select();
    }
  };

  baseURL = (window.top.COFFEECONSOLE ? window.top.COFFEECONSOLE.baseURL : window.location.href.split(/[#?]/)[0].replace(/\/[^\/]*$/, ""));
  window.info = info;
  ccCache = {};
  ccPosition = false;
  window._console = {
    log: function() {
      var i, l;
      l = void 0;
      i = void 0;
      l = arguments.length;
      i = 0;
      while (i < l) {
        log(stringify(arguments[i], true));
        i++;
      }
    },
    dir: function() {
      var i, l;
      l = void 0;
      i = void 0;
      l = arguments.length;
      i = 0;
      while (i < l) {
        log(stringify(arguments[i]));
        i++;
      }
    },
    props: function(obj) {
      var _this = this;
      return (function(_arg) {
        var e, p, props, realObj;
        e = _arg[0];
        props = void 0;
        realObj = void 0;
        props = [];
        realObj = void 0;
        try {
          for (p in obj) {
            props.push(p);
          }
        } catch (e) {

        }
        return props;
      })([]);
    }
  };


  if (document.addEventListener) {
    window.addEventListener("message", function(event) {
      post(event.data);
    }, false);
  } else {
    window.attachEvent("onmessage", function() {
      post(window.event.data);
    });
  }
  exec = document.getElementById("exec");
  form = exec.form || {};
  output = document.getElementById("output");
  cursor = document.getElementById("exec");
  injected = typeof window.top["COFFEECONSOLE"] !== "undefined";
  sandboxframe = (injected ? window.top["COFFEECONSOLE"] : document.createElement("iframe"));
  sandbox = null;
  fakeConsole = "window.top._console";
  history = getHistory();
  liveHistory = window.history.pushState !== undefined;
  pos = 0;
  libraries = {
    jquery: "http://ajax.googleapis.com/ajax/libs/jquery/1/jquery.min.js",
    prototype: "http://ajax.googleapis.com/ajax/libs/prototype/1/prototype.js",
    dojo: "http://ajax.googleapis.com/ajax/libs/dojo/1/dojo/dojo.xd.js",
    mootools: "http://ajax.googleapis.com/ajax/libs/mootools/1/mootools-yui-compressed.js",
    underscore: "http://documentcloud.github.com/underscore/underscore-min.js",
    rightjs: "http://rightjs.org/hotlink/right.js",
    yui: "http://yui.yahooapis.com/3.2.0/build/yui/yui-min.js"
  };
  body = document.getElementsByTagName("body")[0];
  logAfter = null;
  historySupported = !!(window.history && window.history.pushState);
  sse = null;
  lastCmd = null;
  remoteId = null;
  codeCompleteTimer = null;
  keypressTimer = null;
  commands = {
    help: showhelp,
    about: about,
    load: load,
    history: showHistory,
    clear: function() {
      setTimeout((function() {
        output.innerHTML = "";
      }), 10);
      return "clearing...";
    },
    close: function() {
      if (injected) {
        sandboxframe.console.style.display = "none";
        return "hidden";
      } else {
        return "noop";
      }
    },
    listen: function(id) {
      var callback, script;
      script = document.createElement("script");
      callback = "_cb" + +(new Date);
      script.src = "/remote/" + (id || "") + "?callback=" + callback;
      window[callback] = function(id) {
        remoteId = id;
        if (sse !== null) {
          sse.close();
        }
        sse = new EventSource("/remote/" + id + "/log");
        sse.onopen = function() {
          remoteId = id;
          info("Connected to \"" + id + "\"\n\n<script id=\"coffeeconsoleremote\" src=\"" + baseURL + "/remote.js?" + id + "\"></script>");
        };
        sse.onmessage = function(event) {
          var data;
          data = JSON.parse(event.data);
          if (data.type && data.type === "error") {
            post(data.cmd, true, ["error", data.response]);
          } else if (data.type && data.type === "info") {
            info(data.response);
          } else {
            if (data.cmd !== "remote console.log") {
              data.response = data.response.substr(1, data.response.length - 2);
            }
            echo(data.cmd);
            log(data.response, "response");
          }
        };
        sse.onclose = function() {
          info("Remote connection closed");
          remoteId = null;
        };
        try {
          body.removeChild(script);
          delete window[callback];
        } catch (e) {

        }
      };
      body.appendChild(script);
      return "Creating connection...";
    }
  };
  fakeInput = null;
  iOSMobile = navigator.userAgent.indexOf("AppleWebKit") !== -1 && navigator.userAgent.indexOf("Mobile") !== -1;
  enableCC = navigator.userAgent.indexOf("AppleWebKit") !== -1 && navigator.userAgent.indexOf("Mobile") === -1 || navigator.userAgent.indexOf("OS 5_") !== -1;
  if (enableCC) {
    exec.parentNode.innerHTML = "<div autofocus id=\"exec\" autocapitalize=\"off\" spellcheck=\"false\"><span id=\"cursor\" spellcheck=\"false\" autocapitalize=\"off\" autocorrect=\"off\"" + (iOSMobile ? "" : " contenteditable") + "></span></div>";
    exec = document.getElementById("exec");
    cursor = document.getElementById("cursor");
  }
  if (enableCC && iOSMobile) {
    fakeInput = document.createElement("input");
    fakeInput.className = "fakeInput";
    fakeInput.setAttribute("spellcheck", "false");
    fakeInput.setAttribute("autocorrect", "off");
    fakeInput.setAttribute("autocapitalize", "off");
    exec.parentNode.appendChild(fakeInput);
  }
  if (!injected) {
    body.appendChild(sandboxframe);
    sandboxframe.setAttribute("id", "sandbox");
  }
  sandbox = sandboxframe.contentDocument || sandboxframe.contentWindow.document;
  if (!injected) {
    sandbox.open();
    sandbox.write("<script>(function () { var fakeConsole = " + fakeConsole + "; if (console != undefined) { for (var k in fakeConsole) { console[k] = fakeConsole[k]; } } else { console = fakeConsole; } })();</script>");
    sandbox.close();
  }
  cursor.focus();
  output.parentNode.tabIndex = 0;

  output.ontouchstart = output.onclick = function(event) {
    var command;
    command = void 0;
    event = event || window.event;
    if (event.target.nodeName === "A" && event.target.className === "permalink") {
      command = decodeURIComponent(event.target.search.substr(1));
      setCursorTo(command);
      if (liveHistory) {
        window.history.pushState(command, command, event.target.href);
      }
      return false;
    }
  };
  exec.ontouchstart = function() {
    window.scrollTo(0, 0);
  };
  exec.onkeyup = function(event) {
    var which;
    which = void 0;
    which = whichKey(event);
    if (enableCC && which !== 9 && which !== 16) {
      clearTimeout(codeCompleteTimer);
      codeCompleteTimer = setTimeout(function() {
        codeComplete(event);
      }, 200);
    }
  };

  if (enableCC) {
    cursor.__onpaste = function(event) {
      setTimeout((function() {
        cursor.innerHTML = cursor.innerText;
      }), 10);
    };
  }
  modifierkeys = {
    0: 1,
    16: 1
  };
  exec.onkeydown = function(event) {
    var command, cursorPos, firstnl, keys, lastnl, rows, selRange, value, which, wide;
    keys = void 0;
    wide = void 0;
    which = void 0;
    event = event || window.event;
    keys = {
      38: 1,
      40: 1
    };
    wide = body.className === "large";
    which = whichKey(event);
    if (typeof which === "string") {
      which = which.replace(/\/U\+/, "\\u");
    }
    if (keys[which]) {
      if (event.shiftKey) {
        changeView(event);
      } else if (!wide) {
        if (enableCC && window.getSelection) {
          window.selObj = window.getSelection();
          selRange = selObj.getRangeAt(0);
          cursorPos = findNode(selObj.anchorNode.parentNode.childNodes, selObj.anchorNode) + selObj.anchorOffset;
          value = exec.value;
          firstnl = value.indexOf("\n");
          lastnl = value.lastIndexOf("\n");
          if (firstnl !== -1) {
            if (which === 38 && cursorPos > firstnl) {
              return;
            } else {
              if (which === 40 && cursorPos < lastnl) {
                return;
              }
            }
          }
        }
        if (which === 38) {
          pos--;
          if (pos < 0) {
            pos = 0;
          }
        } else if (which === 40) {
          pos++;
          if (pos >= history.length) {
            pos = history.length;
          }
        }
        if ((history[pos] != null) && history[pos] !== "") {
          removeSuggestion();
          setCursorTo(history[pos]);
          return false;
        } else if (pos === history.length) {
          removeSuggestion();
          setCursorTo("");
          return false;
        }
      }
    } else if ((which === 13 || which === 10) && event.shiftKey === false) {
      removeSuggestion();
      if (event.shiftKey === true || event.metaKey || event.ctrlKey || !wide) {
        command = exec.textContent || exec.value;
        if (command.length) {
          post(command);
        }
        return false;
      }
    } else if ((which === 13 || which === 10) && !enableCC && event.shiftKey === true) {
      rows = exec.value.match(/\n/g);
      rows = (rows != null ? rows.length + 2 : 2);
      exec.setAttribute("rows", rows);
    } else if (which === 9 && wide) {
      checkTab(event);
    } else if (event.shiftKey && event.metaKey && which === 8) {
      output.innerHTML = "";
    } else if ((which === 39 || which === 35) && ccPosition !== false) {
      completeCode();
    } else if (event.ctrlKey && which === 76) {
      output.innerHTML = "";
    } else if (enableCC) {
      if (ccPosition !== false && which === 9) {
        codeComplete(event);
        return false;
      } else {
        if (ccPosition !== false && cursor.nextSibling && !modifierkeys[which]) {
          removeSuggestion();
        }
      }
    }
  };

  if (enableCC && iOSMobile) {
    fakeInput.onkeydown = function(event) {
      var which;
      which = void 0;
      removeSuggestion();
      which = whichKey(event);
      if (which === 13 || which === 10) {
        post(this.value);
        this.value = "";
        cursor.innerHTML = "";
        return false;
      }
    };
    fakeInput.onkeyup = function(event) {
      var which;
      which = void 0;
      cursor.innerHTML = cleanse(this.value);
      which = whichKey(event);
      if (enableCC && which !== 9 && which !== 16) {
        clearTimeout(codeCompleteTimer);
        codeCompleteTimer = setTimeout(function() {
          codeComplete(event);
        }, 200);
      }
    };
    fakeInputFocused = false;
    dblTapTimer = null;
    taps = 0;
    form.addEventListener("touchstart", function(event) {
      if (ccPosition !== false) {
        event.preventDefault();
        clearTimeout(dblTapTimer);
        taps++;
        if (taps === 2) {
          completeCode();
          fakeInput.value = cursor.textContent;
          removeSuggestion();
          fakeInput.focus();
        } else {
          dblTapTimer = setTimeout(function() {
            taps = 0;
            codeComplete({
              which: 9
            });
          }, 200);
        }
      }
      return false;
    });
  }
  form.onsubmit = function(event) {
    event = event || window.event;
    event.preventDefault && event.preventDefault();
    removeSuggestion();
    post(exec.textContent || exec.value);
    return false;
  };
  document.onkeydown = function(event) {
    var which;
    which = void 0;
    event = event || window.event;
    which = event.which || event.keyCode;
    if (event.shiftKey && event.metaKey && which === 8) {
      output.innerHTML = "";
      cursor.focus();
    } else {
      if (event.target === output.parentNode && which === 32) {
        output.parentNode.scrollTop += 5 + output.parentNode.offsetHeight * (event.shiftKey ? -1 : 1);
      }
    }
    return changeView(event);
  };
  exec.onclick = function() {
    cursor.focus();
  };
  if (window.location.search) {
    post(decodeURIComponent(window.location.search.substr(1)));
  } else {
    post(":help", true);
  }
  window.onpopstate = function(event) {
    setCursorTo(event.state || "");
  };
  setTimeout((function() {
    window.scrollTo(0, 1);
  }), 500);
  setTimeout((function() {
    document.getElementById("footer").className = "hidden";
  }), 5000);
  getProps("window");
  try {
    if (!!(localStorage.large * 1)) {
      document.body.className = "large";
    }
  } catch (_error) {
    e = _error;
  }
  if (document.addEventListener) {
    document.addEventListener("deviceready", (function() {
      cursor.focus();
    }), false);
  }
  if (injected) {
    (function() {
      var k, x, y;
      x = window._console;
      y = window.top.console;
      k = void 0;
      if (y) {
        for (k in x) {
          y[k] = x[k];
        }
      } else {
        window.top.console = x;
      }
    })();
  }
    
})(this);
