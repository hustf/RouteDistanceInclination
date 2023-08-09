function _prepare_init_file_configuration(io)
    # Add a comment at top (IniFile.jl has no functions for comments)
    msg = """
        # Configuration file for 'RouteSlopeDistance'.
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
    set(conta, "http fields", "User agent", "RouteSlopeDistance.jl 0.0.1 temp_script")
    set(conta, "api server", "baseurl",  "https://nvdbapiles-v3.test.atlas.vegvesen.no/")
    set(conta, "http fields", "Accept", "application/vnd.vegvesen.nvdb-v3-rev2+json") # temp
    #

    ######
    # Link splits 
    ######
    # The key is from-to coordinates. The value is inserted coordinate.
    # Use https://nvdb-vegdata.github.io/nvdb-visrute/STM/ for finding 
    # new keys.
    # Notøy -> Røyra øst
    set(conta, "link split", "(19429 6943497)-(19922 6944583)", "20160 6944585")
    # Ulstein vgs. -> Støylesvingen
    set(conta, "link split", "(28961 6945248)-(28275 6945289)", "28684 6945112")
    # Botnen -> Garneskrysset. Merk at Garneskrysset etterpå blir erstattet av ny koordinat.
    # Utskrift fra test kan derfor ikke brukes direkte.
    set(conta, "link split", "(26807 6941534)-(26449 6940130)", "26141 6941016")
    # Røyra vest -> Frøystadvåg
    set(conta, "link split", "(19605 6944608)-(19495 6945400)", "19332 6945107")
    # Frøystadvåg -> Frøystadkrysset
    set(conta, "link split", "(19495 6945400)-(19646 6945703)", "19741 6945636")
    # 
    #########################
    # Coordinate replacements
    #########################
    # Merk at "In to" og "Out of" ikke gir alltid gir nok mening.
    # Ulsteinvik skysstasjon         Error: 4042  IKKE_FUNNET_SLUTTPUNKT 
    set(conta, "coordinates replacement", "In to 27262 6945774", "27265.47 6945717.35")
    set(conta, "coordinates replacement", "Out of 27262 6945774", "27223.99 6945781.04")
    # Garneskrysset 
    set(conta, "coordinates replacement", "In to 26449 6940130", "26537.51 6940226.53")
    # Fosnavåg terminal
    set(conta, "coordinates replacement", "In to 16064 6947515", "16047.98 6947536.24")
    set(conta, "coordinates replacement", "Out of 16064 6947515", "16074.87 6947499.33")
    #set(conta, "coordinates replacement", "Out of 36976 6947659",  "36947 6947667")
    #set(conta, "coordinates replacement", "In to 36976 6947659", "36990 6947639")


    # To file..
    println(io, conta)
end


"""
    get_config_value(sect::String, key::String)

Instead of passing long argument lists, we store configuration in a text file.
"""
function get_config_value(sect::String, key::String; nothing_if_not_found = false)
    fnam = _get_ini_fnam()
    ini = read(Inifile(), fnam)
    if sect ∉ keys(sections(ini))
        msg = """$sect not a section in $fnam. 
        The existing are: $(keys(sections(ini))).
        If you delete the .ini file above, a new template will be generated.
        """
        throw(ArgumentError(msg))
    end
    if nothing_if_not_found
        get(ini, sect, key,  nothing)
    else
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
            """))
        end
        s
    end
end
function get_config_value(sect, key, type::DataType; nothing_if_not_found = false) 
    st = get_config_value(sect, key; nothing_if_not_found)
    isnothing(st) && return nothing
    tryparse(type, st)
end

function get_config_value(sect, key, ::Type{Tuple{Float64, Float64}}; nothing_if_not_found = false)
    st = get_config_value(sect, key; nothing_if_not_found)
    isnothing(st) && return nothing
    (tryparse(Float64, split(st, ' ')[1]),     tryparse(Float64, split(st, ' ')[2]))
end 

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
_get_fnam_but_dont_create_file() =  joinpath(homedir(), "RouteSlopeDistance.ini")



"""
    coordinate_key(ingoing::Bool, ea, no)
    --> String

'no' is northing
'ea' is easting
'ingoin' = true: This point is fit for driving
in to this destination.
'ingoing' = false: Exit the origin here.

Often, the entry point to a route is different than
the exit point, and this matters to finding routes.

Prepare or look up entries for coordinate replacements.
This patches for status code 4041 and 4042.

One could make the value (the replacement) manually from
e.g. Norgeskart.
""" 
coordinate_key(ingoing::Bool, ea, no) = (ingoing ? "In to " : "Out of " ) * "$(Int(round(ea))) $(Int(round(no)))"

"""
    link_key(ea1, no1, ea2, no2)
    --> String

'no1' is northing start
'ea1' is easting start
'no2' is northing start
'ea2' is easting start

Prepare or look up entries for link splits.

One could make the value (the replacement) manually from
e.g. Norgeskart.   
"""
link_split_key(ea1, no1, ea2, no2) = "($(Int(round(ea1))) $(Int(round(no1))))-($(Int(round(ea2))) $(Int(round(no2))))"
