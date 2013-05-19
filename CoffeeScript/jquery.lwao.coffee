###
 jQuery lwao 1.0
 
 Copyright (c) 2013 Helge Söderström
 http://github.com/dimhoLt
 
 Plugin website:
 http://github.com/dimhoLt/lwao_autocomplete
 
 Dual licensed under the MIT and GPL licenses.
 http://en.wikipedia.org/wiki/MIT_License
 http://en.wikipedia.org/wiki/GNU_General_Public_License
 
 Compile through: $ coffee -b -o js -c CoffeeScript/jquery.lwao.coffee
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
            displayString: [
                '<span class="quote">%</span></span class="author">by %s</span>'
                'quote'
                'authorName'
            ]
            selectionValue: 'qid'
            requestWait: 300
            debug: true
        
        # Merge default settings with options.
        settings = jQuery.extend settings, options

        # Simple logger.
        log = (msg) ->
            console?.log msg if settings.debug
            
        # Perform request
        runAjax = (query) ->
            return false if query < settings.minLength
            
            ret = {}
            settings.ajaxData.searchTerm = query

            $.ajax
                type: 'POST'
                url: '/ajax/search'
                async: true
                data: settings.ajaxData

                success: (response) ->
                    console.log response

                error: (xhr, message, code) ->
                    console.log message

                complete: ->
        
        # Instantiate the timout variable.
        requestTimeout = null

        # Attach autocomplete.
        $(this).each ->
            $(this).on 'keyup', ->
                clearTimeout requestTimeout if requestTimeout isnt null
                requestTimeout = setTimeout(runAjax($(this).val()), settings.requestWait)
                