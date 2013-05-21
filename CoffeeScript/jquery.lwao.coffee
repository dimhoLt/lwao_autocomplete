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
            ajaxMethod: 'POST'
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
                '<li><span class="author">by %s</span><span class="quote">%s</span></li>'
                'authorName'
                'quote'
            ]
            container: $(".lwao_result")
            containerHtml:
                "<ul>\n" +
                "[RESULTS]" +
                "</ul>\n"
            selectionValue: 'qid'
            stringMaxLength: 50
            stringEllipsis: " ..."
            requestWait: 300
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
            
            html = ""
            for obj, index in result
                thisHtml = settings.resultDisplay[0]
                
                # A non-global regex will perform the matches one-by-one.
                for string, index in settings.resultDisplay
                    continue if index is 0
                    
                    replaceValue = obj[string]
                    if settings.stringMaxLength > 0
                        if replaceValue.length > settings.stringMaxLength + settings.stringEllipsis.length
                          replaceValue = replaceValue.substr(0, settings.stringMaxLength - settings.stringEllipsis.length) + settings.stringEllipsis
                         
                    thisHtml = thisHtml.replace "%s", replaceValue
                    
                html += thisHtml
            
            # Create proper DOM...
            html = settings.containerHtml.replace "[RESULTS]", html
            
            #$(".lwao_result").css
            #    top: $(this).offset().bottom # place at bottom of input element
            #    right: 0
            top = inputField.offset().top + inputField.height()
            right = -Math.abs(inputField.width())
            settings.container.show().html html


        # Instantiate the timout variable and lock this instance to a reference.
        requestTimeout = null
            
         
        #
        # Perform request
        #
        runAjax = (query, inputField) ->
            ret = {}
            settings.ajaxData.searchTerm = query

            $.ajax
                type: 'POST'
                url: '/ajax/search'
                async: true
                data: settings.ajaxData

                success: (response) ->
                    if response.status is 0 and response.result.length > 0
                        attachList response.result, inputField

                error: (xhr, message, code) ->
                    console?.log message

                complete: ->
                    requestTimeout = null
                
                
        #
        # Check if we should perform another AJAX-request.
        #
        evaluateAjax = (inputField) ->
            query = inputField.val()
            
            if query.length < settings.minLength
                settings.container.hide()
                return false
            
            if requestTimeout is null
                requestTimeout = new Date().getTime()

            else if new Date().getTime() - requestTimeout < settings.requestWait
                return false
                
            runAjax query, inputField
        
        
        #
        # Attach autocomplete.
        #
        $(this).each ->
            $(this).on 'keyup', ->
                evaluateAjax $(this)
                