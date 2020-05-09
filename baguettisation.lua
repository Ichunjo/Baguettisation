script_name = "Baguettisation"
script_description = "Remplace les tirets courts des dialogues en tirets longs et gère la marge auto"
script_version = "1.4"
script_author="Vardë"

function split(s, delimiter)
    result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

function round(num, numDecimalPlaces) 
    mult = 10^(numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

function dialogue(subs, sel, styles)
    styles = { n = 0 }
    for i, l in ipairs(subs) do
        if l.class == "style" then
            styles.n = styles.n + 1
            styles[styles.n] = l
            styles[l.name] = l
            l.margin_v = l.margin_t
        end
    end

    for k, i in ipairs(sel) do
        line = subs[i]

        -- Vérifications si CorrectPonc a déjà été utilisé
        if line.text:find("– ") ~= nil then 
            replace_space = true
        else
            replace_space = false
        end

        -- Réinitialisation des lignes
        line.text = line.text:gsub("–", "-") -- Semi quadratin
        line.text = line.text:gsub("—", "-") -- Quadratin
        line.text = line.text:gsub("- ", "- ") -- Espace insécable fine
        
        if string.sub(line.text, 1, 2) == "- " then
            line.text = line.text:gsub("- ", "– ")
            cleantag = line.text:gsub("{[^}]+}", "")
            split_line = split(cleantag, "\\N")
            if split_line[2] ~= nil then
                if #split_line[1] >= #split_line[2] then
                    longest_line = split_line[1]
                else
                    longest_line = split_line[2]
                end

                width, height, descent, extlead = aegisub.text_extents(styles[line.style], longest_line)
                video_x, video_y = aegisub.video_size()

                line.margin_l = video_x / 2 - round(width / 2, 0)
                line.style = "Default - Dialogue"
                -- Le Default - Dialogue doit être en an1 !

                if replace_space then
                    line.text = line.text:gsub("– ", "– ")
                end

                subs[i] = line
            end
        end
    end
end

function baguettetisation(subs, sel)
    dialogue(subs, sel, styles)
end

aegisub.register_macro(script_name,script_description,baguettetisation)
