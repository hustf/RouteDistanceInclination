# Ref. https://nvdbapiles-v3.atlas.vegvesen.no/dokumentasjon/openapi/#/Vegnett/get_beta_vegnett_rute

"""
    nvdb_request(url_ext::String, method::String= "GET"; 
                    body = "", logstate = LOGSTATE)
     -> (r::JSON3.Object, retry_in_seconds::Int)

Access the nvdb Web API. This is called by every function 
in `/by_console_doc/` and `/by_reference_doc/`.
Error results return an empty Object. 
Errors are written to 'stderr', expect for 'API rate limit exceeded', as 
the output would typically occur in the middle of recursive calls.
"""
function nvdb_request(url_ext::String, method::String = "GET"; body = "",
    logstate = LOGSTATE)
    if method == "PUT" || method == "DELETE" || method == "POST"
        # Some requests include a body, some don't!
    else
        @assert body == "" "No need to define body for other than a 'POST' request!"
    end
    # Not so cool, but this is how we get rid of spaces in vectors of strings:
    url_ext = replace(url_ext, ' ' => "")
    url = "$BASEURL$url_ext"
    idfields = get_nvdb_fields()
    # A template in case we don't get a response from HTTP.
    resp = HTTP.Messages.Response()
    try
        if method == "GET"
            resp = HTTP.request(method, url, idfields)
        elseif method == "POST" || method == "PUT" || method == "DELETE"
            resp = HTTP.request(method, url, idfields, body)
        else
            throw("unexpected method")
        end
        # Since execution did not skip to 'catch', this request was OK. Log the successfull request.
        request_to_stdout(method, url, body, idfields, logstate, true)
    catch e
        error_logstate = Logstate(logstate.authorization, true, logstate.empty_response)
        request_to_stdout(method, url, body, idfields, error_logstate, false)
        if  e isa HTTP.ExceptionRequest.StatusError && e.status ∈ keys(RESP_DIC) #[400, 401, 403, 404, 429]
            response_body = e.response.body |> String
            code_meaning = get(RESP_DIC, Int(e.status), "")
            if response_body != ""
                response_object = JSON3.read(response_body)
                response_message = response_object.error.message
                msg = "$(e.status) (code meaning): $code_meaning \n\t\t(response message): $response_message"
            else
                msg = "$(e.status): $code_meaning"
            end
            @info msg
            if e.status == 400  # e.g. when a search query is empty
                return JSON3.Object(), 0
            elseif e.status == 403
                printstyled("  This message may have been triggered by insufficient identification.\n", color = :red)
                logstate.authorization && printstyled("               id fields: ", idfields, "\n", color = :red)
                return JSON3.Object(), 0
            elseif e.status == 404 # Not found.
                return JSON3.Object(), 0
            elseif e.status == 405 
                return JSON3.Object(), 0
            elseif e.status == 429 # API rate limit temporarily exceeded.
                retry_in_seconds =  HTTP.header(e.response, "retry-after") 
                return JSON3.Object(), parse(Int, retry_in_seconds)
            else # 401 probably
                @warn "Error code $(e.status)."
                return JSON3.Object(), 0
            end
        else
            msg = "HTTP.request call (unexpected error): method = $method\n header with identification fields = $idfields \n $url_ext"
            @warn msg
            if e isa HTTP.Exceptions.ConnectError
                @error string(e.url)
                @error string(e.error)
                return JSON3.Object(), 0
            else
                response_body = e.response.body |> String
                code_meaning = "?"
                msg = "$(e.status): $code_meaning"
                @error msg
                @error string(e)
                return JSON3.Object(), 0
            end
        end
    end
    response_body = resp.body |> String
    if method == "PUT" || method == "DELETE"
        if response_body == "" && resp.status ∈ [200, 201, 202, 203, 204]
            return JSON3.Object(), 0
        elseif resp.status ∈ [200, 201, 202, 203, 204]
            return JSON3.read(response_body), 0
        else
            code_meaning = get(RESP_DIC, Int(resp.status), "")
            msg = "$(resp.status): $code_meaning"
            @info msg
            return JSON3.Object(), 0
        end
    else
        if resp.status == 204
            if logstate.empty_response
                code_meaning = get(RESP_DIC, Int(resp.status), "")
                msg = "$(resp.status): $code_meaning"
                @info msg
            end
            return JSON3.Object(), 0
        else
            return JSON3.read(response_body), 0
        end
    end
end


"""
    request_to_stdout(method, url, body, idfields, logstate, no_mistake)

Print a request after it is made.
"""
function request_to_stdout(method, url, body, idfields, logstate, no_mistake)
    if no_mistake
        color = :light_black
    else
        color = :red
    end
    if logstate.request_string
        if body == ""
            printstyled("     ", method, " ", url, "\n"; color)
        else
            printstyled("     ", method, " ", url, "   \\", body, "\n"; color)
        end
    end
    # We want to be able to reuse console output for examples, so hiding confidential output is a choice:
    if logstate.authorization
        printstyled("               identification fields: ", idfields, "\n"; color)
    end
end