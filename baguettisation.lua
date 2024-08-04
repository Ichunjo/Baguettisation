script_name = "Baguettisation"
script_description = "Remplace les tirets courts des dialogues en tirets longs et gère la marge auto"
script_version = "1.6"
script_author = "Vardë"


-- karaskel = require('karaskel')
include("karaskel.lua")

---@class Line
---@field start_time integer
---@field end_time integer
---@field duration number
---@field text string
---@field effect string
---@field style string
---@field margin_l integer

---@class Meta
---@field res_x integer|nil
---@field res_y integer|nil

---@class Style
---@field align integer
---@field name string

---@class Styles
---@field n integer
---@field [string] Style


TIRET = "–"
DEFAULT = "Default"
DEFAULT_ITA = "Italique"
DEFAULT_DIALOGUE = "TiretsDefault"
DEFAULT_DIALOGUE_ITA = "TiretsItalique"


---Split string s by delimiter
---@param self string
---@param delimiter string
---@return string[]
string.split = function(self, delimiter)
    local result = {}
    for match in (self .. delimiter):gmatch("(.-)" .. delimiter) do
        table.insert(result, match)
    end
    return result
end


---@param num number
---@param ndigits integer|nil
---@return number
local function round(num, ndigits)
    local mult = 10^(ndigits or 0)
    return math.floor(num * mult + 0.5) / mult
end


---@param gui table
---@param result_table table
local function save_config(gui, result_table)
    local bag_conf = "# Baguettisation Config\n\n"

    for _, val in ipairs(gui) do
        if val.class == "edit" or val.class == "dropdown" then
            bag_conf = bag_conf .. val.name .. "=" .. result_table[val.name] .. "\n"
        end
    end

    local path = aegisub.decode_path("?user") .."\\baguettetisation.conf"
    local file = io.open(path, "w")

    if file then
        file:write(bag_conf)
        file:close()
    end

    aegisub.dialog.display(
        {{class="label", label="Configuration sauvegardé à :\n" .. path}},
        {"OK"},
        {close="OK"}
    )
end


---@param gui table
local function load_config(gui)
    local path = aegisub.decode_path("?user") .."\\baguettetisation.conf"
    local file = io.open(path, "r")

    if file then
        ---@type string
        local bag_conf = file:read("*all")

        for _, val in ipairs(gui) do
            if val.class == "edit" or val.class == "dropdown" then
                if bag_conf:match(val.name) then
                    val.value = bag_conf:match(val.name .. "=(.-)\n")
                end
            end
        end
        io.close(file)
    end
end

---@param styles Styles
---@return table, table
local function gui_config(styles)
    ---@type string[]
    local styles_s = {}

    for _, value in ipairs(styles) do
        table.insert(styles_s, value.name)
    end

    local conf = {
        -- Label
        {
            class="label", label="Type de tiret :",
            x=0, y=0
        },
        {
            class="label", label="Nom du Default :",
            x=0, y=1
        },
        {
            class="label", label="Nom du Default italique :",
            x=0, y=2
        },
        {
            class="label", label="Nom du Default dialogue :",
            x=0, y=3
        },
        {
            class="label", label="Nom du Default italique dialogue :",
            x=0, y=4
        },

        -- User input
        {
            class="edit", name="tiret", value=TIRET,
            x=1, y=0
        },
        {
            class="dropdown", name="sn_default", value=DEFAULT,
            items=styles_s,
            x=1, y=1
        },
        {
            class="dropdown", name="sn_default_ita", value=DEFAULT_ITA,
            items=styles_s,
            x=1, y=2
        },
        {
            class="dropdown", name="sn_default_dia", value=DEFAULT_DIALOGUE,
            items=styles_s,
            x=1, y=3
        },
        {
            class="dropdown", name="sn_default_dia_ita", value=DEFAULT_DIALOGUE_ITA,
            items=styles_s,
            x=1, y=4
        },

        -- Save checkbox
        {
            class="checkbox", name="save", label="Sauvegarder configuration",
            x=5, y=5
        }
    }

    local buttons = {"OK", "Annuler"}

    return conf, buttons
end


---@param subs Line[]
---@param sel integer[]
---@param conf table
---@param meta Meta
---@param styles Styles
local function baguettetisation(subs, sel, conf, meta, styles)
    ---@type integer|nil, integer|nil, integer|nil, integer|nil
    local xres, _, _, _ = aegisub.video_size()
    video_x = meta.res_x or xres

    if not video_x then
        aegisub.log("Erreur : Définir la résolution d\'image au script ou ouvrir une vidéo !")
        aegisub.cancel()
    end

    for _, i in ipairs(sel) do
        local line = subs[i]

        -- Vérifications si CorrectPonc a déjà été utilisé
        if line.text:find("– ") then
            replace_space = true
        else
            replace_space = false
        end

        -- Réinitialisation des lignes
        line.text = line.text
        :gsub("–", "-")    -- Semi quadratin -> Tiret
        :gsub("—", "-")    -- Quadratin -> Tiret
        :gsub("- ", "- ")  -- Espace insécable fine -> Tiret
        :gsub("- ", conf.tiret .. " ")  -- 
        :gsub("-{", conf.tiret .. "{")  -- 
        :gsub("\\an8", "\\an7")
        :gsub("\\an2", "\\an1")

        local line_clean = line.text:gsub("{[^}]+}", "")

        -- Modifier si et seulement si la ligne commence par un tiret et contient un retour à la ligne suivi d'un 2e tiret 
        if line_clean:find("^–%s") and (line_clean:find("\\N–%s") or line_clean:find("\\N –%s")) then
            local split_line = line_clean:split("\\N")
            if split_line[2] then
                if split_line[1]:len() >= split_line[2]:len() then
                    longest_line = split_line[1]
                else
                    longest_line = split_line[2]
                end

                ---@type integer, integer, integer, integer
                local width, _, _, _ = aegisub.text_extents(styles[line.style], longest_line)
                line.margin_l = video_x / 2 - round(width / 2, 0)

                local style = styles[line.style]
                if style.align == 8 then
                    line.text = "{\\an7}" .. line.text
                    if line.style == conf.sn_default then
                        line.style = conf.sn_default_dia
                    elseif line.style == conf.sn_default_ita then
                        line.style = conf.sn_default_dia_ita
                    end
                elseif line.style == conf.sn_default_ita or line.style == conf.sn_default_dia_ita then
                    line.style = conf.sn_default_dia_ita
                else
                    line.style = conf.sn_default_dia
                end

                if replace_space then
                    line.text = line.text:gsub("– ", "– ")
                end

                subs[i] = line
            end
        end
    end
end


---@param subs Line[]
---@param sel integer[]
local function main(subs, sel)
    ---@type Meta, Styles
    local meta, styles = karaskel.collect_head(subs)

    local gui_conf, buttons = gui_config(styles)

    load_config(gui_conf)

    ---@type string, table
    local button, result_table = aegisub.dialog.display(gui_conf, buttons, {ok=buttons["OK"], cancel=buttons["Annuler"]})

    if button == "Annuler" then
        aegisub.cancel()
    end
    if result_table.save then
        save_config(gui_conf, result_table)
    end

    baguettetisation(subs, sel, result_table, meta, styles)
end

aegisub.register_macro(script_name, script_description, main)
