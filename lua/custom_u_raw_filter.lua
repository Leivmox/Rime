-- 删掉 custom_raw_prefix.lua 给 u 拆字段补的「原样输入」候选，只在真查不到词时保留
-- （个人脚本：文件名带 custom_ 前缀，与雾凇发行版自带脚本区分）
--
-- custom_raw_prefix.lua 给 radical_lookup 段补了一个 文本 = 段内编码、preedit =「u + 编码」
-- 的候选，目的是让 preedit 在该段查不到词时也显示完整的 u 前缀。但编码正常查到词时，
-- 这个补出来的候选会多出一条「siri」这类原样输入项，所以在这里按文本精确判定后删掉。
-- 判定依据：候选文本 == 该段编码；真候选都是汉字，不会撞上。
local M = {}

function M.func(input, env)
  local composition = env.engine.context.composition
  local seg = nil
  if not composition:empty() then
    seg = composition:back()
  end
  if seg and seg:has_tag('radical_lookup') then
    local code = seg:active_text(env.engine.context.input)
    -- 补出来的候选权重最低、排在最后，这里先扣住它：
    -- 有真候选（any == true）就丢弃，只有它自己时才放行，让 preedit 显示 u。
    local raw_cand = nil
    local any = false
    for cand in input:iter() do
      if cand.text == code then
        raw_cand = cand
      else
        any = true
        yield(cand)
      end
    end
    if raw_cand and not any then
      yield(raw_cand)
    end
  else
    for cand in input:iter() do
      yield(cand)
    end
  end
end

return M
