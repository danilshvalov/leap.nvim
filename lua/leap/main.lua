local hl = require("leap.highlight")
local opts = require("leap.opts")
local api = vim.api
local empty_3f = vim.tbl_isempty
local filter = vim.tbl_filter
local map = vim.tbl_map
local _local_1_ = math
local abs = _local_1_["abs"]
local ceil = _local_1_["ceil"]
local max = _local_1_["max"]
local min = _local_1_["min"]
local pow = _local_1_["pow"]
local function inc(x)
  return (x + 1)
end
local function dec(x)
  return (x - 1)
end
local function clamp(x, min0, max0)
  if (x < min0) then
    return min0
  elseif (x > max0) then
    return max0
  else
    return x
  end
end
local function echo(msg)
  return api.nvim_echo({{msg}}, false, {})
end
local function replace_keycodes(s)
  return api.nvim_replace_termcodes(s, true, false, true)
end
local function get_cursor_pos()
  return {vim.fn.line("."), vim.fn.col(".")}
end
local function char_at_pos(_3_, _5_)
  local _arg_4_ = _3_
  local line = _arg_4_[1]
  local byte_col = _arg_4_[2]
  local _arg_6_ = _5_
  local char_offset = _arg_6_["char-offset"]
  local line_str = vim.fn.getline(line)
  local char_idx = vim.fn.charidx(line_str, dec(byte_col))
  local char_nr = vim.fn.strgetchar(line_str, (char_idx + (char_offset or 0)))
  if (char_nr ~= -1) then
    return vim.fn.nr2char(char_nr)
  else
    return nil
  end
end
local function user_forced_autojump_3f()
  return (not opts.labels or empty_3f(opts.labels))
end
local function user_forced_noautojump_3f()
  return (not opts.safe_labels or empty_3f(opts.safe_labels))
end
local function echo_no_prev_search()
  return echo("no previous search")
end
local function echo_not_found(s)
  return echo(("not found: " .. s))
end
local function push_cursor_21(direction)
  local function _9_()
    local _8_ = direction
    if (_8_ == "fwd") then
      return "W"
    elseif (_8_ == "bwd") then
      return "bW"
    else
      return nil
    end
  end
  return vim.fn.search("\\_.", _9_())
end
local function cursor_before_eol_3f()
  return (vim.fn.search("\\_.", "Wn") ~= vim.fn.line("."))
end
local function cursor_before_eof_3f()
  return ((vim.fn.line(".") == vim.fn.line("$")) and (vim.fn.virtcol(".") == dec(vim.fn.virtcol("$"))))
end
local function add_offset_21(offset)
  if (offset < 0) then
    return push_cursor_21("bwd")
  elseif (offset > 0) then
    if not cursor_before_eol_3f() then
      push_cursor_21("fwd")
    else
    end
    if (offset > 1) then
      return push_cursor_21("fwd")
    else
      return nil
    end
  else
    return nil
  end
end
local function push_beyond_eof_21()
  local saved = vim.o.virtualedit
  vim.o.virtualedit = "onemore"
  vim.cmd("norm! l")
  local function _14_()
    vim.o.virtualedit = saved
    return nil
  end
  return api.nvim_create_autocmd({"CursorMoved", "WinLeave", "BufLeave", "InsertEnter", "CmdlineEnter", "CmdwinEnter"}, {callback = _14_, once = true})
end
local function simulate_inclusive_op_21(mode)
  local _15_ = vim.fn.matchstr(mode, "^no\\zs.")
  if (_15_ == "") then
    if cursor_before_eof_3f() then
      return push_beyond_eof_21()
    else
      return push_cursor_21("fwd")
    end
  elseif (_15_ == "v") then
    return push_cursor_21("bwd")
  else
    return nil
  end
end
local function force_matchparen_refresh()
  pcall(api.nvim_exec_autocmds, "CursorMoved", {group = "matchparen"})
  return pcall(api.nvim_exec_autocmds, "CursorMoved", {group = "matchup_matchparen"})
end
local function jump_to_21_2a(pos, _18_)
  local _arg_19_ = _18_
  local winid = _arg_19_["winid"]
  local add_to_jumplist_3f = _arg_19_["add-to-jumplist?"]
  local mode = _arg_19_["mode"]
  local offset = _arg_19_["offset"]
  local backward_3f = _arg_19_["backward?"]
  local inclusive_op_3f = _arg_19_["inclusive-op?"]
  local op_mode_3f = mode:match("o")
  if add_to_jumplist_3f then
    vim.cmd("norm! m`")
  else
  end
  if (winid ~= vim.fn.win_getid()) then
    api.nvim_set_current_win(winid)
  else
  end
  vim.fn.cursor(pos)
  if offset then
    add_offset_21(offset)
  else
  end
  if (op_mode_3f and inclusive_op_3f and not backward_3f) then
    simulate_inclusive_op_21(mode)
  else
  end
  if not op_mode_3f then
    return force_matchparen_refresh()
  else
    return nil
  end
end
local function highlight_cursor(_3fpos)
  local _let_25_ = (_3fpos or get_cursor_pos())
  local line = _let_25_[1]
  local col = _let_25_[2]
  local pos = _let_25_
  local ch_at_curpos = (char_at_pos(pos, {}) or " ")
  return api.nvim_buf_set_extmark(0, hl.ns, dec(line), dec(col), {virt_text = {{ch_at_curpos, "Cursor"}}, virt_text_pos = "overlay", hl_mode = "combine", priority = hl.priority.cursor})
end
local function handle_interrupted_change_op_21()
  local seq
  local function _26_()
    if (vim.fn.col(".") > 1) then
      return "<RIGHT>"
    else
      return ""
    end
  end
  seq = ("<C-\\><C-G>" .. _26_())
  return api.nvim_feedkeys(replace_keycodes(seq), "n", true)
end
local function exec_user_autocmds(pattern)
  return api.nvim_exec_autocmds("User", {pattern = pattern, modeline = false})
end
local function get_input()
  local ok_3f, ch = pcall(vim.fn.getcharstr)
  if (ok_3f and (ch ~= replace_keycodes("<esc>"))) then
    return ch
  else
    return nil
  end
