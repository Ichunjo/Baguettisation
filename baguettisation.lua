script_name = "Baguettisation"
script_description = "Remplace les tirets courts des dialogues en tirets longs et gère la marge auto"
script_version = "1.2"
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
		line.text = line.text:gsub("-", "–")
		if line.text:find("–%s") then
			cleantag = line.text:gsub("{[^}]+}", "")
			xsplit = split(cleantag, "\\N")
			if xsplit[2] ~= nil then
				if #xsplit[1] >= #xsplit[2] then
					lineLaPlusLongue = xsplit[1]
				else
					lineLaPlusLongue = xsplit[2]
				end

				width, height, descent, extlead = aegisub.text_extents(styles[line.style], lineLaPlusLongue)
				video_x, video_y = aegisub.video_size()

				line.margin_l = (video_x/2) - round((width/2),0)
				line.style = "Default - Dialogue"
				-- Le Default - Dialogue doit être en an1 !
				subs[i] = line
			end
		end
	end
end

function baguettetisation(subs, sel)
	dialogue(subs, sel, styles)
end

aegisub.register_macro(script_name,script_description,baguettetisation)
