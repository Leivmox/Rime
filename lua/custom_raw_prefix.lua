-- 前缀反查段（u 拆字 / v 表情）补一个「原样输入」候选，让输入串始终带上前缀
-- （个人脚本：文件名带 custom_ 前缀，与雾凇发行版自带脚本区分）
--
-- 现象：u 段打 usd、v 段打 vqi / vcho / vlo 时，输入框里前缀 u/v 消失。
-- 根因：affix_segmentor 把「前缀 + 编码」切成 phony 前缀段 + 编码段两段，
--       librime 的 Composition::GetPreedit 会跳过 phony 段，前缀只能靠
--       xxx_lookup/preedit_format 的 xform/^/u/ 补回来；而 preedit_format 只作用于
--       「有候选」的段里选中候选的 preedit。编码查不到词（u 段）或文字候选被 filter
--       删光后不剩符号（v 段）时该段没有候选，preedit 退回拼接段内原始编码，前缀就丢了。
-- 做法：给该段补一个候选 —— 文本仍是段内编码（回车行为不变，仍是原样上屏），
--       preedit 显式设为「前缀 + 编码」。段一旦有候选，preedit 就走候选的 preedit，
--       前缀始终显示；真的查到候选时由对应 filter（custom_u_raw_filter.lua /
--       custom_v_emoji_filter.lua）把它删掉，正常候选不受影响。
--       （注意：librime 新版 SimpleCandidate::preedit() 默认返回空串，不回退到 text，
--        所以 preedit 必须显式 set，否则输入框仍会退回原始编码。）
local M = {}

-- 段 tag -> 前缀配置路径（与 rime_frost.custom.yaml 中的 affix_segmentor 对应）
local PREFIX_PATHS = {
  radical_lookup = 'radical_lookup/prefix',
  emoji_lookup = 'emoji_lookup/prefix',
}
local DEFAULT_PREFIX = {
  radical_lookup = 'u',
  emoji_lookup = 'v',
}

function M.func(input, seg, env)
  if input == '' then
    return
  end
  for tag, path in pairs(PREFIX_PATHS) do
    if seg:has_tag(tag) then
      local prefix = env.engine.schema.config:get_string(path) or DEFAULT_PREFIX[tag]
      -- 只处理 affix 已经剥掉前缀的编码段；万一没剥（段内还带着前缀），说明 preedit
      -- 本来就能显示完整输入，不用补，否则会补出 uu / vv 前缀。
      if input:sub(1, #prefix) ~= prefix then
        local cand = Candidate('', seg.start, seg._end, input, '')
        cand.preedit = prefix .. input
        cand.quality = -100  -- 排在所有真候选之后
        yield(cand)
      end
      return
    end
  end
end

return M
