local M = {}

local copyright_holder = ""

function M.setup(copyright_holder_)
	copyright_holder = copyright_holder_
end

function M.AddIncludeGuard()
	local file_path = vim.api.nvim_buf_get_name(0)

	local copyright_prefix = "// Copyright"
	local header_guard_prefix = "#ifndef"
	local copyright_string = "// Copyright " .. os.date("%Y") .. " " .. copyright_holder .. ". All Rights Reserved."
	local first_line = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1]
	local has_copyright = first_line:find(copyright_prefix, 1, true) == 1
	if not has_copyright then
		vim.api.nvim_buf_set_lines(0, 0, 0, true, { copyright_string })
	end
	local second_line = vim.api.nvim_buf_get_lines(0, 1, 2, false)[1]
	local has_header_guard = second_line:find(header_guard_prefix, 1, true) == 1
	if not has_header_guard then
		vim.fn.jobstart({
			"python3",
			"-c",
			'from cpplint import GetHeaderGuardCPPVariable; print(GetHeaderGuardCPPVariable("' .. file_path .. '"))',
		}, {
			stdout_buffered = true,
			on_stdout = function(_, data)
				local header_guard_string = data[1]
				print(vim.inspect(header_guard_string))
				vim.api.nvim_buf_set_lines(0, 1, 1, true, { "#define " .. header_guard_string })
				vim.api.nvim_buf_set_lines(0, 1, 1, true, { "#ifndef " .. header_guard_string })
				vim.api.nvim_buf_set_lines(0, -1, -1, true, { "#endif  //  " .. header_guard_string })
			end,
		})
	end
end

M.setup("")


return M
