-- in templar.lua

local templates_dir = vim.fn.stdpath("config") .. "/templates"

local templates = vim.fn.readdir(templates_dir)

local function parse_field(field, values)
	local value
	if string.match(field, "^%d+$") then
		value = values[tonumber(field)]
	else
		value = vim.fn.luaeval(field)
		values[#values] = value
	end

	return value
end

local function parse_template(file)
	-- Get content of the template
	local filename = vim.fn.expand(file)
	local lines = vim.fn.readfile(filename)

	-- Content of the future file
	local evaluated = {}
	local actual_cursor = vim.api.nvim_win_get_cursor(0)
	local future_cursor = nil
	local values = {}

	for index, line in ipairs(lines) do
		local tag = vim.fn.matchstr(line, "%{\\zs.\\+\\ze%}")

		if not tag or tag:len() == 0 then
			evaluated[index] = line
		elseif tag == "CURSOR" then
			future_cursor = { actual_cursor[1] + index - 1, line:find("CURSOR") - 3 }
			evaluated[index] = line:gsub("%%{.+%%}", "")
		elseif tag:match("INCLUDE %g+") then
			-- Special INCLUDE tag
			-- Includes the content of a template into current
			local fname = vim.fn.matchstr(tag, "INCLUDE \\zs\\f*\\ze")
			local path = vim.fn.fnamemodify(filename, ":p:h") .. "/" .. fname

			local _, output = parse_template(path)

			vim.list_extend(evaluated, output)
		else
			evaluated[index] = line:gsub("%%{.+%%}", parse_field(tag, values))
		end
	end
	future_cursor = future_cursor or actual_cursor
	return future_cursor, evaluated
end

local function use_template(file)
	local cursor, lines = parse_template(file)
	vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
	vim.api.nvim_win_set_cursor(0, cursor)
end

-- searches the correct template for the current file
local function search_template()
	local curfile_ext = vim.fn.expand("%:e")

	for _, template in ipairs(templates) do
	  local template_ext = vim.split(template, ".", { plain = true })[2]
		if curfile_ext == template_ext then
			local files = vim.api.nvim_get_runtime_file("templates/" .. template, false)
			return files[1]
		end
	end

	return nil
end

local function source()
	local template_file = search_template()

	if template_file then
		use_template(template_file)
	end
end

return {
	source = source,
}
