###
 jQuery lwao 1.0
 
 Copyright (c) 2013 Helge Söderström
 http://github.com/dimhoLt
 
 Plugin website:
 http://github.com/dimhoLt/lwao_autocomplete
 
 Dual licensed under the MIT and GPL licenses.
 http://en.wikipedia.org/wiki/MIT_License
 http://en.wikipedia.org/wiki/GNU_General_Public_License
 
 Compile through: $ coffee -bw -o js -c CoffeeScript/jquery.lwao.coffee
###

$.fn.extend
    lwao: (options) ->
    
        # Default settings
        settings =
            minLength: 3
            ajaxUrl: ''
            ajaxType: 'POST'
            ajaxData: {}
            inputVarName: 'searchTerm'
            resultDisplay: [
                # The first value is the string to place. "%s"-occurrences will
                # be replaced by the following indexes.
                #
                # The following strings are the values expected in the AJAX
                # result JSON object.
                #
                # NOTE: Every "%s" must have a corresponding following key
                #       in this array!
                '<li><a href="/quote/%s"><span class="author">by %s</span><span class="quote">%s</span><span class=\"clearfix\"></span></a></li>'
                'qId'
                'authorName'
                'quote'
            ]
            container: $(".lwao_result")
            containerHtml:
                "<ul class=\"list\">\n" +
                "[RESULTS]" +
                "</ul>\n"
            backdrop: $(".lwao_backdrop")
            stringMaxLength: 80
            searchTermHighlightPadding: 10
            stringEllipsis: "..."
            padEllipsis: true
            requestWait: 300
            fadeSpeed: 150
            highlightSearchTerm: true
            showResultFixed: false
            debug: true
        
        
        # Merge default settings with options.
        settings = jQuery.extend settings, options


        # Simple logger.
        log = (msg) ->
            console?.log msg if settings.debug
         
         
        #
        # Attach list with results to search object.
        #
        attachList = (result, inputField) ->
            if settings.resultDisplay[0].match(/%s/g).length isnt (settings.resultDisplay.length - 1)
                return false
            
            searchTerm = inputField.val()
            
            if result.length > 0
                html = ""
                for obj, index in result
                    thisHtml = settings.resultDisplay[0]

                    # A non-global regex will perform the matches one-by-one.
                    for string, index in settings.resultDisplay
                        continue if index is 0
                        
                        replaceValue = obj[string]
                        
                        if settings.stringMaxLength > 0
                            if replaceValue.length > settings.stringMaxLength + settings.stringEllipsis.length
                                substrStartPoint = 0
                                
                                initialEllipsis = ""
                                endEllipsis = ""
                                if settings.highlightSearchTerm
                                    # Find the place in the string where the
                                    # search term is.
                                    searchTermOffset = replaceValue.indexOf searchTerm

                                    searchTermOccurenceIsBeyondView = searchTermOffset + searchTerm.length > settings.stringMaxLength
                                    if searchTermOffset > -1 and searchTermOccurenceIsBeyondView
                                        # Include the entire search term +
                                        # searchTermHighlightPadding chars
                                        substrStartPoint = (searchTermOffset + searchTerm.length + settings.searchTermHighlightPadding) - settings.stringMaxLength

                                    # If we start from somewhere in the string,
                                    # we'll need to ellips it at the beginning as
                                    # well.
                                    if substrStartPoint > 0
                                        initialEllipsis = settings.stringEllipsis
                                        if settings.padEllipsis
                                            initialEllipsis = " " + initialEllipsis
                                    
                                # Find out how much of the string should be
                                # removed.
                                substrLength = settings.stringMaxLength
                                substrLength -= initialEllipsis.length
                                
                                # Only apply the final ellipsis if we haven't
                                # pushed the start too far ahead.
                                if replaceValue.length - substrStartPoint > settings.stringMaxLength
                                    endEllipsis = settings.stringEllipsis
                                    if settings.padEllipsis
                                        endEllipsis += " "
                                        substrLength -= endEllipsis.length
                                
                                # Perform the cropping...
                                replaceValue = initialEllipsis + replaceValue.substr(substrStartPoint, substrLength) + endEllipsis
                                
                        # And finally highlight the result.
                        if settings.highlightSearchTerm
                            searchTermRegex = new RegExp("("+ searchTerm + ")", 'ig')
                            replaceValue = replaceValue.replace(searchTermRegex, "<strong>$1</strong>")

                        thisHtml = thisHtml.replace "%s", replaceValue

                    html += thisHtml

                # Create proper DOM...
                html = settings.containerHtml.replace "[RESULTS]", html

                # Add backdrop if not there.
                top = inputField.offset().top + inputField.closest("div").height()
                right = $(".quotes_container").css("padding-right")
                position = 'absolute'
                if settings.showResultFixed
                    position = 'fixed'
                settings.container.css
                    position: position
                    top: top
                    right: right
                .fadeIn(settings.fadeSpeed).html html
                settings.backdrop.fadeIn settings.fadeSpeed
                
            # No items
            else
                settings.container.fadeout settings.fadeSpeed
                settings.container.fadeout settings.fadeSpeed


        # Instantiate the timout variable and lock this instance to a reference.
        requestTimeout    = null
        requestInProgress = false
        
        
        #
        # Perform request
        #
        runAjax = (query, inputField) ->
            return false if requestInProgress is true
            
            settings.ajaxData.searchTerm = query

            $.ajax
                url: settings.ajaxUrl
                type: settings.ajaxType
                async: true
                data: settings.ajaxData
                
                beforeSend: ->
                    requestInProgress = true

                success: (response) ->
                    if response.status is 0 and response.result.length > 0
                        attachList response.result, inputField

                error: (xhr, message, code) ->
                    console?.log message

                complete: ->
                    requestInProgress = false
                    requestTimeout = null
                
                
        #
        # Check if we should perform another AJAX-request.
        #
        evaluateAjax = (inputField) ->
            query = inputField.val()
            
            if query.length < settings.minLength
                settings.container.fadeOut settings.fadeSpeed
                settings.backdrop.fadeOut settings.fadeSpeed
                return false
            
            if requestTimeout is null
                requestTimeout = new Date().getTime()

            else if new Date().getTime() - requestTimeout < settings.requestWait
                return false
                
            runAjax query, inputField
            
            
        #
        # Perform action when clicking on an item in the built autocomplete
        # list.
        #
        $(document).on 'click', '.lwao_result li', ->
            return true
        
        
        #
        # Attach autocomplete to all inputs in set.
        #
        $(this).each ->
            $(this).on 'keyup', ->
                evaluateAjax $(this)
                
                
        #
        # Attach general closing events.
        #
        $("body").on 'click', ->
            settings.container.fadeOut settings.fadeSpeed
            settings.backdrop.fadeOut settings.fadeSpeed
        