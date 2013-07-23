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
 
 Compile through: $ coffee -bw -o js -c CoffeeScript/jquery.lwao.coffee
*/

$.fn.extend({
  lwao: function(options) {
    var attachList, evaluateAjax, latestSearchTerm, log, requestInProgress, requestTimeout, runAjax, settings;
    settings = {
      minLength: 3,
      ajaxUrl: '',
      ajaxType: 'POST',
      ajaxData: {},
      requestWait: 300,
      inputVarName: 'searchTerm',
      responseResultVarName: 'result',
      resultDisplay: ['<li><a href="/quote/%s"><span class="author">by %s</span><span class="quote">%s</span><span class=\"clearfix\"></span></a></li>', 'qId', 'authorName', 'quote'],
      noResultsHtml: '<span class="noResults">Couldn\'t find anything... sorry =(</span>',
      container: $(".lwao_result"),
      containerCss: {},
      hideContainerOnBlur: true,
      wrapperHtml: "<ul class=\"list\">\n" + "[RESULTS]" + "</ul>\n",
      useBackdrop: true,
      backdrop: $(".lwao_backdrop"),
      stringMaxLength: 80,
      highlightSearchTerm: true,
      searchTermHighlightPadding: 10,
      stringEllipsis: "...",
      padEllipsis: true,
      fadeSpeed: 150,
      debug: true
    };
    settings = jQuery.extend(settings, options);
    log = function(msg) {
      if (settings.debug) {
        return typeof console !== "undefined" && console !== null ? console.log(msg) : void 0;
      }
    };
    attachList = function(result, inputField) {
      var ajaxResultToMatch, endEllipsis, html, index, initialEllipsis, obj, right, scrollTop, searchTerm, searchTermOccurenceIsBeyondView, searchTermOffset, searchTermRegex, string, substrLength, substrStartPoint, thisHtml, top, _i, _j, _len, _len1, _ref;
      if (settings.resultDisplay[0].match(/%s/g).length !== (settings.resultDisplay.length - 1)) {
        return false;
      }
      searchTerm = inputField.val();
      html = "";
      for (index = _i = 0, _len = result.length; _i < _len; index = ++_i) {
        obj = result[index];
        thisHtml = settings.resultDisplay[0];
        _ref = settings.resultDisplay;
        for (index = _j = 0, _len1 = _ref.length; _j < _len1; index = ++_j) {
          string = _ref[index];
          if (index === 0) {
            continue;
          }
          ajaxResultToMatch = obj[string];
          if (settings.stringMaxLength > 0) {
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
          if (settings.highlightSearchTerm) {
            searchTermRegex = new RegExp("(" + searchTerm + ")", 'ig');
            ajaxResultToMatch = ajaxResultToMatch.replace(searchTermRegex, "<strong>$1</strong>");
          }
          thisHtml = thisHtml.replace("%s", ajaxResultToMatch);
        }
        html += thisHtml;
      }
      html = settings.wrapperHtml.replace("[RESULTS]", html);
      if ((settings.containerCss["position"] != null) && settings.containerCss["position"] === "absolute" || settings.containerCss["position"] === "fixed") {
        scrollTop = $("body").scrollTop();
        top = (inputField.offset().top - scrollTop) + inputField.closest("div").height();
        right = $(".quotes_container").css("padding-right");
        settings.containerCss({
          position: position,
          top: top,
          right: right
        });
      } else {
        settings.container.css(settings.containerCss);
      }
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
          if (response.status === 0 && response[settings.responseResultVarName].length > 0) {
            return attachList(response[settings.responseResultVarName], inputField);
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
    $(document).on('click', '.lwao_result li', function() {
      return true;
    });
    $(this).each(function() {
      return $(this).on('keyup', function() {
        return evaluateAjax($(this));
      });
    });
    return $("body").on('click', function() {
      if (settings.hideContainerOnBlur) {
        settings.container.fadeOut(settings.fadeSpeed);
      }
      return settings.backdrop.fadeOut(settings.fadeSpeed);
    });
  }
});
