// Generated by CoffeeScript 1.6.3
/*
 jQuery lwao 1.0
 
 Copyright (c) 2013 Helge Söderström
 http://github.com/dimhoLt
 
 Plugin website:
 http://github.com/dimhoLt/lwao_autocomplete
 
 Dual licensed under the MIT and GPL licenses.
 http://en.wikipedia.org/wiki/MIT_License
 http://en.wikipedia.org/wiki/GNU_General_Public_License
 
 Compile through:
 $ coffee -bw -o js -c CoffeeScript/jquery.lwao.coffee
 
 Minify compiled JS through:
 $ uglifyjs js/jquery.lwao.js -p js/jquery.lwao.min.js
*/

$.fn.extend({
  lwao: function(options) {
    var attachList, evaluateAjax, hide, itemSelected, latestSearchTerm, log, objLength, requestInProgress, requestTimeout, runAjax, settings, traverseResultList, traversingInProgress;
    settings = {
      minLength: 3,
      ajaxUrl: '',
      ajaxType: 'POST',
      ajaxData: {},
      requestWait: 300,
      inputVarName: 'searchTerm',
      responseResultVarName: 'result',
      resultDisplay: {
        'html': '<li><a href="/quote/%s"><span class="author">by %s</span><span class="quote">%s</span><span class=\"clearfix\"></span></a></li>',
        'qId': '',
        'authorName': 'unknown',
        'quote': ''
      },
      noResultsHtml: '<span class="noResults">Couldn\'t find anything... sorry =(</span>',
      container: $(".lwao_result"),
      containerCss: {},
      hideContainerOnBlur: true,
      wrapperHtml: "<ul class=\"lwao_list\">\n" + "[RESULTS]" + "</ul>\n",
      useBackdrop: true,
      backdrop: $(".lwao_backdrop"),
      stringMaxLength: 80,
      highlightSearchTerm: true,
      searchTermHighlightPadding: 10,
      stringEllipsis: "...",
      padEllipsis: true,
      fadeSpeed: 150,
      selectCallback: null,
      changeAfterSelectCallback: null,
      disableTraversal: false,
      debug: true
    };
    settings = jQuery.extend(settings, options);
    log = function(msg) {
      if (settings.debug) {
        return typeof console !== "undefined" && console !== null ? console.log(msg) : void 0;
      }
    };
    objLength = function(obj) {
      var key, length;
      length = 0;
      for (key in obj) {
        if (obj.hasOwnProperty(key)) {
          length++;
        }
      }
      return length;
    };
    traversingInProgress = false;
    itemSelected = false;
    traverseResultList = function(direction) {
      switch (direction) {
        case "down":
          if (settings.container.find("li a.selected").length === 0) {
            settings.container.find("li:first a").addClass("selected");
          } else {
            settings.container.find("a.selected").removeClass("selected").closest("li").next().find("a").addClass("selected");
          }
          break;
        case "up":
          if (settings.container.find("li a.selected").length === 0) {
            settings.container.find("li:last a").addClass("selected");
          } else {
            settings.container.find("a.selected").removeClass("selected").closest("li").prev().find("a").addClass("selected");
          }
      }
      traversingInProgress = false;
    };
    hide = function() {
      if (settings.hideContainerOnBlur) {
        settings.container.fadeOut(settings.fadeSpeed);
      }
      return settings.backdrop.fadeOut(settings.fadeSpeed);
    };
    attachList = function(results, inputField) {
      var ajaxResultKeyToFind, ajaxResultToMatch, currObj, endEllipsis, fallbackValue, html, index, initialEllipsis, newResultToMatch, objValue, objValues, result, right, scrollTop, searchTerm, searchTermOccurenceIsBeyondView, searchTermOffset, searchTermRegex, substrLength, substrStartPoint, thisHtml, top, _i, _j, _len, _len1, _ref;
      if (settings.resultDisplay.html.match(/%s/g).length !== objLength(settings.resultDisplay) - 1) {
        return false;
      }
      searchTerm = inputField.val();
      html = "";
      for (index = _i = 0, _len = results.length; _i < _len; index = ++_i) {
        result = results[index];
        thisHtml = settings.resultDisplay.html;
        _ref = settings.resultDisplay;
        for (ajaxResultKeyToFind in _ref) {
          fallbackValue = _ref[ajaxResultKeyToFind];
          if (ajaxResultKeyToFind === 'html') {
            continue;
          }
          if (ajaxResultKeyToFind.indexOf(".") !== -1) {
            objValues = ajaxResultKeyToFind.split(".");
            ajaxResultToMatch = result[objValues[0]];
          } else {
            ajaxResultToMatch = result[ajaxResultKeyToFind];
          }
          if (ajaxResultToMatch == null) {
            ajaxResultToMatch = fallbackValue;
          }
          if (typeof ajaxResultToMatch === 'object') {
            if ((objValues != null) && ajaxResultToMatch[objValues[1]]) {
              newResultToMatch = "";
              currObj = ajaxResultToMatch[objValues[1]];
              for (index = _j = 0, _len1 = objValues.length; _j < _len1; index = ++_j) {
                objValue = objValues[index];
                if ((currObj == null) || typeof currObj !== 'object') {
                  break;
                }
                currObj = currObj[ajaxResultKeyToFind];
              }
              if (currObj) {
                ajaxResultToMatch = currObj;
              }
            }
          }
          if (typeof ajaxResultToMatch !== 'object' && settings.stringMaxLength > 0) {
            if (ajaxResultToMatch.length > settings.stringMaxLength + settings.stringEllipsis.length) {
              substrStartPoint = 0;
              initialEllipsis = "";
              endEllipsis = "";
              if (settings.highlightSearchTerm) {
                searchTermOffset = ajaxResultToMatch.indexOf(searchTerm);
                searchTermOccurenceIsBeyondView = searchTermOffset + searchTerm.length > settings.stringMaxLength;
                if (searchTermOffset > -1 && searchTermOccurenceIsBeyondView) {
                  substrStartPoint = (searchTermOffset + searchTerm.length + settings.searchTermHighlightPadding) - settings.stringMaxLength;
                }
                substrStartPoint = Math.max(substrStartPoint, 0);
                if (substrStartPoint > 0) {
                  initialEllipsis = settings.stringEllipsis;
                  substrStartPoint += settings.stringEllipsis.length;
                  if (settings.padEllipsis) {
                    initialEllipsis = initialEllipsis + " ";
                    substrStartPoint++;
                  }
                }
              }
              substrLength = settings.stringMaxLength;
              substrLength -= initialEllipsis.length;
              if (ajaxResultToMatch.length - substrStartPoint > substrLength) {
                endEllipsis = settings.stringEllipsis;
                if (settings.padEllipsis) {
                  endEllipsis = " " + endEllipsis;
                  substrLength -= endEllipsis.length;
                }
              }
              ajaxResultToMatch = ajaxResultToMatch.substr(substrStartPoint, substrLength);
              ajaxResultToMatch = initialEllipsis + ajaxResultToMatch + endEllipsis;
            }
          }
          if (typeof ajaxResultToMatch !== 'object' && settings.highlightSearchTerm) {
            searchTermRegex = new RegExp("(" + searchTerm + ")", 'ig');
            ajaxResultToMatch = ajaxResultToMatch.replace(searchTermRegex, "<strong>$1</strong>");
          }
          if (typeof ajaxResultToMatch === 'object') {
            ajaxResultToMatch = JSON.stringify(ajaxResultToMatch);
          }
          thisHtml = thisHtml.replace("%s", ajaxResultToMatch);
        }
        html += thisHtml;
      }
      html = settings.wrapperHtml.replace("[RESULTS]", html);
      if ((settings.containerCss["position"] != null) && settings.containerCss["position"] === "absolute" || settings.containerCss["position"] === "fixed") {
        scrollTop = $(window).scrollTop();
        top = (inputField.offset().top - scrollTop) + inputField.closest("div").height();
        right = $(".quotes_container").css("padding-right");
        settings.container.css({
          position: settings.containerCss["position"],
          top: top,
          right: right
        });
      }
      settings.container.css(settings.containerCss);
      settings.container.fadeIn(settings.fadeSpeed).html(html);
      if (settings.useBackdrop) {
        return settings.backdrop.fadeIn(settings.fadeSpeed);
      }
    };
    requestTimeout = null;
    requestInProgress = false;
    latestSearchTerm = null;
    runAjax = function(query, inputField) {
      if (requestInProgress === true) {
        return false;
      }
      settings.ajaxData[settings.inputVarName] = query;
      return $.ajax({
        url: settings.ajaxUrl,
        type: settings.ajaxType,
        async: true,
        data: settings.ajaxData,
        beforeSend: function() {
          requestInProgress = true;
          return latestSearchTerm = query;
        },
        success: function(response) {
          var currObject, index, objectName, objectNames, responseObjectToUse, _i, _len;
          if (response.status === 0) {
            if (settings.responseResultVarName.indexOf(".") !== -1) {
              objectNames = settings.responseResultVarName.split(".");
              if (response[objectNames[0]] != null) {
                currObject = response[objectNames[0]];
              } else {
                settings.container.html(settings.noResultsHtml);
                return;
              }
              for (index = _i = 0, _len = objectNames.length; _i < _len; index = ++_i) {
                objectName = objectNames[index];
                if (index === 0) {
                  continue;
                }
                if (currObject[objectName] != null) {
                  currObject = currObject[objectName];
                  if (index === objectNames.length - 1) {
                    responseObjectToUse = currObject;
                  }
                }
              }
            }
            if (response[settings.responseResultVarName] != null) {
              responseObjectToUse = response[settings.responseResultVarName];
            }
            console.log(responseObjectToUse);
            if ((responseObjectToUse != null) && responseObjectToUse.length > 0) {
              return attachList(responseObjectToUse, inputField);
            } else {
              return settings.container.html(settings.noResultsHtml);
            }
          } else {
            return settings.container.html(settings.noResultsHtml);
          }
        },
        error: function(xhr, message, code) {
          return typeof console !== "undefined" && console !== null ? console.log(message) : void 0;
        },
        complete: function() {
          requestInProgress = false;
          return requestTimeout = null;
        }
      });
    };
    evaluateAjax = function(inputField) {
      var query;
      query = inputField.val().trim();
      if (query.length < settings.minLength) {
        settings.container.fadeOut(settings.fadeSpeed);
        settings.backdrop.fadeOut(settings.fadeSpeed);
        return false;
      }
      if (query === latestSearchTerm) {
        return false;
      }
      if (requestTimeout === null) {
        requestTimeout = new Date().getTime();
      } else if (new Date().getTime() - requestTimeout < settings.requestWait) {
        return false;
      }
      return runAjax(query, inputField);
    };
    settings.container.on('click', 'li a', function(e) {
      if (settings.selectCallback !== null) {
        e.preventDefault();
        itemSelected = true;
        settings.selectCallback($(this).parent());
      }
      return true;
    });
    if (settings.disableTraversal === false) {
      $(this).on('keyup', function(e) {
        var locationTarget;
        if (e.keyCode === 38) {
          return traverseResultList("up");
        } else if (e.keyCode === 40) {
          return traverseResultList("down");
        } else if (e.keyCode === 13) {
          e.preventDefault();
          itemSelected = true;
          if (settings.container.find("a.selected").length !== 0) {
            if (settings.selectCallback !== null) {
              settings.selectCallback(settings.container.find("a.selected").closest("li"));
              return hide();
            } else {
              locationTarget = settings.container.find("a.selected").attr("href");
              return window.location.href = locationTarget;
            }
          } else {
            return false;
          }
        }
      });
    }
    settings.container.on('mouseenter', function() {
      return $(this).find("a").removeClass("selected");
    });
    $(this).each(function() {
      return $(this).on('keyup', function(e) {
        if (e.keyCode === 13) {
          return;
        }
        if (e.keyCode === 27) {
          return hide();
        } else {
          if (itemSelected === true) {
            itemSelected = false;
            if (settings.changeAfterSelectCallback !== null) {
              settings.changeAfterSelectCallback();
            }
          }
          return evaluateAjax($(this));
        }
      });
    });
    return $("body").on('click', function() {
      return hide();
    });
  }
});
