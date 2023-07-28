function _prepare_init_file_configuration(io)
    # Add a comment at top (IniFile.jl has no functions for comments)
    msg = """
        # Configuration file for 'RouteDistanceInclination'.
        # You can modify and save the values here. To start over from 'factory settings':
        # Delete this file. A new file will be created next time configurations are used.
        #
        # We don't know how general NVDB's API is, hence we put some values for adaption
        # to similar APIs in this init file. Feel free to experiment with other countries
        # or authorities (unless their licences says otherwise).
        #
        # The default base url is the dev environment, which may not always be available. 
        # Ref. https://nvdbapiles-v3.atlas.vegvesen.no/dokumentasjon/
        """
    println(io, msg)
    #
    conta = Inifile()
    # Lines in arbitrary order from file
    set(conta, "http fields", "User agent", "RouteDistanceInclination.jl 0.0.1 temp_script")
    set(conta, "api server", "baseurl", "https://nvdbapiles-v3.utv.atlas.vegvesen.no/")
    set(conta, "http fields", "Accept", "application/vnd.vegvesen.nvdb-v3-rev2+json")
    #
    println(io, conta)
end


"""
    get_config_value(sect::String, key::String)

Instead of passing long argument lists, we store configuration in a text file.
"""
function get_config_value(sect::String, key::String)
    fnam = _get_ini_fnam()
    ini = read(Inifile(), fnam)
    if sect ∉ keys(sections(ini))
        msg = """$sect not a section in $fnam. 
        The existing are: $(keys(sections(ini))).
        If you delete the .ini file above, a new template will be generated.
        """
        throw(ArgumentError(msg))
    end
    s = get(ini, sect, key,  "")
    if s == ""
        throw(ArgumentError("""
            $key not a key with value in section $sect of file $fnam. 
           
            Example:
            [user]                          # section  
            user_name     = slartibartfast  # key and value
            perceived_age = 5

            Current file:
            $ini

            We return an empty string
            """))
    end
    s
end
get_config_value(sect, key, type) = tryparse(type, get_config_value(sect, key))

"delete_init_file()"
function delete_init_file()
    fna = _get_fnam_but_dont_create_file()
    if isfile(fna) 
        rm(fna)
        println("Removed $fna")
    else
        println("$fna Didn't and doesn't exist.")
    end
end




"Get an existing, readable ini file name, create it if necessary"
function _get_ini_fnam()
    fna = _get_fnam_but_dont_create_file()
    if !isfile(fna)
        open(_prepare_init_file_configuration, fna, "w+")
        # Launch an editor
        if Sys.iswindows()
            run(`cmd /c $fna`; wait = false)
        end
        println("Default settings stored in $fna")
    end
    fna
end
_get_fnam_but_dont_create_file() =  joinpath(homedir(), "RouteDistanceInclination.ini")



