script_name = "Baguettisation"
script_description = "Remplace les tirets courts des dialogues en tirets longs et gère la marge auto"
script_version = "1.544"
script_author = "Vardë"
scrip_updated_by="slykhy"

include("karaskel.lua")

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
    meta = karaskel.collect_head(subs)
    
    -- 384x288 est défini par défaut pour certaines versions Aegisub
    if meta.res_x ~= 0 and meta.res_y ~= 0 and meta.res_x ~= 384 and meta.res_y ~= 288 then
        video_x = meta.res_x
        video_y = meta.res_y
    else
        aegisub.log("Erreur : Définir la résolution d\'image au script ou ouvrir une vidéo !")
        return
    end

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

         -- Réinitialisation des tirets
        line.text = line.text:gsub("–", "-"):gsub("—", "-"):gsub("- ", "- "):gsub("- ", "– "):gsub("-{", "–{"):gsub("\\an8", "\\an7")

        cleantag = line.text:gsub("{[^}]+}", "")

        -- Modifier si et seulement si la ligne commence par un tiret et contient un retour à la ligne suivi d'un 2e tiret 
        if cleantag:find("^–%s") and (cleantag:find("\\N–%s") or cleantag:find("\\N –%s")) then
            split_line = split(cleantag, "\\N")
            if split_line[2] ~= nil then
                if #split_line[1] >= #split_line[2] then
                    longest_line = split_line[1]
                else
                    longest_line = split_line[2]
                end

                width = aegisub.text_extents(styles[line.style], longest_line)
                line.margin_l = video_x / 2 - round(width / 2, 0)

                -- Adapté aux styles de CR
                if styles[line.style].align == 8 and line.style == "Italique" then
                    line.text = "{\\an7}" .. line.text
                    line.style = "TiretsItalique"
                elseif styles[line.style].align == 8 and line.style == "Default" then
                    line.text = "{\\an7}" .. line.text
                    line.style = "TiretsDefault"
                elseif line.style == "Italique" or line.style == "TiretsItalique" then
                    line.style = "TiretsItalique"
                else
                    line.style = "TiretsDefault"
                end

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

aegisub.register_macro(script_name, script_description, baguettetisation)
