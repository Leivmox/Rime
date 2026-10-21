-- ESC 一键完全清空输入（个人脚本：文件名带 custom_ 前缀，与雾凇发行版自带脚本区分）
--
-- 背景：librime 里 Escape 绑定的动作是 CancelComposition：
--   先 ClearPreviousSegment()（只清除当前段），失败后才 Clear()（整体清空）。
-- 而 affix_segmentor（拼音方案的 u 拆字反查、五笔方案的 z 临时拼音等）
-- 会把输入切成「前缀段 + 编码段」两段，导致按一次 ESC 只清掉编码段，
-- 前缀 u / z 还留在输入里，要按好几次才能退干净。
--
-- 本脚本：按下 ESC 且正在输入时，直接 context:clear() 全部清空。
-- 普通输入本来就是一整段、ESC 原本就是全清，行为不变；
-- 反查/特殊模式从此一次 ESC 即可彻底退出。

local M = {}

function M.func(key, env)
  if key:release() then
    return 2 -- kNoop
  end
  if key:repr() ~= "Escape" then
    return 2
  end
  local context = env.engine.context
  if context:is_composing() then
    context:clear()
    return 1 -- kAccepted
  end
  return 2
end

return M
