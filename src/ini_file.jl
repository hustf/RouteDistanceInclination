# Also see 'exported.jl'.

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

    #############
    # Link splits 
    #############
    # The key is from-to coordinates. The value is inserted coordinate.
    # Use https://nvdb-vegdata.github.io/nvdb-visrute/STM/ for finding 
    # new keys. Function `link_split_key(ea1, no1, ea2, no2)` can be useful.
    #
    # You can edit the init file manually. If you revise here instead,
    # then do:
    #
    # julia> RouteSlopeDistance.delete_init_file()
    # Removed C:\Users\frohu_h4g8g6y\RouteSlopeDistance.ini
    #
    # Notøy <-> Røyra øst
    _add_link_split(conta, "(19429 6943497)-(19922 6944583)", "20160 6944585", also_reverse = true)
    # Ulstein vgs. <-> Støylesvingen
    _add_link_split(conta, "(28961 6945248)-(28275 6945289)", "28684 6945112", also_reverse = true)
    # Botnen <-> Garneskrysset. 
    _add_link_split(conta, "(26807 6941534)-(26449 6940130)", "26141 6941016", also_reverse = true)
    # Myrvåglomma <-> Myrvåg
    _add_link_split(conta, "(23911 6938921)-(23412 6939348)", "23732 6938944", also_reverse = true)
    # Røyra vest <-> Frøystadvåg
    _add_link_split(conta, "(19605 6944608)-(19495 6945400)", "19332 6945107", also_reverse = true)
    # Frøystadvåg <-> Frøystadkrysset
    _add_link_split(conta, "(19495 6945400)-(19646 6945703)", "19741 6945636", also_reverse = true)
    # Hareid ungdomsskule fv. 61 -> Hareid bussterminal
    _add_link_split(conta, "(36533 6947582)-(36976 6947659)", "36942 6947647", also_reverse = false)
    # Furene -> Hovdevatnet 
    _add_link_split(conta, "(34704 6925611)-(34518 6927170)", "34922 6925892", also_reverse = false)
    # Sørheim <-> Eiksundbrua
    _add_link_split(conta, "(32452 6930544)-(27963 6935576)", "28970 6931629", also_reverse = true)
    _add_link_split(conta, "(28970 6931629)-(27963 6935576)", "27809 6934212", also_reverse = true)
    # 
    #########################
    # Coordinate replacements
    #########################
    # Merk at "In to" og "Out of" ikke gir alltid gir nok mening.
    # Ulsteinvik skysstasjon         Error: 4042  IKKE_FUNNET_SLUTTPUNKT 
    set(conta, "coordinates replacement", "In to 27262 6945774", "27265 6945717")
    set(conta, "coordinates replacement", "Out of 27262 6945774", "27224 6945781")
    # Garneskrysset 
    set(conta, "coordinates replacement", "In to 26449 6940130", "26453 6940120")
    set(conta, "coordinates replacement", "Out of 26449 6940130", "26453 6940120")
    # Fosnavåg terminal
    set(conta, "coordinates replacement", "In to 16064 6947515", "16048 6947536")
    set(conta, "coordinates replacement", "Out of 16064 6947515", "16075 6947499")
    # Hareid bussterminal
    set(conta, "coordinates replacement", "Out of 36976 6947659",  "36947 6947667")
    set(conta, "coordinates replacement", "In to 36976 6947659", "36943 6947661")

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
function get_config_value(sect, key, ::Type{Tuple{Int64, Int64}}; nothing_if_not_found = false)
    st = get_config_value(sect, key; nothing_if_not_found)
    isnothing(st) && return nothing
    (tryparse(Int64, split(st, ' ')[1]),     tryparse(Int64, split(st, ' ')[2]))
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
    _add_link_split(conta, keypair::String, keycoordinate; also_reverse = false)
    ---> Vector{Float64}

# Example
```
julia> _add_link_split(conta, "(19429 6943497)-(19922 6944583)", "20160 6944585"; also_reverse = true)
```
"""
function _add_link_split(conta, keypair::String, keycoordinate::String; also_reverse = false)
    set(conta, "link split", keypair, keycoordinate)
    if also_reverse
        fromkey, tokey = split(keypair, '-')
        kpr = tokey * '-' * fromkey
        set(conta, "link split", kpr, keycoordinate)
    end
    nothing
end