-- 反向键盘布局映射：把 Colemak-DH 发出的字母还原成 QWERTY 键位字母。
--
-- 场景：键盘固件底层用 VIA 把布局改成了 Colemak-DH，但五笔字根是按 QWERTY
-- 键位排的。这个 processor 在 Rime 层把「实际收到的键」反向映射回「QWERTY
-- 键位对应的字母」，让五笔码表（按 QWERTY 编码）正确匹配，从而不必改键盘固件。
--
-- 映射表：{ 收到的 Colemak 键 = 还原后的 QWERTY 键位字母 }
-- 覆盖 QWERTY 全部 26 个字母键位（Colemak-DH 布局）。
--
-- 备注：
--   1. 只处理「无修饰键」的按下事件；Shift/Ctrl/Alt/Super 组合键直接放行，
--      这样 U/R/N/V 这些大写 recognizer 前缀（Unicode、金额大写、农历、
--      计算器）不受影响。
--   2. 英文模式（ascii_mode）下不映射，英文按 Colemak 原样输出。
--   3. 分号键（Rime 内部名为 semicolon）对应 QWERTY 的 P 键位：Colemak 把
--      P 键位发成 ';'，这里还原成 'p'，所以五笔 P 键字根按键盘原 P 键位。
--   4. Colemak-DH 下排是 x c d v z k h：按下原 QWERTY 的 z/x/c/v/b/n/m 键位时，
--      固件实际发出 x/c/d/v/z/k/h，所以下排是 x→z、c→x、d→c、v→v、z→b、
--      k→n、h→m（注意不是 z→z、x→x、c→c 那套，中间几个会错位）。
--   5. 五笔 z 前缀进入拼音查码模式后，拼音按字母输入（不按键位），此时停止
--      反向映射，直接用 Colemak-DH 发出的字母做拼音。编码中间的 z 万能码
--      仍然走反向映射（因为输入不以 z 开头）。

local M = {}

local MAP = {
  -- 上排
  q='q', w='w', f='e', p='r', b='t', j='y', l='u', u='i', y='o', semicolon='p',
  -- 中排
  a='a', r='s', s='d', t='f', g='g', m='h', n='j', e='k', i='l',
  -- 下排
  x='z', c='x', d='c', v='v', z='b', k='n', h='m',
}

-- 直接上屏的标点：QWERTY 键位被 Colemak 改成字母后，这里还原成标点直接输出、
-- 不进候选（和拼音方案里 punctuator/half_shape 单字符直出是同一个道理）。
local DIRECT = {
  o = ';',   -- QWERTY ';' 键位：Colemak 发 'o'，直接上屏分号
}

function M.func(key, env)
  local context = env.engine.context
  -- 只处理「按下」且无修饰键
  if key:release() or key:shift() or key:alt() or key:ctrl() or key:super() then
    return 2
  end
  -- 英文模式：不映射，直接输出 Colemak 英文
  if context:get_option('ascii_mode') then
    return 2
  end
  -- 拼音查码模式：输入以 z 开头说明已进入 z 临时拼音，此时停止反向映射，
  -- 让 Colemak-DH 字母直接做拼音（拼音是按字母不是按键位）。
  -- 编码中间的 z 万能码不受影响：那种情况下输入不以 z 开头，仍走映射。
  if context.input:match("^z") then
    return 2
  end
  local repr = key:repr()
  -- 标点：直接上屏，不进候选
  local direct = DIRECT[repr]
  if direct then
    if context:is_composing() then
      context:commit()   -- 先把当前候选上屏（和标点键默认行为一致）
    end
    env.engine:commit_text(direct)
    return 1
  end
  -- 字母：反向映射后进入五笔编码
  local mapped = MAP[repr]
  if mapped then
    context:push_input(mapped)
    return 1
  end
  return 2
end

return M