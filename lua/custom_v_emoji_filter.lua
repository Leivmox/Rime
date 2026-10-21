-- v+拼音 emoji/符号模式：专属段只保留 emoji/符号候选（个人脚本：文件名带 custom 前缀）
--
-- 配合 rime_frost.custom.yaml 的「v+拼音 → emoji」模式：
--   recognizer 把 ^v[a-z]{2,}$ 打上 emoji_lookup tag，affix_segmentor 剥掉前缀 v，
--   script_translator@emoji_lookup 用主词库把剩余拼音翻译成文字候选（vxiao →「笑」…），
--   simplifier@emoji 再按 opencc/emoji.txt 附加转换候选（「笑」→ 😄 😊）。
--   本 filter 把该段残留的文字候选（「笑」）删掉，最终候选框只剩 😄 😊 这类纯符号。
--
-- 判定规则：候选文本中任一字符落在 CJK（部首/CJK 标点/汉字/假名）、CJK 扩展区、
-- 全角 ASCII 变体、ASCII 字母数字区 → 视为文字候选，整条丢弃；
-- emoji 修饰符（U+FE0F 变体选择符、U+200D 零宽连接符、U+20E3 键帽）跳过不判，
-- 否则 ⬆️（U+2B06 + U+FE0F）这类组合 emoji 会被误伤。

local M = {}

-- 遍历 UTF-8 文本的所有码点，判断是否「纯符号/emoji」（不含汉字和 ASCII 字母数字）
local function is_symbol_only(text)
  if not text or #text == 0 then
    return false
  end
  local i, len = 1, #text
  while i <= len do
    local b1 = string.byte(text, i)
    local cp
    if b1 < 0x80 then                 -- 1 字节：ASCII
      cp = b1
      i = i + 1
    elseif b1 < 0xE0 then             -- 2 字节
      if i + 1 > len then return false end
      cp = (b1 % 0x20) * 0x40 + (string.byte(text, i + 1) % 0x40)
      i = i + 2
    elseif b1 < 0xF0 then             -- 3 字节（↑ ★ ① © 等）
      if i + 2 > len then return false end
      cp = (b1 % 0x10) * 0x1000 + (string.byte(text, i + 1) % 0x40) * 0x40
        + (string.byte(text, i + 2) % 0x40)
      i = i + 3
    else                              -- 4 字节（😄 🀄 等）
      if i + 3 > len then return false end
      cp = (b1 % 0x08) * 0x40000 + (string.byte(text, i + 1) % 0x40) * 0x1000
        + (string.byte(text, i + 2) % 0x40) * 0x40 + (string.byte(text, i + 3) % 0x40)
      i = i + 4
    end
    if cp == 0xFE0F or cp == 0xFE0E   -- emoji 变体选择符（⬆️ 末尾的 ️）
      or cp == 0x200D or cp == 0x20E3 then  -- 零宽连接符（👨‍👩‍👧）、键帽（🅰️）
      -- 修饰符：跳过，不算文字
    elseif (cp >= 0x2E80 and cp <= 0x9FFF)  -- 部首、CJK 标点、汉字、假名
      or cp >= 0x20000                        -- CJK 扩展 B 及以上
      or (cp >= 0xF900 and cp <= 0xFAFF)      -- CJK 兼容区
      or (cp >= 0xFF01 and cp <= 0xFF5E)      -- 全角 ASCII 变体
      or (cp >= 0x30 and cp <= 0x39)          -- 0-9
      or (cp >= 0x41 and cp <= 0x5A)          -- A-Z
      or (cp >= 0x61 and cp <= 0x7A) then     -- a-z
      return false                            -- 出现文字字符 → 整条候选丢弃
    end
    -- 其余区间（①★↑©½ 及 U+1F600 起的 emoji 区）→ 合格
  end
  return true
end

function M.func(input, env)
  local context = env.engine.context
  local composition = context.composition
  local seg = nil
  if not composition:empty() then
    seg = composition:back()          -- 当前活跃段
  end
  if seg and seg:has_tag("emoji_lookup") then
    -- v 模式：只放行纯符号/emoji 候选，文字候选（「笑」「上」）全部拦下
    for cand in input:iter() do
      if is_symbol_only(cand.text) then
        yield(cand)
      end
    end
  else
    -- 非 v 模式：原样放行，零开销
    for cand in input:iter() do
      yield(cand)
    end
  end
end

return M