end
local function get_input_by_keymap()
  local input = get_input()
  if (vim.bo.iminsert == 1) then
    local converted = vim.fn.mapcheck(input, "l")
    if (#converted > 0) then
      input = converted
    else
    end
  else
  end
  return input
end
local function set_dot_repeat()
  local op = vim.v.operator
  local cmd = replace_keycodes("<cmd>lua require'leap'.leap {['dot-repeat?'] = true}<cr>")
  local change
  if (op == "c") then
    change = replace_keycodes("<c-r>.<esc>")
  else
    change = nil
  end
  local seq = (op .. cmd .. (change or ""))
  pcall(vim.fn["repeat#setreg"], seq, vim.v.register)
  return pcall(vim.fn["repeat#set"], seq, -1)
end
local function get_other_windows_on_tabpage(mode)
  local wins = api.nvim_tabpage_list_wins(0)
  local curr_win = api.nvim_get_current_win()
  local curr_buf = api.nvim_get_current_buf()
  local visual_7cop_mode_3f = (mode ~= "n")
  local function _31_(_241)
    return ((api.nvim_win_get_config(_241)).focusable and (_241 ~= curr_win) and not (visual_7cop_mode_3f and (api.nvim_win_get_buf(_241) ~= curr_buf)))
  end
  return filter(_31_, wins)
end
local function get_horizontal_bounds()
  local match_length = 2
  local textoff = vim.fn.getwininfo(vim.fn.win_getid())[1].textoff
  local offset_in_win = dec(vim.fn.wincol())
  local offset_in_editable_win = (offset_in_win - textoff)
  local left_bound = (vim.fn.virtcol(".") - offset_in_editable_win)
  local window_width = api.nvim_win_get_width(0)
  local right_edge = (left_bound + dec((window_width - textoff)))
  local right_bound = (right_edge - dec(match_length))
  return {left_bound, right_bound}
end
local function skip_one_21(backward_3f)
  local new_line
  local function _32_()
    if backward_3f then
      return "bwd"
    else
      return "fwd"
    end
  end
  new_line = push_cursor_21(_32_())
  if (new_line == 0) then
    return "dead-end"
  else
    return nil
  end
end
local function to_closed_fold_edge_21(backward_3f)
  local edge_line
  local _34_
  if backward_3f then
    _34_ = vim.fn.foldclosed
  else
    _34_ = vim.fn.foldclosedend
  end
  edge_line = _34_(vim.fn.line("."))
  vim.fn.cursor(edge_line, 0)
  local edge_col
  if backward_3f then
    edge_col = 1
  else
    edge_col = vim.fn.col("$")
  end
  return vim.fn.cursor(0, edge_col)
end
local function reach_right_bound_21(right_bound)
  while ((vim.fn.virtcol(".") < right_bound) and not (vim.fn.col(".") >= dec(vim.fn.col("$")))) do
    vim.cmd("norm! l")
  end
  return nil
end
local function to_next_in_window_pos_21(backward_3f, left_bound, right_bound, stopline)
  local _let_37_ = {vim.fn.line("."), vim.fn.virtcol(".")}
  local line = _let_37_[1]
  local virtcol = _let_37_[2]
  local from_pos = _let_37_
  local left_off_3f = (virtcol < left_bound)
  local right_off_3f = (virtcol > right_bound)
  local _38_
  if (left_off_3f and backward_3f) then
    if (dec(line) >= stopline) then
      _38_ = {dec(line), right_bound}
    else
      _38_ = nil
    end
  elseif (left_off_3f and not backward_3f) then
    _38_ = {line, left_bound}
  elseif (right_off_3f and backward_3f) then
    _38_ = {line, right_bound}
  elseif (right_off_3f and not backward_3f) then
    if (inc(line) <= stopline) then
      _38_ = {inc(line), left_bound}
    else
      _38_ = nil
    end
  else
    _38_ = nil
  end
  if (nil ~= _38_) then
    local to_pos = _38_
    if (from_pos == to_pos) then
      return "dead-end"
    else
      vim.fn.cursor(to_pos)
      if backward_3f then
        return reach_right_bound_21(right_bound)
      else
        return nil
      end
    end
  else
    return nil
  end
end
local function get_match_positions(pattern, _45_, _47_)
  local _arg_46_ = _45_
  local left_bound = _arg_46_[1]
  local right_bound = _arg_46_[2]
  local _arg_48_ = _47_
  local backward_3f = _arg_48_["backward?"]
  local whole_window_3f = _arg_48_["whole-window?"]
  local skip_curpos_3f = _arg_48_["skip-curpos?"]
  local skip_orig_curpos_3f = skip_curpos_3f
  local _let_49_ = get_cursor_pos()
  local orig_curline = _let_49_[1]
  local orig_curcol = _let_49_[2]
  local wintop = vim.fn.line("w0")
  local winbot = vim.fn.line("w$")
  local stopline
  if backward_3f then
    stopline = wintop
  else
    stopline = winbot
  end
  local saved_view = vim.fn.winsaveview()
  local saved_cpo = vim.o.cpo
  local cleanup
  local function _51_()
    vim.fn.winrestview(saved_view)
    vim.o.cpo = saved_cpo
    return nil
  end
  cleanup = _51_
  vim.o.cpo = (vim.o.cpo):gsub("c", "")
  local match_count = 0
  local moved_to_topleft_3f
  if whole_window_3f then
    vim.fn.cursor({wintop, left_bound})
    moved_to_topleft_3f = true
  else
    moved_to_topleft_3f = nil
  end
  local function iter(match_at_curpos_3f)
    local match_at_curpos_3f0 = (match_at_curpos_3f or moved_to_topleft_3f)
    local flags
    local function _53_()
      if backward_3f then
        return "b"
      else
        return ""
      end
    end
    local function _54_()
      if match_at_curpos_3f0 then
        return "c"
      else
        return ""
      end
    end
    flags = (_53_() .. _54_())
    moved_to_topleft_3f = false
    local _55_ = vim.fn.searchpos(pattern, flags, stopline)
    if ((_G.type(_55_) == "table") and (nil ~= (_55_)[1]) and (nil ~= (_55_)[2])) then
      local line = (_55_)[1]
      local col = (_55_)[2]
      local pos = _55_
      if (line == 0) then
        return cleanup()
      elseif ((line == orig_curline) and (col == orig_curcol) and skip_orig_curpos_3f) then
        local _56_ = skip_one_21()
        if (_56_ == "dead-end") then
          return cleanup()
        elseif true then
          local _ = _56_
          return iter(true)
        else
          return nil
        end
      elseif ((col < left_bound) and (col > right_bound) and not vim.wo.wrap) then
        local _58_ = to_next_in_window_pos_21(backward_3f, left_bound, right_bound, stopline)
        if (_58_ == "dead-end") then
          return cleanup()
        elseif true then
          local _ = _58_
          return iter(true)
        else
          return nil
        end
      elseif (vim.fn.foldclosed(line) ~= -1) then
        to_closed_fold_edge_21(backward_3f)
        local _60_ = skip_one_21(backward_3f)
        if (_60_ == "dead-end") then
          return cleanup()
        elseif true then
          local _ = _60_
          return iter(true)
        else
          return nil
        end
      else
        match_count = (match_count + 1)
        return pos
      end
    else
      return nil
    end
  end
  return iter
end
local function get_targets_2a(pattern, _64_)
  local _arg_65_ = _64_
  local backward_3f = _arg_65_["backward?"]
  local wininfo = _arg_65_["wininfo"]
  local targets = _arg_65_["targets"]
  local source_winid = _arg_65_["source-winid"]
  local targets0 = (targets or {})
  local _let_66_ = get_horizontal_bounds()
  local _ = _let_66_[1]
  local right_bound = _let_66_[2]
  local bounds = _let_66_
  local whole_window_3f = wininfo
  local wininfo0 = (wininfo or vim.fn.getwininfo(vim.fn.win_getid())[1])
  local skip_curpos_3f = (whole_window_3f and (vim.fn.win_getid() == source_winid))
  local match_positions = get_match_positions(pattern, bounds, {["backward?"] = backward_3f, ["skip-curpos?"] = skip_curpos_3f, ["whole-window?"] = whole_window_3f})
  local prev_match = {}
  for _67_ in match_positions do
    local _each_68_ = _67_
    local line = _each_68_[1]
    local col = _each_68_[2]
    local pos = _each_68_
    local ch1 = char_at_pos(pos, {})
    local ch2, eol_3f = nil, nil
    do
      local _69_ = char_at_pos(pos, {["char-offset"] = 1})
      if (nil ~= _69_) then
        local char = _69_
        ch2, eol_3f = char
      elseif true then
        local _0 = _69_
        ch2, eol_3f = replace_keycodes(opts.special_keys.eol), true
      else
        ch2, eol_3f = nil
      end
    end
    local same_char_triplet_3f
    local _71_
    if backward_3f then
      _71_ = dec
    else
      _71_ = inc
    end
    same_char_triplet_3f = ((ch2 == prev_match.ch2) and (line == prev_match.line) and (col == _71_(prev_match.col)))
    prev_match = {line = line, col = col, ch2 = ch2}
    if not same_char_triplet_3f then
      table.insert(targets0, {wininfo = wininfo0, pos = pos, pair = {ch1, ch2}, ["edge-pos?"] = (eol_3f or (col == right_bound))})
    else
    end
  end
  if next(targets0) then
    return targets0
  else
    return nil
  end
end
local function distance(_75_, _77_)
  local _arg_76_ = _75_
  local l1 = _arg_76_[1]
  local c1 = _arg_76_[2]
  local _arg_78_ = _77_
  local l2 = _arg_78_[1]
  local c2 = _arg_78_[2]
  local editor_grid_aspect_ratio = 0.3
  local _let_79_ = {abs((c1 - c2)), abs((l1 - l2))}
  local dx = _let_79_[1]
  local dy = _let_79_[2]
  local dx0 = (dx * editor_grid_aspect_ratio)
  return pow((pow(dx0, 2) + pow(dy, 2)), 0.5)
end
local function get_targets(pattern, _80_)
  local _arg_81_ = _80_
  local backward_3f = _arg_81_["backward?"]
  local target_windows = _arg_81_["target-windows"]
  if not target_windows then
    return get_targets_2a(pattern, {["backward?"] = backward_3f})
  else
    local targets = {}
    local cursor_positions = {}
    local source_winid = vim.fn.win_getid()
    local curr_win_only_3f
    do
      local _82_ = target_windows
      if ((_G.type(_82_) == "table") and ((_G.type((_82_)[1]) == "table") and (((_82_)[1]).winid == source_winid)) and ((_82_)[2] == nil)) then
        curr_win_only_3f = true
      else
        curr_win_only_3f = nil
      end
    end
    local cross_win_3f = not curr_win_only_3f
    for _, _84_ in ipairs(target_windows) do
      local _each_85_ = _84_
      local winid = _each_85_["winid"]
      local wininfo = _each_85_
      if cross_win_3f then
        api.nvim_set_current_win(winid)
      else
      end
      cursor_positions[winid] = get_cursor_pos()
      get_targets_2a(pattern, {targets = targets, wininfo = wininfo, ["source-winid"] = source_winid})
    end
    if cross_win_3f then
      api.nvim_set_current_win(source_winid)
    else
    end
    if not empty_3f(targets) then
      local by_screen_pos_3f = (vim.o.wrap and (#targets < 200))
      if by_screen_pos_3f then
        for winid, _88_ in pairs(cursor_positions) do
          local _each_89_ = _88_
          local line = _each_89_[1]
          local col = _each_89_[2]
          local _90_ = vim.fn.screenpos(winid, line, col)
          if ((_G.type(_90_) == "table") and (nil ~= (_90_).row) and ((_90_).col == col)) then
            local row = (_90_).row
            cursor_positions[winid] = {row, col}
          else
          end
        end
      else
      end
      for _, _93_ in ipairs(targets) do
        local _each_94_ = _93_
        local _each_95_ = _each_94_["pos"]
        local line = _each_95_[1]
        local col = _each_95_[2]
        local _each_96_ = _each_94_["wininfo"]
        local winid = _each_96_["winid"]
        local t = _each_94_
        if by_screen_pos_3f then
          local _97_ = vim.fn.screenpos(winid, line, col)
          if ((_G.type(_97_) == "table") and (nil ~= (_97_).row) and ((_97_).col == col)) then
            local row = (_97_).row
            t["screenpos"] = {row, col}
          else
          end
        else
        end
        t["rank"] = distance((t.screenpos or t.pos), cursor_positions[winid])
      end
      local function _100_(_241, _242)
        return ((_241).rank < (_242).rank)
      end
      table.sort(targets, _100_)
      return targets
    else
      return nil
    end
  end
end
local function populate_sublists(targets)
  targets["sublists"] = {}
  if not opts.case_sensitive then
    local function _103_(t, k)
      return rawget(t, k:lower())
    end
    local function _104_(t, k, v)
      return rawset(t, k:lower(), v)
    end
    setmetatable(targets.sublists, {__index = _103_, __newindex = _104_})
  else
  end
  for _, _106_ in ipairs(targets) do
    local _each_107_ = _106_
    local _each_108_ = _each_107_["pair"]
    local _0 = _each_108_[1]
    local ch2 = _each_108_[2]
    local target = _each_107_
    if not targets.sublists[ch2] then
      targets["sublists"][ch2] = {}
    else
    end
    table.insert(targets.sublists[ch2], target)
  end
  return nil
end
local function set_autojump(sublist, force_noautojump_3f)
  sublist["autojump?"] = (not (force_noautojump_3f or user_forced_noautojump_3f()) and (user_forced_autojump_3f() or (#opts.safe_labels >= dec(#sublist))))
  return nil
end
local function attach_label_set(sublist)
  local _110_
  if user_forced_autojump_3f() then
    _110_ = opts.safe_labels
  elseif user_forced_noautojump_3f() then
    _110_ = opts.labels
  elseif sublist["autojump?"] then
    _110_ = opts.safe_labels
  else
    _110_ = opts.labels
  end
  sublist["label-set"] = _110_
  return nil
end
local function set_sublist_attributes(targets, _112_)
  local _arg_113_ = _112_
  local force_noautojump_3f = _arg_113_["force-noautojump?"]
  for _, sublist in pairs(targets.sublists) do
    set_autojump(sublist, force_noautojump_3f)
    attach_label_set(sublist)
  end
  return nil
end
local function set_labels(targets)
  for _, sublist in pairs(targets.sublists) do
    if (#sublist > 1) then
      local _local_114_ = sublist
      local autojump_3f = _local_114_["autojump?"]
      local label_set = _local_114_["label-set"]
      for i, target in ipairs(sublist) do
        local i_2a
        if autojump_3f then
          i_2a = dec(i)
        else
          i_2a = i
        end
        if (i_2a > 0) then
          local _117_
          do
            local _116_ = (i_2a % #label_set)
            if (_116_ == 0) then
              _117_ = label_set[#label_set]
            elseif (nil ~= _116_) then
              local n = _116_
              _117_ = label_set[n]
            else
              _117_ = nil
            end
          end
          target["label"] = _117_
        else
        end
      end
    else
    end
  end
  return nil
end
local function set_label_states(sublist, _123_)
  local _arg_124_ = _123_
  local group_offset = _arg_124_["group-offset"]
  local _7clabel_set_7c = #sublist["label-set"]
  local offset = (group_offset * _7clabel_set_7c)
  local primary_start
  local function _125_()
    if sublist["autojump?"] then
      return 2
    else
      return 1
    end
  end
  primary_start = (offset + _125_())
  local primary_end = (primary_start + dec(_7clabel_set_7c))
  local secondary_start = inc(primary_end)
  local secondary_end = (primary_end + _7clabel_set_7c)
  for i, target in ipairs(sublist) do
    if target.label then
      local _126_
      if (function(_127_,_128_,_129_) return (_127_ <= _128_) and (_128_ <= _129_) end)(primary_start,i,primary_end) then
        _126_ = "active-primary"
      elseif (function(_130_,_131_,_132_) return (_130_ <= _131_) and (_131_ <= _132_) end)(secondary_start,i,secondary_end) then
        _126_ = "active-secondary"
      elseif (i > secondary_end) then
        _126_ = "inactive"
      else
        _126_ = nil
      end
      target["label-state"] = _126_
    else
    end
  end
  return nil
end
local function set_initial_label_states(targets)
  for _, sublist in pairs(targets.sublists) do
    set_label_states(sublist, {["group-offset"] = 0})
  end
  return nil
end
local function inactivate_labels(target_list)
  for _, target in ipairs(target_list) do
    target["label-state"] = "inactive"
  end
  return nil
end
local function set_beacon_for_labeled(target)
  local _let_135_ = target
  local _let_136_ = _let_135_["pair"]
  local ch1 = _let_136_[1]
  local ch2 = _let_136_[2]
  local edge_pos_3f = _let_135_["edge-pos?"]
  local label = _let_135_["label"]
  local offset
  local function _137_()
    if edge_pos_3f then
      return 0
    else
      return ch2:len()
    end
  end
  offset = (ch1:len() + _137_())
  local virttext
  do
    local _138_ = target["label-state"]
    if (_138_ == "active-primary") then
      virttext = {{label, hl.group["label-primary"]}}
    elseif (_138_ == "active-secondary") then
      virttext = {{label, hl.group["label-secondary"]}}
    elseif (_138_ == "inactive") then
      if not opts.highlight_unlabeled then
        virttext = {{" ", hl.group["label-secondary"]}}
      else
        virttext = nil
      end
    else
      virttext = nil
    end
  end
  local _141_
  if virttext then
    _141_ = {offset, virttext}
  else
    _141_ = nil
  end
  target["beacon"] = _141_
  return nil
end
local function set_beacon_to_match_hl(target)
  local _let_143_ = target
  local _let_144_ = _let_143_["pair"]
  local ch1 = _let_144_[1]
  local ch2 = _let_144_[2]
  local virttext = {{(ch1 .. ch2), hl.group.match}}
  target["beacon"] = {0, virttext}
  return nil
end
local function set_beacon_to_empty_label(target)
  target["beacon"][2][1][1] = " "
  return nil
end
local function resolve_conflicts(target_list)
  local unlabeled_match_positions = {}
  local label_positions = {}
  for i, target in ipairs(target_list) do
    local _let_145_ = target
    local _let_146_ = _let_145_["pos"]
    local lnum = _let_146_[1]
    local col = _let_146_[2]
    local _let_147_ = _let_145_["pair"]
    local ch1 = _let_147_[1]
    local _ = _let_147_[2]
    local _let_148_ = _let_145_["wininfo"]
    local bufnr = _let_148_["bufnr"]
    local winid = _let_148_["winid"]
    if (not target.beacon or (opts.highlight_unlabeled and (target.beacon[2][1][2] == hl.group.match))) then
      local keys = {(bufnr .. " " .. winid .. " " .. lnum .. " " .. col), (bufnr .. " " .. winid .. " " .. lnum .. " " .. (col + ch1:len()))}
      for _0, k in ipairs(keys) do
        do
          local _149_ = label_positions[k]
          if (nil ~= _149_) then
            local other = _149_
            other.beacon = nil
            set_beacon_to_match_hl(target)
          else
          end
        end
        unlabeled_match_positions[k] = target
      end
    else
      local label_offset = target.beacon[1]
      local k = (bufnr .. " " .. winid .. " " .. lnum .. " " .. (col + label_offset))
      do
        local _151_ = unlabeled_match_positions[k]
        if (nil ~= _151_) then
          local other = _151_
          target.beacon = nil
          set_beacon_to_match_hl(other)
        elseif true then
          local _0 = _151_
          local _152_ = label_positions[k]
          if (nil ~= _152_) then
            local other = _152_
            target.beacon = nil
            set_beacon_to_empty_label(other)
          else
          end
        else
        end
      end
      label_positions[k] = target
    end
  end
  return nil
end
local function set_beacons(target_list, _156_)
  local _arg_157_ = _156_
  local force_no_labels_3f = _arg_157_["force-no-labels?"]
  if force_no_labels_3f then
    for _, target in ipairs(target_list) do
      set_beacon_to_match_hl(target)
    end
    return nil
  else
    for _, target in ipairs(target_list) do
      if target.label then
        set_beacon_for_labeled(target)
      elseif opts.highlight_unlabeled then
        set_beacon_to_match_hl(target)
      else
      end
    end
    return resolve_conflicts(target_list)
  end
end
local function light_up_beacons(target_list, _3fstart)
  for i = (_3fstart or 1), #target_list do
    local target = target_list[i]
    local _160_ = target.beacon
    if ((_G.type(_160_) == "table") and (nil ~= (_160_)[1]) and (nil ~= (_160_)[2])) then
      local offset = (_160_)[1]
      local virttext = (_160_)[2]
      local _let_161_ = map(dec, target.pos)
      local lnum = _let_161_[1]
      local col = _let_161_[2]
      api.nvim_buf_set_extmark(target.wininfo.bufnr, hl.ns, lnum, (col + offset), {virt_text = virttext, virt_text_pos = "overlay", hl_mode = "combine", priority = hl.priority.label})
    else
    end
  end
  return nil
end
local state = {["repeat"] = {in1 = nil, in2 = nil}, ["dot-repeat"] = {in1 = nil, in2 = nil, ["target-idx"] = nil, ["backward?"] = nil, ["inclusive-op?"] = nil, ["offset?"] = nil}}
local function leap(_163_)
  local _arg_164_ = _163_
  local dot_repeat_3f = _arg_164_["dot-repeat?"]
  local target_windows = _arg_164_["target-windows"]
  local kwargs = _arg_164_
  local function _166_()
    if dot_repeat_3f then
      return state["dot-repeat"]
    else
      return kwargs
    end
  end
  local _let_165_ = _166_()
  local backward_3f = _let_165_["backward?"]
  local inclusive_op_3f = _let_165_["inclusive-op?"]
  local offset = _let_165_["offset"]
  local mode = api.nvim_get_mode().mode
  local _3ftarget_windows
  do
    local _167_
    do
      local _168_ = target_windows
      if (_G.type(_168_) == "table") then
        local t = _168_
        _167_ = t
      elseif (_168_ == true) then
        _167_ = get_other_windows_on_tabpage(mode)
      else
        _167_ = nil
      end
    end
    if (_167_ ~= nil) then
      local function _170_(_241)
        return (vim.fn.getwininfo(_241))[1]
      end
      _3ftarget_windows = map(_170_, _167_)
    else
      _3ftarget_windows = _167_
    end
  end
  local source_window = vim.fn.getwininfo(vim.fn.win_getid())[1]
  local directional_3f = not _3ftarget_windows
  local op_mode_3f = mode:match("o")
  local change_op_3f = (op_mode_3f and (vim.v.operator == "c"))
  local dot_repeatable_op_3f = (op_mode_3f and directional_3f and (vim.v.operator ~= "y"))
  local force_noautojump_3f = (op_mode_3f or not directional_3f)
  local spec_keys
  local function _172_(_, k)
    return replace_keycodes(opts.special_keys[k])
  end
  spec_keys = setmetatable({}, {__index = _172_})
  local function prepare_pattern(in1, _3fin2)
    local function _173_()
      if opts.case_sensitive then
        return "\\C"
      else
        return "\\c"
      end
    end
    local function _175_()
      local _174_ = _3fin2
      if (_174_ == spec_keys.eol) then
        return ("\\(" .. _3fin2 .. "\\|\\r\\?\\n\\)")
      elseif true then
        local _ = _174_
        return (_3fin2 or "\\_.")
      else
        return nil
      end
    end
    return ("\\V" .. _173_() .. in1:gsub("\\", "\\\\") .. _175_())
  end
  local function get_target_with_active_primary_label(sublist, input)
    local res = nil
    for idx, _177_ in ipairs(sublist) do
      local _each_178_ = _177_
      local label = _each_178_["label"]
      local label_state = _each_178_["label-state"]
      local target = _each_178_
      if (res or (label_state == "inactive")) then break end
      if ((label == input) and (label_state == "active-primary")) then
        res = {idx, target}
      else
      end
    end
    return res
  end
  local function update_state(state_2a)
    if not dot_repeat_3f then
      if state_2a["repeat"] then
        state["repeat"] = state_2a["repeat"]
      else
      end
      if (state_2a["dot-repeat"] and dot_repeatable_op_3f) then
        state["dot-repeat"] = vim.tbl_extend("error", state_2a["dot-repeat"], {["backward?"] = backward_3f, offset = offset, ["inclusive-op?"] = inclusive_op_3f})
        return nil
      else
        return nil
      end
    else
      return nil
    end
  end
  local jump_to_21
  do
    local first_jump_3f = true
    local function _183_(target)
      jump_to_21_2a(target.pos, {winid = target.wininfo.winid, ["add-to-jumplist?"] = first_jump_3f, mode = mode, offset = offset, ["backward?"] = backward_3f, ["inclusive-op?"] = inclusive_op_3f})
      first_jump_3f = false
      return nil
    end
    jump_to_21 = _183_
  end
  local function traverse(targets, idx, _184_)
    local _arg_185_ = _184_
    local force_no_labels_3f = _arg_185_["force-no-labels?"]
    if force_no_labels_3f then
      inactivate_labels(targets)
    else
    end
    set_beacons(targets, {["force-no-labels?"] = force_no_labels_3f})
    do
      hl:cleanup(_3ftarget_windows)
      hl["apply-backdrop"](hl, backward_3f, _3ftarget_windows)
      do
        light_up_beacons(targets, inc(idx))
      end
      highlight_cursor()
      vim.cmd("redraw")
    end
    local _187_
    local function _188_()
      if dot_repeatable_op_3f then
        set_dot_repeat()
      else
      end
      do
      end
      local function _191_()
        if _3ftarget_windows then
          local _190_ = _3ftarget_windows
          table.insert(_190_, source_window)
          return _190_
        else
          return nil
        end
      end
      hl:cleanup(_191_())
      exec_user_autocmds("LeapLeave")
      return nil
    end
    _187_ = (get_input_by_keymap() or _188_())
    if (nil ~= _187_) then
      local input = _187_
      if ((input == spec_keys.next_match) or (input == spec_keys.prev_match)) then
        local new_idx
        do
          local _192_ = input
          if (_192_ == spec_keys.next_match) then
            new_idx = min(inc(idx), #targets)
          elseif (_192_ == spec_keys.prev_match) then
            new_idx = max(dec(idx), 1)
          else
            new_idx = nil
          end
        end
        update_state({["repeat"] = {in1 = state["repeat"].in1, in2 = targets[new_idx].pair[2]}})
        jump_to_21(targets[new_idx])
        return traverse(targets, new_idx, {["force-no-labels?"] = force_no_labels_3f})
      else
        local _194_ = get_target_with_active_primary_label(targets, input)
        if ((_G.type(_194_) == "table") and true and (nil ~= (_194_)[2])) then
          local _ = (_194_)[1]
          local target = (_194_)[2]
          if dot_repeatable_op_3f then
            set_dot_repeat()
          else
          end
          do
            jump_to_21(target)
          end
          local function _197_()
            if _3ftarget_windows then
              local _196_ = _3ftarget_windows
              table.insert(_196_, source_window)
              return _196_
            else
              return nil
            end
          end
          hl:cleanup(_197_())
          exec_user_autocmds("LeapLeave")
          return nil
        elseif true then
          local _ = _194_
          if dot_repeatable_op_3f then
            set_dot_repeat()
          else
          end
          do
            vim.fn.feedkeys(input, "i")
          end
          local function _200_()
            if _3ftarget_windows then
              local _199_ = _3ftarget_windows
              table.insert(_199_, source_window)
              return _199_
            else
              return nil
            end
          end
          hl:cleanup(_200_())
          exec_user_autocmds("LeapLeave")
          return nil
        else
          return nil
        end
      end
    else
      return nil
    end
  end
  local function get_first_pattern_input()
    do
      hl:cleanup(_3ftarget_windows)
      hl["apply-backdrop"](hl, backward_3f, _3ftarget_windows)
      do
        echo("")
      end
      highlight_cursor()
      vim.cmd("redraw")
    end
    local _204_
    local function _205_()
      if change_op_3f then
        handle_interrupted_change_op_21()
      else
      end
      do
      end
      local function _208_()
        if _3ftarget_windows then
          local _207_ = _3ftarget_windows
          table.insert(_207_, source_window)
          return _207_
        else
          return nil
        end
      end
      hl:cleanup(_208_())
      exec_user_autocmds("LeapLeave")
      return nil
    end
    _204_ = (get_input_by_keymap() or _205_())
    if (_204_ == spec_keys.repeat_search) then
      if state["repeat"].in1 then
        return state["repeat"].in1, state["repeat"].in2
      else
        if change_op_3f then
          handle_interrupted_change_op_21()
        else
        end
        do
          echo_no_prev_search()
        end
        local function _211_()
          if _3ftarget_windows then
            local _210_ = _3ftarget_windows
            table.insert(_210_, source_window)
            return _210_
          else
            return nil
          end
        end
        hl:cleanup(_211_())
        exec_user_autocmds("LeapLeave")
        return nil
      end
    elseif (nil ~= _204_) then
      local in1 = _204_
      return in1
    else
      return nil
    end
  end
  local function get_second_pattern_input(targets)
    do
      local _214_ = targets
      set_initial_label_states(_214_)
      set_beacons(_214_, {})
    end
    do
      hl:cleanup(_3ftarget_windows)
      hl["apply-backdrop"](hl, backward_3f, _3ftarget_windows)
      do
        light_up_beacons(targets)
      end
      highlight_cursor()
      vim.cmd("redraw")
    end
    local function _215_()
      if change_op_3f then
        handle_interrupted_change_op_21()
      else
      end
      do
      end
      local function _218_()
        if _3ftarget_windows then
          local _217_ = _3ftarget_windows
          table.insert(_217_, source_window)
          return _217_
        else
          return nil
        end
      end
      hl:cleanup(_218_())
      exec_user_autocmds("LeapLeave")
      return nil
    end
    return (get_input_by_keymap() or _215_())
  end
  local function get_full_pattern_input()
    local _219_, _220_ = get_first_pattern_input()
    if ((nil ~= _219_) and (nil ~= _220_)) then
      local in1 = _219_
      local in2 = _220_
      return in1, in2
    elseif ((nil ~= _219_) and (_220_ == nil)) then
      local in1 = _219_
      local _221_ = get_input_by_keymap()
      if (nil ~= _221_) then
        local in2 = _221_
        return in1, in2
      elseif true then
        local _ = _221_
        if change_op_3f then
          handle_interrupted_change_op_21()
        else
        end
        do
        end
        local function _224_()
          if _3ftarget_windows then
            local _223_ = _3ftarget_windows
            table.insert(_223_, source_window)
            return _223_
          else
            return nil
          end
        end
        hl:cleanup(_224_())
        exec_user_autocmds("LeapLeave")
        return nil
      else
        return nil
      end
    else
      return nil
    end
  end
  local function post_pattern_input_loop(sublist)
    local function loop(group_offset, initial_invoc_3f)
      do
        local _227_ = sublist
        set_label_states(_227_, {["group-offset"] = group_offset})
        set_beacons(_227_, {})
      end
      do
        hl:cleanup(_3ftarget_windows)
        hl["apply-backdrop"](hl, backward_3f, _3ftarget_windows)
        do
          local function _228_()
            if sublist["autojump?"] then
              return 2
            else
              return nil
            end
          end
          light_up_beacons(sublist, _228_())
        end
        highlight_cursor()
        vim.cmd("redraw")
      end
      local _229_
      local function _230_()
        if change_op_3f then
          handle_interrupted_change_op_21()
        else
        end
        do
        end
        local function _233_()
          if _3ftarget_windows then
            local _232_ = _3ftarget_windows
            table.insert(_232_, source_window)
            return _232_
          else
            return nil
          end
        end
        hl:cleanup(_233_())
        exec_user_autocmds("LeapLeave")
        return nil
      end
      _229_ = (get_input() or _230_())
      if (nil ~= _229_) then
        local input = _229_
        if (((input == spec_keys.next_group) or ((input == spec_keys.prev_group) and not initial_invoc_3f)) and (not sublist["autojump?"] or user_forced_autojump_3f())) then
          local _7cgroups_7c = ceil((#sublist / #sublist["label-set"]))
          local max_offset = dec(_7cgroups_7c)
          local inc_2fdec
          if (input == spec_keys.next_group) then
            inc_2fdec = inc
          else
            inc_2fdec = dec
          end
          local new_offset = clamp(inc_2fdec(group_offset), 0, max_offset)
          return loop(new_offset, false)
        else
          return input
        end
      else
        return nil
      end
    end
    return loop(0, true)
  end
  exec_user_autocmds("LeapEnter")
  local function _237_(...)
    local _238_, _239_ = ...
    if ((nil ~= _238_) and true) then
      local in1 = _238_
      local _3fin2 = _239_
      local function _240_(...)
        local _241_ = ...
        if (nil ~= _241_) then
          local targets = _241_
          local function _242_(...)
            local _243_ = ...
            if (nil ~= _243_) then
              local in2 = _243_
              if dot_repeat_3f then
                local _244_ = targets[state["dot-repeat"]["target-idx"]]
                if (nil ~= _244_) then
                  local target = _244_
                  if dot_repeatable_op_3f then
                    set_dot_repeat()
                  else
                  end
                  do
                    jump_to_21(target)
                  end
                  local function _247_(...)
                    if _3ftarget_windows then
                      local _246_ = _3ftarget_windows
                      table.insert(_246_, source_window)
                      return _246_
                    else
                      return nil
                    end
                  end
                  hl:cleanup(_247_(...))
                  exec_user_autocmds("LeapLeave")
                  return nil
                elseif true then
                  local _ = _244_
                  if change_op_3f then
                    handle_interrupted_change_op_21()
                  else
                  end
                  do
                  end
                  local function _250_(...)
                    if _3ftarget_windows then
                      local _249_ = _3ftarget_windows
                      table.insert(_249_, source_window)
                      return _249_
                    else
                      return nil
                    end
                  end
                  hl:cleanup(_250_(...))
                  exec_user_autocmds("LeapLeave")
                  return nil
                else
                  return nil
                end
              elseif (directional_3f and (in2 == spec_keys.next_match)) then
                local in20 = targets[1].pair[2]
                update_state({["repeat"] = {in1 = in1, in2 = in20}})
                jump_to_21(targets[1])
                if (op_mode_3f or (#targets == 1)) then
                  if dot_repeatable_op_3f then
                    set_dot_repeat()
                  else
                  end
                  do
                    update_state({["dot-repeat"] = {in1 = in1, in2 = in20, ["target-idx"] = 1}})
                  end
                  local function _254_(...)
                    if _3ftarget_windows then
                      local _253_ = _3ftarget_windows
                      table.insert(_253_, source_window)
                      return _253_
                    else
                      return nil
                    end
                  end
                  hl:cleanup(_254_(...))
                  exec_user_autocmds("LeapLeave")
                  return nil
                else
                  return traverse(targets, 1, {["force-no-labels?"] = true})
                end
              else
                update_state({["repeat"] = {in1 = in1, in2 = in2}})
                local update_dot_repeat_state
                local function _256_(_241)
                  return update_state({["dot-repeat"] = {in1 = in1, in2 = in2, ["target-idx"] = _241}})
                end
                update_dot_repeat_state = _256_
                local _257_
                local function _258_(...)
                  if change_op_3f then
                    handle_interrupted_change_op_21()
                  else
                  end
                  do
                    echo_not_found((in1 .. in2))
                  end
                  local function _261_(...)
                    if _3ftarget_windows then
                      local _260_ = _3ftarget_windows
                      table.insert(_260_, source_window)
                      return _260_
                    else
                      return nil
                    end
                  end
                  hl:cleanup(_261_(...))
                  exec_user_autocmds("LeapLeave")
                  return nil
                end
                _257_ = (targets.sublists[in2] or _258_(...))
                if ((_G.type(_257_) == "table") and (nil ~= (_257_)[1]) and ((_257_)[2] == nil)) then
                  local only = (_257_)[1]
                  if dot_repeatable_op_3f then
                    set_dot_repeat()
                  else
                  end
                  do
                    update_dot_repeat_state(1)
                    jump_to_21(only)
                  end
                  local function _264_(...)
                    if _3ftarget_windows then
                      local _263_ = _3ftarget_windows
                      table.insert(_263_, source_window)
                      return _263_
                    else
                      return nil
                    end
                  end
                  hl:cleanup(_264_(...))
                  exec_user_autocmds("LeapLeave")
                  return nil
                elseif (nil ~= _257_) then
                  local sublist = _257_
                  if sublist["autojump?"] then
                    jump_to_21(sublist[1])
                  else
                  end
                  local _266_ = post_pattern_input_loop(sublist)
                  if (nil ~= _266_) then
                    local in_final = _266_
                    if (directional_3f and (in_final == spec_keys.next_match)) then
                      local new_idx
                      if sublist["autojump?"] then
                        new_idx = 2
                      else
                        new_idx = 1
                      end
                      jump_to_21(sublist[new_idx])
                      if op_mode_3f then
                        if dot_repeatable_op_3f then
                          set_dot_repeat()
                        else
                        end
                        do
                          update_dot_repeat_state(1)
                        end
                        local function _270_(...)
                          if _3ftarget_windows then
                            local _269_ = _3ftarget_windows
                            table.insert(_269_, source_window)
                            return _269_
                          else
                            return nil
                          end
                        end
                        hl:cleanup(_270_(...))
                        exec_user_autocmds("LeapLeave")
                        return nil
                      else
                        return traverse(sublist, new_idx, {["force-no-labels?"] = not sublist["autojump?"]})
                      end
                    else
                      local _272_ = get_target_with_active_primary_label(sublist, in_final)
                      if ((_G.type(_272_) == "table") and (nil ~= (_272_)[1]) and (nil ~= (_272_)[2])) then
                        local idx = (_272_)[1]
                        local target = (_272_)[2]
                        if dot_repeatable_op_3f then
                          set_dot_repeat()
                        else
                        end
                        do
                          update_dot_repeat_state(idx)
                          jump_to_21(target)
                        end
                        local function _275_(...)
                          if _3ftarget_windows then
                            local _274_ = _3ftarget_windows
                            table.insert(_274_, source_window)
                            return _274_
                          else
                            return nil
                          end
                        end
                        hl:cleanup(_275_(...))
                        exec_user_autocmds("LeapLeave")
                        return nil
                      elseif true then
                        local _ = _272_
                        if sublist["autojump?"] then
                          if dot_repeatable_op_3f then
                            set_dot_repeat()
                          else
                          end
                          do
                            vim.fn.feedkeys(in_final, "i")
                          end
                          local function _278_(...)
                            if _3ftarget_windows then
                              local _277_ = _3ftarget_windows
                              table.insert(_277_, source_window)
                              return _277_
                            else
                              return nil
                            end
                          end
                          hl:cleanup(_278_(...))
                          exec_user_autocmds("LeapLeave")
                          return nil
                        else
                          if change_op_3f then
                            handle_interrupted_change_op_21()
                          else
                          end
                          do
                          end
                          local function _281_(...)
                            if _3ftarget_windows then
                              local _280_ = _3ftarget_windows
                              table.insert(_280_, source_window)
                              return _280_
                            else
                              return nil
                            end
                          end
                          hl:cleanup(_281_(...))
                          exec_user_autocmds("LeapLeave")
                          return nil
                        end
                      else
                        return nil
                      end
                    end
                  else
                    return nil
                  end
                else
                  return nil
                end
              end
            elseif true then
              local __60_auto = _243_
              return ...
            else
              return nil
            end
          end
          local function _289_(...)
            do
              local _290_ = targets
              populate_sublists(_290_)
              set_sublist_attributes(_290_, {["force-noautojump?"] = force_noautojump_3f})
              set_labels(_290_)
            end
            return (_3fin2 or get_second_pattern_input(targets))
          end
          return _242_(_289_(...))
        elseif true then
          local __60_auto = _241_
          return ...
        else
          return nil
        end
      end
      local function _292_(...)
        if change_op_3f then
          handle_interrupted_change_op_21()
        else
        end
        do
          echo_not_found((in1 .. (_3fin2 or "")))
        end
        local function _295_(...)
          if _3ftarget_windows then
            local _294_ = _3ftarget_windows
            table.insert(_294_, source_window)
            return _294_
          else
            return nil
          end
        end
        hl:cleanup(_295_(...))
        exec_user_autocmds("LeapLeave")
        return nil
      end
      return _240_((get_targets(prepare_pattern(in1, _3fin2), {["backward?"] = backward_3f, ["target-windows"] = _3ftarget_windows}) or _292_(...)))
    elseif true then
      local __60_auto = _238_
      return ...
    else
      return nil
    end
  end
  local function _297_()
    if dot_repeat_3f then
      return state["dot-repeat"].in1, state["dot-repeat"].in2
    elseif opts.highlight_ahead_of_time then
      return get_first_pattern_input()
    else
      return get_full_pattern_input()
    end
  end
  return _237_(_297_())
end
local temporary_editor_opts = {["vim.bo.modeline"] = false}
local saved_editor_opts = {}
local function save_editor_opts()
  for opt, _ in pairs(temporary_editor_opts) do
    local _let_298_ = vim.split(opt, ".", true)
    local _0 = _let_298_[1]
    local scope = _let_298_[2]
    local name = _let_298_[3]
    saved_editor_opts[opt] = _G.vim[scope][name]
  end
  return nil
end
local function set_editor_opts(opts0)
  for opt, val in pairs(opts0) do
    local _let_299_ = vim.split(opt, ".", true)
    local _ = _let_299_[1]
    local scope = _let_299_[2]
    local name = _let_299_[3]
    _G.vim[scope][name] = val
  end
  return nil
end
local function set_temporary_editor_opts()
  return set_editor_opts(temporary_editor_opts)
end
local function restore_editor_opts()
  return set_editor_opts(saved_editor_opts)
end
hl["init-highlight"](hl)
api.nvim_create_augroup("LeapDefault", {})
local function _300_()
  return hl["init-highlight"](hl)
end
api.nvim_create_autocmd("ColorScheme", {callback = _300_, group = "LeapDefault"})
local function _301_()
  save_editor_opts()
  return set_temporary_editor_opts()
end
api.nvim_create_autocmd("User", {pattern = "LeapEnter", callback = _301_, group = "LeapDefault"})
api.nvim_create_autocmd("User", {pattern = "LeapLeave", callback = restore_editor_opts, group = "LeapDefault"})
return {state = state, leap = leap}
