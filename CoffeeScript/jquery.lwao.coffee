###
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
###

$.fn.extend
    lwao: (options) ->
    
        # Default settings
        settings =
            # The least amount of characters before AJAX is triggered.
            minLength: 3
            
            # URL of the AJAX call.
            ajaxUrl: ''
            
            # Method in AJAX call.
            ajaxType: 'POST'
            
            # Extra data in AJAX call, in addition to what's in the input field.
            ajaxData: {}
            
            # The amount of time to wait before a new AJAX-request is allowed.
            requestWait: 300
            
            # The server variable name that holds the value of the input field.
            inputVarName: 'searchTerm'
            
            # The server response object name to accept as result.
            responseResultVarName: 'result'
            
            # The HTML string created by the server result for each item. The
            # first value, 'html', is the HTML markup that will constitute each
            # item. If SHOULD contain '%s'-strings plotting replaces
            # corresponding to server results.
            # Following this, there should be an EQUAL number of values in this
            # object as there are '%s'-strings in the markup defining which
            # result values we'll actually use to populate the list. NOTE that
            # these MAY contain dots, if the server item we're looking for is
            # an object. Example:
            #     'author.name' will assume that the server returns an "author"
            #                   object with the value "name".
            #
            # The value of the key is the fallback value if the server response
            # is null or undefined.
            #
            # Example:
            #   'html'        : '<li><span class="article">%s</span> <span class="author">%s</span></li>'
            #   'article'     : ''
            #   'author.name' : 'unknown'
            #
            # Assumes a result from the server looking like this:
            #   {
            #     article: 'My epic article.',
            #     author: {
            #       id: 1,
            #       name: 'Jackie Chan'
            #     }
            #   }
            resultDisplay:
                'html': '<li><a href="/quote/%s"><span class="author">by %s</span><span class="quote">%s</span><span class=\"clearfix\"></span></a></li>'
                'replaces': [
                    {
                        'varName': 'qId'
                        'fallback': ''
                    }
                    
                    {
                        'varName': 'authorName'
                        'fallback': 'unknown'
                    }
                    
                    {
                        'varName': 'quote'
                        'fallback': ''
                    }
                ]
            
            # Text that is shown if no results are available.
            noResultsHtml: '<span class="noResults">Couldn\'t find anything... sorry =(</span>'
            
            # The container in which the generated result HTML is put.
            container: $(".lwao_result")
            
            # Associative array of CSS to set to container when showing results.
            # Example:
            #   containerCss: {
            #       'position': 'relative',
            #       'background': 'red'
            #   }
            containerCss: {}
            
            # Whether or not to remove the container from the DOM on blur or
            # keep it.
            hideContainerOnBlur: true
            
            # The wrapper HTML holds a "[RESULTS]"-string which is replaced by
            # the generated HTML from the server result. This is to make it
            # easier to build lists.
            wrapperHtml:
                "<ul class=\"lwao_list\">\n" +
                "[RESULTS]" +
                "</ul>\n"
                
            # Whether or not to use backdrop.
            useBackdrop: true
            
            # The backdrop object.
            backdrop: $(".lwao_backdrop")
            
            # The max length of the server result strings to be shown in the
            # result list.
            stringMaxLength: 80
            
            # If set to true, the script will find the occurrence of the
            # matching input value in the server result, forward the string to
            # it's location and highlight it in the results list.
            highlightSearchTerm: true
            
            # The amount of characters to be included after the highlighted
            # result to give the result proper context.
            searchTermHighlightPadding: 10
            
            # If the result string is cropped, the ellipsis string will be
            # shown after (or before) where actual text has been removed.
            stringEllipsis: "..."
            
            # Whether or not to pad the ellipsis with a space.
            padEllipsis: true
            
            # The amount of time for the fade animation to run.
            fadeSpeed: 150
            
            # Callback function to run when clicking something. Contains the
            # clicked element as the parameter.
            selectCallback: null

            # Callback function to run if changing the input after an item has
            # been selected.
            changeAfterSelectCallback: null
            
            # If set, traversal, i.e., selecting the result item using the
            # keyboard arrow keys is ignored.
            disableTraversal: false
            
            # If in debug mode, more debug data is output.
            debug: true
        
        
        # Merge default settings with options.
        settings = jQuery.extend settings, options


        # Simple logger.
        log = (msg) ->
            console?.log msg if settings.debug
        
        
        # State trackers...
        traversingInProgress = false
        itemSelected = false
            
            
        #
        # Traverse the result list.
        #
        traverseResultList = (direction) ->
            switch direction
                when "down"
                    if settings.container.find("li a.selected").length is 0
                        settings.container.find("li:first a").addClass "selected"
                    else
                        settings.container.find("a.selected")
                            .removeClass("selected")
                            .closest("li")
                            .next()
                            .find("a")
                            .addClass("selected")
                                
                when "up"
                    if settings.container.find("li a.selected").length is 0
                        settings.container.find("li:last a").addClass "selected"
                        
                    else
                        settings.container.find("a.selected")
                            .removeClass("selected")
                            .closest("li")
                            .prev()
                            .find("a")
                            .addClass("selected")
            
            traversingInProgress = false
            return
            
            
        #
        # Hides the autocomplete according to settings.
        #
        hide = ->
            if settings.hideContainerOnBlur
                settings.container.fadeOut settings.fadeSpeed
            settings.backdrop.fadeOut settings.fadeSpeed
         
         
        #
        # Attach list with results to search object.
        #
        attachList = (results, inputField) ->
            if settings.resultDisplay.html.match(/%s/g).length isnt settings.resultDisplay.replaces.length
                return false
            
            searchTerm = inputField.val()
            
            html = ""
            for result, index in results
                thisHtml = settings.resultDisplay.html

                # A non-global regex will perform the matches one-by-one.
                for index, replace of settings.resultDisplay.replaces
                    if replace.varName.indexOf(".") isnt -1
                        objValues = replace.varName.split(".")
                        ajaxResultToMatch = result[objValues[0]]
                    else
                        ajaxResultToMatch = result[replace.varName]
                    
                    ajaxResultToMatch = replace.fallback if not ajaxResultToMatch?
                    
                    # If we're having nested objects, the result has to be able
                    # to resolve it.
                    if typeof ajaxResultToMatch is 'object'
                        # If it can't match, skip it.
                        if objValues? and ajaxResultToMatch[objValues[1]]
                            newResultToMatch = ""
                            currObj = ajaxResultToMatch[objValues[1]]
                            for objValue, index in objValues
                                if !currObj? or typeof currObj isnt 'object'
                                    break

                                currObj = currObj[replace.varName]

                            if currObj
                                ajaxResultToMatch = currObj

                    if typeof ajaxResultToMatch isnt 'object' and settings.stringMaxLength > 0
                        if ajaxResultToMatch.length > settings.stringMaxLength + settings.stringEllipsis.length
                            substrStartPoint = 0

                            initialEllipsis = ""
                            endEllipsis = ""
                            if settings.highlightSearchTerm
                                # Find the place in the string where the
                                # search term is.
                                searchTermOffset = ajaxResultToMatch.indexOf searchTerm

                                searchTermOccurenceIsBeyondView = searchTermOffset + searchTerm.length > settings.stringMaxLength
                                if searchTermOffset > -1 and searchTermOccurenceIsBeyondView
                                    substrStartPoint = (searchTermOffset + searchTerm.length + settings.searchTermHighlightPadding) - settings.stringMaxLength

                                # Disallow the substring startpoint to be negative.
                                substrStartPoint = Math.max substrStartPoint, 0
                                
                                # If we start from somewhere in the string,
                                # we'll need to ellips it at the beginning as
                                # well.
                                if substrStartPoint > 0
                                    initialEllipsis = settings.stringEllipsis
                                    substrStartPoint += settings.stringEllipsis.length
                                    if settings.padEllipsis
                                        initialEllipsis = initialEllipsis + " "
                                        substrStartPoint++

                            # Find out how much of the string should be
                            # removed.
                            substrLength = settings.stringMaxLength
                            substrLength -= initialEllipsis.length

                            # Only apply the end ellipsis if we haven't pushed
                            # the start too far ahead.
                            if ajaxResultToMatch.length - substrStartPoint > substrLength
                                endEllipsis = settings.stringEllipsis
                                if settings.padEllipsis
                                    endEllipsis = " " + endEllipsis
                                    substrLength -= endEllipsis.length

                            # Perform the cropping...
                            ajaxResultToMatch = ajaxResultToMatch.substr(substrStartPoint, substrLength)
                            
                            # Add the ellipsis...
                            ajaxResultToMatch = initialEllipsis + ajaxResultToMatch + endEllipsis

                    # And finally highlight the result.
                    if typeof ajaxResultToMatch isnt 'object' and settings.highlightSearchTerm
                        searchTermRegex = new RegExp("("+ searchTerm + ")", 'ig')
                        ajaxResultToMatch = ajaxResultToMatch.replace(searchTermRegex, "<strong>$1</strong>")

                    if typeof ajaxResultToMatch is 'object'
                        ajaxResultToMatch = JSON.stringify ajaxResultToMatch
                        
                    thisHtml = thisHtml.replace "%s", ajaxResultToMatch

                html += thisHtml

            # Create proper DOM...
            html = settings.wrapperHtml.replace "[RESULTS]", html

            # If we have a position, calculate placement and show the results.
            if settings.containerCss["position"]? and settings.containerCss["position"] is "absolute" or settings.containerCss["position"] is "fixed"
                scrollTop = $(window).scrollTop()
                top = (inputField.offset().top - scrollTop) + inputField.closest("div").height()
                right = $(".quotes_container").css("padding-right")
                settings.container.css
                    position: settings.containerCss["position"]
                    top: top
                    right: right
            
            # Add custom on-load css by user.
            settings.container.css settings.containerCss
            
            # Show results.
            settings.container.fadeIn(settings.fadeSpeed).html html
            
            # Are we to use backdrop? Then fade it in.
            if settings.useBackdrop
                settings.backdrop.fadeIn settings.fadeSpeed


        # Instantiate the timout variable and lock this instance to a reference.
        requestTimeout    = null
        requestInProgress = false
        latestSearchTerm  = null
        
        
        #
        # Perform request
        #
        runAjax = (query, inputField) ->
            return false if requestInProgress is true
            
            settings.ajaxData[settings.inputVarName] = query

            $.ajax
                url: settings.ajaxUrl
                type: settings.ajaxType
                async: true
                data: settings.ajaxData
                
                beforeSend: ->
                    requestInProgress = true
                    latestSearchTerm = query

                success: (response) ->
                    if response.status is 0
                        # Now, check if we've actually supplied dot-separated
                        # object selectors (e.g. "data.result").
                        if settings.responseResultVarName.indexOf(".") isnt -1
                            # We have. Find the names. This'd give the array
                            # [ 'data', 'result' ] from the above example.
                            objectNames = settings.responseResultVarName.split "."
                            
                            # Now, traverse them and see if we have the objects
                            # supplied. The last object found will be assumed
                            # the one to use. If none, the "noResultsHtml" will
                            # be shown.
                            if response[objectNames[0]]?
                                currObject = response[objectNames[0]]
                            else
                                settings.container.html settings.noResultsHtml
                                return
                                
                            for objectName, index in objectNames
                                # Already checked above.
                                continue if index is 0
                                
                                if currObject[objectName]?
                                    currObject = currObject[objectName]
                                    
                                    if index is objectNames.length - 1
                                        responseObjectToUse = currObject
                                    
                        # Nope. It's just a regular string.
                        if response[settings.responseResultVarName]?
                            responseObjectToUse = response[settings.responseResultVarName]

                        if responseObjectToUse? and responseObjectToUse.length > 0
                            attachList responseObjectToUse, inputField
                            
                        else
                            settings.container.html settings.noResultsHtml
                        
                    else
                        settings.container.html settings.noResultsHtml

                error: (xhr, message, code) ->
                    console?.log message

                complete: ->
                    requestInProgress = false
                    requestTimeout = null
                
                
        #
        # Check if we should perform another AJAX-request.
        #
        evaluateAjax = (inputField) ->
            query = inputField.val().trim()
            
            if query.length < settings.minLength
                settings.container.fadeOut settings.fadeSpeed
                settings.backdrop.fadeOut settings.fadeSpeed
                return false
            
            if query is latestSearchTerm
                return false
            
            if requestTimeout is null
                requestTimeout = new Date().getTime()

            else if new Date().getTime() - requestTimeout < settings.requestWait
                return false
                
            runAjax query, inputField
            
            
        #
        # Run the selectCallback when clicking an item from the container's list.
        #
        settings.container.on 'click', 'li a', (e) ->
            if settings.selectCallback isnt null
                e.preventDefault()
                itemSelected = true
                settings.selectCallback $(this).parent()
                
            return true
            
            
        #
        # Attach event traversing the result list to pressing the arrow keys.
        #
        if settings.disableTraversal is false
            $(this).on 'keyup', (e) ->
                if e.keyCode is 38 # Up-arrow
                    traverseResultList "up"

                else if e.keyCode is 40 # Down-arrow
                    traverseResultList "down"

                else if e.keyCode is 13 # Enter
                    e.preventDefault()
                    itemSelected = true
                    if settings.container.find("a.selected").length isnt 0
                        if settings.selectCallback isnt null
                            settings.selectCallback settings.container.find("a.selected").closest("li")
                            hide()
                            
                        else
                            locationTarget = settings.container.find("a.selected").attr "href"
                            window.location.href = locationTarget
                    else
                        return false
            
            
        #
        # Remove any selected-class from the keyboard when hovering so we don't
        # have several selected items.
        #
        settings.container.on 'mouseenter', ->
            $(this).find("a").removeClass("selected")
        
        
        #
        # Attach autocomplete to all inputs in set.
        #
        $(this).each ->
            $(this).on 'keyup', (e) ->
                # Ignore if pressing enter - that's a selection.
                if e.keyCode is 13 # Enter
                    return
                    
                if e.keyCode is 27 # Escape
                    hide()
                
                else
                    if itemSelected is true
                        itemSelected = false
                        if settings.changeAfterSelectCallback isnt null
                            settings.changeAfterSelectCallback()
                    
                    evaluateAjax $(this)
                
                
        #
        # Attach general closing events.
        #
        $("body").on 'click', ->
            hide()
        
