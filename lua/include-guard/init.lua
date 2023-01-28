local M = {}

M.opts = {}

function M.setup(opts)
	M.opts = opts or {}
	M.opts.copyright_holder = opts.copyright_holder or ""
	M.opts.add_copyright = opts.add_copyright or true
end

function M.UpdateCopyright()
  local pos = vim.fn.search("^// Copyright.*", "n") - 1
	local copyright_string = "// Copyright "
		.. os.date("%Y")
		.. " "
		.. M.opts.copyright_holder
		.. ". All Rights Reserved."
  vim.api.nvim_buf_set_lines(0, pos, pos + 1, false, { copyright_string })
end

local function AddCopyright()
	local copyright_prefix = "// Copyright"
	local copyright_string = "// Copyright "
		.. os.date("%Y")
		.. " "
		.. M.opts.copyright_holder
		.. ". All Rights Reserved."
	local first_line = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1]
	local has_copyright = first_line:find(copyright_prefix, 1, true) == 1
	if not has_copyright then
		vim.api.nvim_buf_set_lines(0, 0, 0, true, { copyright_string })
	end
end

-- Returns the command calling cpplint to get the correct header guard string
local function cpplint_cmd(file_path)
	return {
		"python3",
		"-c",
		'from cpplint import GetHeaderGuardCPPVariable; print(GetHeaderGuardCPPVariable("' .. file_path .. '"))',
	}
end

-- starts an async job can calling a function that takes the generated_guard_string as an argument to alter
-- the current buffer.
local function replace_job(file_path, callback_function)
	vim.fn.jobstart(cpplint_cmd(file_path), {
		stdout_buffered = true,
		on_stdout = function(_, data)
			callback_function(data[1])
		end,
	})
end

local function _AddIncludeGuard(define_line_pos)
	local generated_guard_string = ""
	-- Some header files contain an include guard, but they might have the wrong one. We assume the first #define being
	-- the include-header-guard.
	local guard_line_pos = vim.fn.search("^#ifndef \\w*", "n")
	local existing_guard_name = nil
	if guard_line_pos ~= 0 then
		existing_guard_name = vim.fn.matchlist(vim.fn.getline(guard_line_pos), "^#ifndef \\(\\w*\\)")[2]
	end

	local file_path = vim.api.nvim_buf_get_name(0)
	if existing_guard_name == nil then
		replace_job(file_path, function(generated_guard_string)
			vim.api.nvim_buf_set_lines(
				0,
				define_line_pos,
				define_line_pos,
				true,
				{ "#ifndef " .. generated_guard_string, "#define " .. generated_guard_string }
			)
			vim.api.nvim_buf_set_lines(0, -1, -1, true, { "#endif  //  " .. generated_guard_string })
		end)
	else
		replace_job(file_path, function(generated_guard_string)
			if generated_guard_string ~= existing_guard_name then
				local pos = vim.fn.search("^#ifndef\\s*" .. existing_guard_name, "n") - 1
				vim.api.nvim_buf_set_lines(0, pos, pos + 1, false, { "#ifndef " .. generated_guard_string })
				pos = vim.fn.search("^#define\\s*" .. existing_guard_name, "n") - 1
				vim.api.nvim_buf_set_lines(0, pos, pos + 1, false, { "#define " .. generated_guard_string })
				pos = vim.fn.search("^#endif\\s*//.*" .. existing_guard_name, "n") - 1
				vim.api.nvim_buf_set_lines(0, pos, pos + 1, false, { "#endif  //  " .. generated_guard_string })
			end
		end)
	end
end

function M.AddIncludeGuardAndCopyright()
	-- line number where the include guard should be placed. If there is a copyright notice, it would be the
	-- second line.
	local define_line_pos = 0
	if M.opts.add_copyright then
		AddCopyright()
		define_line_pos = 1
	end

	_AddIncludeGuard(define_line_pos)
end
function M.AddIncludeGuard()
	-- line number where the include guard should be placed. If there is a copyright notice, it would be the
	-- second line.
	local define_line_pos = 0
	if M.opts.add_copyright then
		define_line_pos = 1
	end

	_AddIncludeGuard(define_line_pos)
end

return M
