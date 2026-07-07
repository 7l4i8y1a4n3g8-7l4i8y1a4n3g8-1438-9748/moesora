# Moesora 主题入口脚本（CoffeeScript）
# Vite + coffee 插件编译为 templates/assets/dist/moesora.js；入口 import 的 CSS 输出为 moesora.css。

import "../style/index.css"

do ->
  cfg = window.MoesoraConfig or {}
  # 标签页离开/返回文案
  originalTitle = document.title
  hiddenTitle = cfg.hiddenTitle ? '(つ_<)~ 你去哪儿了！'   # 用 ? 区分「未配置」与「已清空」：清空则为 ''
  visibleTitle = cfg.visibleTitle ? '(*´∇｀*) 欢迎回来！'
  visibleTimer = null

  applyDark = (dark) ->
    root.classList.toggle 'dark', dark
    root.setAttribute 'data-color-scheme', if dark then 'dark' else 'light'
    try
      document.dispatchEvent new CustomEvent('moesora:theme-change', detail: dark: dark)
    catch e
      ev = document.createEvent('CustomEvent')
      ev.initCustomEvent 'moesora:theme-change', false, false, dark: dark
      document.dispatchEvent ev
    return

  readSaved = ->
    try
      return localStorage.getItem('moesora-theme')
    catch e
      return null
    return

  writeSaved = (v) ->
    try
      localStorage.setItem 'moesora-theme', v
    catch e
    return

  # 加载文案：DOM 就绪即移除 + 超时兜底（不再等 window.load，避免被慢资源拖住卡在加载层）

  hideLoader = ->
    el = document.getElementById('moesora-loading')
    if !el
      return
    el.style.opacity = '0'
    setTimeout (->
      if el.parentNode
        el.remove()
      return
    ), 400
    return

  document.addEventListener 'visibilitychange', ->
    if document.hidden
      clearTimeout visibleTimer if visibleTimer
      if hiddenTitle               # 为空则不改标题，保留页面原标题
        originalTitle = document.title
        document.title = hiddenTitle
    else
      clearTimeout visibleTimer if visibleTimer
      if visibleTitle
        document.title = visibleTitle
        visibleTimer = setTimeout((->
          document.title = originalTitle
          return
        ), 2000)
      else if hiddenTitle          # 仅在离开时改过的情况下恢复真实标题
        document.title = originalTitle
    return
    return
  # 明暗模式：跟随系统 + 手动切换 + 记忆
  root = document.documentElement
  media = if window.matchMedia then window.matchMedia('(prefers-color-scheme: dark)') else null
  toggle = document.getElementById('moe-theme-toggle')
  if toggle
    toggle.addEventListener 'click', ->
      nowDark = root.classList.contains('dark')
      applyDark !nowDark
      writeSaved if nowDark then 'light' else 'dark'
      return
  if media and media.addEventListener
    media.addEventListener 'change', (e) ->
      if readSaved()
        return
      # 用户已手动选择，忽略系统变化
      applyDark e.matches
      return
  if document.readyState == 'interactive' or document.readyState == 'complete'
    hideLoader()
  else
    document.addEventListener 'DOMContentLoaded', hideLoader
  setTimeout hideLoader, 3000
  console.log '%c Moesora %c 少女祈祷中... ', 'background:#f9a8d4;color:#fff;padding:2px 6px;border-radius:4px 0 0 4px', 'background:#333;color:#fff;padding:2px 6px;border-radius:0 4px 4px 0'
  return
# ---- 自包含图片灯箱（零依赖，不走任何 CDN；支持双击放大/拖动/长图滚动）----
# ---- 导航栏无感退出：Halo 对 JSON Accept 的 POST /logout 返回 204，主题随后回到首页 ----
do ->
  document.addEventListener 'submit', (e) ->
    form = e.target
    return unless form and form.matches and form.matches('.moe-user-logout-form')
    return unless window.fetch and window.FormData and window.URLSearchParams
    e.preventDefault()
    btn = form.querySelector('button[type="submit"]')
    btn.disabled = true if btn
    redirect = form.getAttribute('data-redirect') or '/'
    body = new URLSearchParams(new FormData(form))
    fetch(form.action,
      method: 'POST'
      credentials: 'same-origin'
      headers:
        'Accept': 'application/json'
        'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8'
        'X-Requested-With': 'XMLHttpRequest'
      body: body
    ).then((r) ->
      if !r.ok
        throw new Error('logout failed')
      window.location.replace redirect
      return
    ).catch ->
      if btn
        btn.disabled = false
      form.submit()
      return
    return
  return

window.MoesoraLightbox = do ->
  ov = undefined
  imgEl = undefined
  stage = undefined
  thumbsEl = undefined
  counterEl = undefined
  list = []
  idx = 0
  scale = 1
  tx = 0
  ty = 0
  rot = 0
  MAXZ = 8
  MINZ = 1
  STEP = 2.5
  # 指针/触摸状态
  dragging = false
  moved = false
  sx = 0
  sy = 0
  stx = 0
  sty = 0
  # 触摸双指
  pinchStart = 0
  pinchScale0 = 1
  lastTapAt = 0
  justDbl = false
  touchDblAt = 0
  swipeY0 = null

  applyT = ->
    return unless imgEl
    imgEl.style.transform = 'translate(' + tx.toFixed(1) + 'px,' + ty.toFixed(1) + 'px) scale(' + scale.toFixed(3) + ') rotate(' + rot + 'deg)'
    ov.classList.toggle 'zoomed', scale > 1.01
    return

  clampPan = ->
    # 限制平移范围，避免把图拖出可视区太远
    return unless imgEl
    r = stage.getBoundingClientRect()
    iw = imgEl.clientWidth * scale
    ih = imgEl.clientHeight * scale
    mx = Math.max(0, (iw - r.width) / 2 + 40)
    my = Math.max(0, (ih - r.height) / 2 + 40)
    tx = Math.max(-mx, Math.min(mx, tx))
    ty = Math.max(-my, Math.min(my, ty))
    return

  setZoom = (z, cx, cy) ->
    z = Math.max(MINZ, Math.min(MAXZ, z))
    if z == MINZ
      scale = 1; tx = 0; ty = 0
      applyT()
      return
    r = imgEl.getBoundingClientRect()
    ox = if cx? then cx else r.left + r.width / 2
    oy = if cy? then cy else r.top + r.height / 2
    cxImg = (ox - (r.left + r.width / 2)) / scale
    cyImg = (oy - (r.top + r.height / 2)) / scale
    ratio = z / scale
    tx = tx - cxImg * (ratio - 1) * scale
    ty = ty - cyImg * (ratio - 1) * scale
    scale = z
    clampPan()
    applyT()
    return

  reset = ->
    scale = 1; tx = 0; ty = 0; rot = 0
    applyT()
    return

  build = ->
    ov = document.createElement('div')
    ov.className = 'moe-lb'
    ov.innerHTML =
      '<div class="moe-lb-toolbar">' +
        '<span class="moe-lb-counter" data-role="counter"></span>' +
        '<span class="moe-lb-tools">' +
          '<button class="moe-lb-tool" data-act="zoomout" type="button" aria-label="缩小" title="缩小">&#8722;</button>' +
          '<button class="moe-lb-tool" data-act="zoomin" type="button" aria-label="放大" title="放大">&#43;</button>' +
          '<button class="moe-lb-tool" data-act="rotate" type="button" aria-label="旋转" title="旋转"><svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 2v6h-6"/><path d="M3 12a9 9 0 0 1 15-6.7L21 8"/><path d="M3 22v-6h6"/><path d="M21 12a9 9 0 0 1-15 6.7L3 16"/></svg></button>' +
          '<button class="moe-lb-tool moe-lb-close" data-act="close" type="button" aria-label="关闭" title="关闭">&times;</button>' +
        '</span>' +
      '</div>' +
      '<button class="moe-lb-nav moe-lb-prev" type="button" aria-label="上一张">&#10094;</button>' +
      '<div class="moe-lb-stage" data-role="stage">' +
        '<div class="moe-lb-spin" data-role="spin"></div>' +
        '<img class="moe-lb-img" alt=""/>' +
      '</div>' +
      '<button class="moe-lb-nav moe-lb-next" type="button" aria-label="下一张">&#10095;</button>' +
      '<div class="moe-lb-thumbs" data-role="thumbs"></div>' +
      '<div class="moe-lb-tip"><span class="moe-lb-tip-pc">滚轮/双击缩放 · 拖动查看 · ← → 切换 · Esc 关闭</span><span class="moe-lb-tip-mb">双指缩放 · 上下滑动切换 · 双击放大</span></div>'
    document.body.appendChild ov
    imgEl = ov.querySelector('.moe-lb-img')
    stage = ov.querySelector('[data-role="stage"]')
    thumbsEl = ov.querySelector('[data-role="thumbs"]')
    counterEl = ov.querySelector('[data-role="counter"]')

    # 工具栏按钮
    ov.querySelector('.moe-lb-toolbar').addEventListener 'click', (e) ->
      b = e.target.closest('[data-act]')
      return unless b
      act = b.getAttribute('data-act')
      switch act
        when 'close' then close()
        when 'zoomin' then setZoom(scale * 1.4)
        when 'zoomout' then setZoom(scale / 1.4)
        when 'rotate' then (rot = (rot + 90) % 360; applyT())
      return

    # 背景点击关闭（点到 stage 空白或遮罩）
    ov.addEventListener 'click', (e) ->
      if e.target == ov or e.target == stage
        close()
      return

    # 左右切换
    ov.querySelector('.moe-lb-prev').addEventListener 'click', (e) -> e.stopPropagation(); show idx - 1; return
    ov.querySelector('.moe-lb-next').addEventListener 'click', (e) -> e.stopPropagation(); show idx + 1; return

    # 双击缩放（以指针为锚点）
    imgEl.addEventListener 'dblclick', (e) ->
      e.preventDefault(); e.stopPropagation()
      # 触摸设备上 touch 双击已处理过，浏览器随后合成的 dblclick 要忽略，否则一放一缩
      if Date.now() - touchDblAt < 600
        return
      if scale > 1.01 then reset() else setZoom(STEP, e.clientX, e.clientY)
      return

    # 滚轮缩放
    stage.addEventListener 'wheel', ((e) ->
      e.preventDefault()
      f = if e.deltaY < 0 then 1.18 else 1 / 1.18
      setZoom(scale * f, e.clientX, e.clientY)
      return
    ), { passive: false }

    # 鼠标拖动平移
    imgEl.addEventListener 'mousedown', (e) ->
      return if scale <= 1.01
      dragging = true; moved = false
      sx = e.clientX; sy = e.clientY; stx = tx; sty = ty
      ov.classList.add 'dragging'
      e.preventDefault()
      return
    window.addEventListener 'mousemove', (e) ->
      return unless dragging
      tx = stx + (e.clientX - sx); ty = sty + (e.clientY - sy)
      moved = true
      clampPan(); applyT()
      return
    window.addEventListener 'mouseup', ->
      dragging = false
      ov and ov.classList.remove 'dragging'
      return

    # 触摸：单指滑动切换/拖动，双指捏合缩放，双击放大
    stage.addEventListener 'touchstart', ((e) ->
      if e.touches.length == 2
        dx = e.touches[0].clientX - e.touches[1].clientX
        dy = e.touches[0].clientY - e.touches[1].clientY
        pinchStart = Math.sqrt(dx * dx + dy * dy)
        pinchScale0 = scale
        swipeY0 = null
        dragging = false
      else if e.touches.length == 1
        t = e.touches[0]
        now = Date.now()
        if now - lastTapAt < 320
          # 双击：放大/还原（手机居中放大最稳，不传锚点）。标记为双击，touchend 不判滑动
          justDbl = true
          touchDblAt = now
          if scale > 1.01 then reset() else setZoom(STEP)
          lastTapAt = 0
          swipeY0 = null
          dragging = false
        else
          justDbl = false
          lastTapAt = now
          if scale > 1.01
            dragging = true; sx = t.clientX; sy = t.clientY; stx = tx; sty = ty
            swipeY0 = null
          else
            swipeY0 = t.clientY
      return
    ), { passive: true }
    stage.addEventListener 'touchmove', ((e) ->
      if e.touches.length == 2 and pinchStart
        dx = e.touches[0].clientX - e.touches[1].clientX
        dy = e.touches[0].clientY - e.touches[1].clientY
        d = Math.sqrt(dx * dx + dy * dy)
        mx = (e.touches[0].clientX + e.touches[1].clientX) / 2
        my = (e.touches[0].clientY + e.touches[1].clientY) / 2
        setZoom(pinchScale0 * (d / pinchStart), mx, my)
        e.preventDefault()
      else if e.touches.length == 1 and dragging
        t = e.touches[0]
        tx = stx + (t.clientX - sx); ty = sty + (t.clientY - sy)
        clampPan(); applyT()
        e.preventDefault()
      return
    ), { passive: false }
    stage.addEventListener 'touchend', ((e) ->
      if justDbl
        justDbl = false
        swipeY0 = null
        dragging = false
        pinchStart = 0
        return
      if swipeY0 != null and scale <= 1.01 and e.changedTouches.length
        dyv = e.changedTouches[0].clientY - swipeY0
        if Math.abs(dyv) > 60
          if dyv > 0 then show(idx - 1) else show(idx + 1)
      swipeY0 = null
      dragging = false
      pinchStart = 0
      return
    ), { passive: true }

    # 键盘
    document.addEventListener 'keydown', (e) ->
      return if !ov or !ov.classList.contains('show')
      switch e.key
        when 'Escape' then close()
        when 'ArrowLeft' then show idx - 1
        when 'ArrowRight' then show idx + 1
        when '+', '=' then setZoom(scale * 1.4)
        when '-', '_' then setZoom(scale / 1.4)
        when '0' then reset()
      return
    return

  buildThumbs = ->
    return unless thumbsEl
    if list.length < 2
      thumbsEl.innerHTML = ''
      thumbsEl.style.display = 'none'
      return
    thumbsEl.style.display = 'flex'
    html = ''
    i = 0
    while i < list.length
      html += '<img class="moe-lb-thumb" data-i="' + i + '" src="' + list[i] + '" alt="" loading="lazy"/>'
      i++
    thumbsEl.innerHTML = html
    thumbsEl.addEventListener 'click', ((e) ->
      t = e.target.closest('.moe-lb-thumb')
      return unless t
      e.stopPropagation()
      show parseInt(t.getAttribute('data-i'), 10)
      return
    ) unless thumbsEl._bound
    thumbsEl._bound = true
    return

  syncThumbActive = ->
    return unless thumbsEl
    Array::forEach.call thumbsEl.children, (c, k) ->
      c.classList.toggle 'is-active', k == idx
      if k == idx and c.scrollIntoView
        try c.scrollIntoView({ inline: 'center', block: 'nearest', behavior: 'smooth' }) catch e
      return
    return

  show = (i) ->
    return if !list.length
    idx = (i + list.length) % list.length
    reset()
    imgEl.classList.remove 'loaded'
    ov.classList.add 'loading'
    imgEl.onload = ->
      imgEl.classList.add 'loaded'
      ov.classList.remove 'loading'
      return
    imgEl.onerror = ->
      ov.classList.remove 'loading'
      return
    imgEl.src = list[idx]
    counterEl.textContent = (idx + 1) + ' / ' + list.length if counterEl
    ov.classList.toggle 'multi', list.length > 1
    syncThumbActive()
    return

  open = (nodeList, current) ->
    build() unless ov
    list = []
    start = 0
    Array::forEach.call nodeList or [], (n, k) ->
      list.push n.currentSrc or n.src
      start = k if n == current
      return
    return if !list.length
    buildThumbs()
    ov.classList.add 'show'
    document.body.style.overflow = 'hidden'
    show start
    return

  close = ->
    if ov
      ov.classList.remove 'show', 'zoomed', 'dragging', 'loading'
      document.body.style.overflow = ''
      reset()
    return

  {
    open: open
    close: close
  }

# ---- plugin-text-diagram 兼容：依赖插件提供 Mermaid，主题随明暗状态重渲染并在 PJAX 后重跑 ----
do ->
  SELECTOR = 'text-diagram[data-type="mermaid"]'
  MERMAID_SRC = '/plugins/text-diagram/assets/static/mermaid.min.js'
  rerenderTimer = null

  getDiagrams = ->
    document.querySelectorAll SELECTOR

  hasDiagram = ->
    !!document.querySelector SELECTOR

  prepareDiagrams = (reset) ->
    nodes = getDiagrams()
    Array::forEach.call nodes, (el) ->
      if !el.dataset.moeMermaidSource
        el.dataset.moeMermaidSource = (el.textContent or '').trim()
      if reset and el.dataset.moeMermaidSource
        el.textContent = el.dataset.moeMermaidSource
        el.removeAttribute 'data-processed'
      return
    nodes

  waitForMermaid = ->
    return Promise.resolve() if window.mermaid
    return window.__moeTextDiagramMermaidPromise if window.__moeTextDiagramMermaidPromise

    window.__moeTextDiagramMermaidPromise = new Promise (resolve, reject) ->
      settled = false
      timer = null
      timeout = null

      finish = ->
        return if settled or !window.mermaid
        settled = true
        clearInterval timer if timer
        clearTimeout timeout if timeout
        resolve()
        return

      fail = ->
        return if settled
        settled = true
        clearInterval timer if timer
        clearTimeout timeout if timeout
        reject()
        return

      scripts = document.querySelectorAll 'script[src*="/plugins/text-diagram/assets/static/mermaid.min.js"]'
      if !scripts.length
        script = document.createElement('script')
        script.defer = true
        script.src = MERMAID_SRC
        script.setAttribute 'data-moe-text-diagram', 'mermaid'
        document.head.appendChild script
        scripts = [script]

      Array::forEach.call scripts, (s) ->
        s.addEventListener 'load', finish, once: true
        s.addEventListener 'error', fail, once: true
        return

      timer = setInterval finish, 100
      timeout = setTimeout fail, 12000
      return

    window.__moeTextDiagramMermaidPromise

  resolveColor = (value, fallback) ->
    return fallback unless document.body
    probe = document.createElement('span')
    probe.style.cssText = 'position:absolute;left:-9999px;top:-9999px;visibility:hidden;color:' + fallback
    document.body.appendChild probe
    probe.style.color = value
    resolved = getComputedStyle(probe).color
    probe.remove()
    resolved or fallback

  themeVar = (styles, name, fallback) ->
    raw = (styles.getPropertyValue(name) or '').trim()
    resolveColor (if raw then raw else fallback), fallback

  buildMermaidConfig = ->
    rootStyle = getComputedStyle document.documentElement
    bodyStyle = if document.body then getComputedStyle(document.body) else null
    dark = document.documentElement.classList.contains('dark')
    theme = themeVar rootStyle, '--moe-theme', '#f9a8d4'
    text = themeVar rootStyle, '--moe-text', if dark then '#ece8f0' else '#3a3340'
    card = themeVar rootStyle, '--moe-card', if dark then '#2a2533' else '#ffffff'
    bg = themeVar rootStyle, '--moe-bg', if dark then '#18151f' else '#fff7fb'
    bg2 = themeVar rootStyle, '--moe-bg-2', if dark then '#221d2c' else '#fff1f7'
    border = themeVar rootStyle, '--moe-border', theme
    muted = themeVar rootStyle, '--moe-muted', if dark then '#9a90a8' else '#9a8fa6'
    danger = '#fb7185'
    font = if bodyStyle and bodyStyle.fontFamily then bodyStyle.fontFamily else '"PingFang SC","Microsoft YaHei",system-ui,-apple-system,sans-serif'
    startOnLoad: false
    theme: 'base'
    themeVariables:
      background: bg
      primaryColor: card
      primaryBorderColor: theme
      primaryTextColor: text
      secondaryColor: bg2
      secondaryBorderColor: border
      secondaryTextColor: text
      tertiaryColor: bg
      tertiaryBorderColor: border
      tertiaryTextColor: text
      mainBkg: card
      nodeBkg: card
      nodeBorder: theme
      nodeTextColor: text
      clusterBkg: bg2
      clusterBorder: border
      titleColor: text
      edgeLabelBackground: card
      lineColor: theme
      defaultLinkColor: theme
      textColor: text
      fontFamily: font
      noteBkgColor: bg2
      noteBorderColor: border
      noteTextColor: text
      actorBkg: card
      actorBorder: theme
      actorTextColor: text
      actorLineColor: theme
      signalColor: text
      signalTextColor: text
      labelBoxBkgColor: bg2
      labelBoxBorderColor: border
      labelTextColor: text
      loopTextColor: text
      activationBkgColor: bg2
      activationBorderColor: theme
      sequenceNumberColor: text
      sectionBkgColor: bg2
      altSectionBkgColor: card
      sectionBkgColor2: bg
      taskBkgColor: card
      taskBorderColor: border
      taskTextColor: text
      taskTextOutsideColor: text
      taskTextClickableColor: theme
      activeTaskBkgColor: bg2
      activeTaskBorderColor: theme
      gridColor: border
      doneTaskBkgColor: bg2
      doneTaskBorderColor: muted
      critBkgColor: bg2
      critBorderColor: danger
      todayLineColor: theme
      personBkg: card
      personBorder: theme
      labelBackgroundColor: bg2
      stateBkg: card
      stateBorder: theme
      stateLabelColor: text
      classText: text
      requirementBackground: card
      requirementBorderColor: theme
      requirementTextColor: text
      relationColor: theme
      relationLabelBackground: card
      relationLabelColor: text

  run = (reset = false) ->
    return unless hasDiagram()
    prepareDiagrams reset
    waitForMermaid().then(->
      return unless window.mermaid
      try
        window.mermaid.initialize buildMermaidConfig()
        result = window.mermaid.run
          querySelector: SELECTOR
        if result and typeof result.catch == 'function'
          result.catch ->
      catch e
      return
    ).catch ->
    return

  rerender = ->
    clearTimeout rerenderTimer if rerenderTimer
    rerenderTimer = setTimeout (->
      rerenderTimer = null
      run true
      return
    ), 0
    return

  # 主题脚本执行时内容已解析到当前位置，先缓存源码；否则插件自己的 DOMContentLoaded 渲染会把源码替换成 SVG。
  prepareDiagrams false
  document.addEventListener 'moesora:theme-change', rerender
  window.MoesoraTextDiagramInit = run
  if document.readyState == 'complete'
    setTimeout run, 0
  else
    window.addEventListener 'load', run
  return

window.MoesoraInitPage = ->
  # 首页文章卡片摘要：移除文本绘图代码，避免 Mermaid 源码出现在列表卡片里
  do ->
    diagramStart = /(?:^|[\s。！？；：:—\-–,，])((?:graph|flowchart)\s+(?:TB|TD|BT|RL|LR)|sequenceDiagram|classDiagram|stateDiagram(?:-v2)?|erDiagram|journey|gantt|pie\s+title|mindmap|timeline|gitGraph|quadrantChart|requirementDiagram|C4Context)\b/i

    cleanExcerpt = (txt) ->
      return '' unless txt
      s = String(txt).replace(/\s+/g, ' ').trim()
      m = diagramStart.exec s
      if m
        s = s.slice(0, m.index).replace(/[\s:：,，;；\-–—]+$/, '').trim()
      s

    document.querySelectorAll('.moe-post-excerpt').forEach (el) ->
      return if el.dataset.moeExcerptClean
      el.dataset.moeExcerptClean = '1'
      txt = cleanExcerpt el.textContent
      if txt
        el.textContent = txt
      else
        el.hidden = true
      return
    return

  # 文章字数统计 / 预计阅读时长
  do ->
    content = document.querySelector('.moe-post-content')
    meta = document.querySelector('.moe-article-meta')
    if content and meta and !meta.querySelector('.moe-meta-rt')
      txt = content.innerText or content.textContent or ''
      words = (txt.match(/[\u4e00-\u9fa5\u3040-\u30ff\uac00-\ud7a3]/g) or []).length + (txt.match(/[a-zA-Z0-9]+/g) or []).length
      if words > 0
        mins = Math.max(1, Math.round(words / 350))
        span = document.createElement('span')
        span.className = 'moe-meta-item moe-meta-rt'
        span.innerHTML = '<svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 5a2 2 0 0 1 2-2h9l5 5v11a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2z"/><path d="M9 9h6M9 13h6M9 17h3"/></svg><span>约 ' + words + ' 字 · ' + mins + ' 分钟</span>'
        meta.appendChild span
    return

  # 文章页 TOC + 代码复制
  do ->
    # 清理上一页的目录滚动监听，避免泄漏
    if window.__moeTocSpy
      window.removeEventListener 'scroll', window.__moeTocSpy
      window.removeEventListener 'resize', window.__moeTocSpy
      window.__moeTocSpy = null
    content = document.querySelector('.moe-post-content')
    tocCard = document.getElementById('moe-toc-card')
    toc = document.getElementById('moe-toc')
    if toc
      toc.innerHTML = ''
    if tocCard
      tocCard.hidden = true
    if content and toc and tocCard
      headings = content.querySelectorAll('h2, h3, h4')
      links = []
      if headings.length
        headings.forEach (h, i) ->
          if !h.id
            h.id = 'moe-h-' + i
          a = document.createElement('a')
          a.href = '#' + h.id
          a.textContent = h.textContent
          a.className = 'toc-' + h.tagName.toLowerCase()
          a.addEventListener 'click', (e) ->
            e.preventDefault()
            h.scrollIntoView
              behavior: 'smooth'
              block: 'start'
            history.replaceState null, '', '#' + h.id
            links.forEach (x) -> x.classList.remove 'active'
            a.classList.add 'active'
            return
          toc.appendChild a
          links.push a
          return
        tocCard.hidden = false

        spy = ->
          line = (parseInt(getComputedStyle(document.documentElement).getPropertyValue('--moe-nav-h')) or 0) + 24
          current = -1
          headings.forEach (h, i) ->
            if h.getBoundingClientRect().top <= line
              current = i
            return
          links.forEach (a, i) ->
            isOn = i == current
            a.classList.toggle 'active', isOn
            if isOn and toc.scrollHeight > toc.clientHeight + 4
              target = a.offsetTop - toc.clientHeight / 2 + a.offsetHeight / 2
              if toc.scrollTo
                toc.scrollTo top: Math.max(0, target), behavior: 'smooth'
              else
                toc.scrollTop = Math.max(0, target)
            return
          return

        ticking = false
        onScroll = ->
          return if ticking
          ticking = true
          requestAnimationFrame ->
            spy()
            ticking = false
            return
          return

        window.addEventListener 'scroll', onScroll, passive: true
        window.addEventListener 'resize', onScroll, passive: true
        window.__moeTocSpy = onScroll
        spy()
    if content
      mcfg = window.MoesoraConfig or {}
      foldLine = parseInt(mcfg.codeFoldLine or 0, 10) or 0
      foldImgH = parseInt(mcfg.imgFoldHeight or 0, 10) or 0
      # 内容增强：时间线代码块、彩色提示框、圆形头像（须在代码块美化之前，先把 timeline 代码块转走）
      if window.MoesoraContent
        window.MoesoraContent content
      content.querySelectorAll('pre').forEach (pre) ->
        if pre.dataset.moeCode
          return
        # 防重复
        codeEl = pre.querySelector('code')
        if !codeEl
          return
        pre.dataset.moeCode = '1'
        pre.classList.add 'moe-code'
        # 识别语言（pre 和 code 两处都查），无则用默认语言
        lang = ''

        pick = (cls) ->
          (cls or '').split(/\s+/).forEach (c) ->
            if /^language-/.test(c)
              lang = c.slice(9)
            else if /^lang-/.test(c)
              lang = c.slice(5)
            return
          return

        pick codeEl.className
        pick pre.className
        if !lang and mcfg.defaultCodeLang
          lang = mcfg.defaultCodeLang
        if lang and !/\blanguage-/.test(codeEl.className)
          codeEl.className = (codeEl.className + ' language-' + lang).trim()
          # 让 hljs 用这个语言
        if !lang
          lang = 'code'
        # 行号
        raw = (codeEl.textContent or '').replace(/\n+$/, '')
        codeEl.textContent = raw
        # 去尾部空行，保证行号对齐
        lineN = raw.split('\n').length or 1
        gutter = document.createElement('span')
        gutter.className = 'moe-code-ln'
        nums = ''
        i = 1
        while i <= lineN
          nums += i + (if i < lineN then '\n' else '')
          i++
        gutter.textContent = nums
        # 顶部 bar：三色点 + 语言名 + 折叠箭头 + 复制
        bar = document.createElement('div')
        bar.className = 'moe-code-bar'
        bar.innerHTML = '<span class="moe-code-dots"><i></i><i></i><i></i></span>' + '<span class="moe-code-lang"></span>' + '<span class="moe-code-tools">' + '<button type="button" class="moe-code-btn moe-code-fold" title="折叠/展开">' + '<svg viewBox="0 0 24 24" width="15" height="15" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><polyline points="6 9 12 15 18 9"/></svg>' + '</button>' + '<button type="button" class="moe-code-btn moe-copy-btn" title="复制">' + '<svg class="moe-ico-copy" viewBox="0 0 24 24" width="15" height="15" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="9" y="9" width="13" height="13" rx="2"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/></svg>' + '<svg class="moe-ico-done" viewBox="0 0 24 24" width="15" height="15" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>' + '</button>' + '</span>'
        bar.querySelector('.moe-code-lang').textContent = lang
        # 重组：bar + body(gutter + 可横向滚动的 code)
        body = document.createElement('div')
        body.className = 'moe-code-body'
        scroll = document.createElement('div')
        scroll.className = 'moe-code-scroll'
        scroll.appendChild codeEl
        body.appendChild gutter
        body.appendChild scroll
        pre.insertBefore bar, pre.firstChild
        pre.appendChild body
        # 复制（兼容非 HTTPS：clipboard 不可用/失败时回退 execCommand）
        copyBtn = bar.querySelector('.moe-copy-btn')
        showCopied = ->
          copyBtn.classList.add 'copied'
          setTimeout (->
            copyBtn.classList.remove 'copied'
            return
          ), 1400
          return
        fallbackCopy = (text) ->
          ta = document.createElement('textarea')
          ta.value = text
          ta.setAttribute 'readonly', ''
          ta.style.cssText = 'position:fixed;top:0;left:0;width:1px;height:1px;opacity:0;padding:0;border:0'
          document.body.appendChild ta
          ta.select()
          try
            ta.setSelectionRange 0, text.length
          catch e
          ok = false
          try
            ok = document.execCommand('copy')
          catch e2
            ok = false
          document.body.removeChild ta
          ok
        copyBtn.addEventListener 'click', ->
          text = codeEl.innerText
          if navigator.clipboard and navigator.clipboard.writeText and window.isSecureContext
            navigator.clipboard.writeText(text).then(showCopied).catch ->
              showCopied() if fallbackCopy(text)
              return
          else
            showCopied() if fallbackCopy(text)
          return
        # 折叠箭头：整块平滑收起 / 展开（视频里的效果）

        setCollapsed = (folded, animate) ->
          if folded
            if animate
              body.style.maxHeight = body.scrollHeight + 'px'
              requestAnimationFrame ->
                pre.classList.add 'moe-code-collapsed'
                body.style.maxHeight = '0px'
                return
            else
              pre.classList.add 'moe-code-collapsed'
              body.style.maxHeight = '0px'
          else
            pre.classList.remove 'moe-code-collapsed'
            body.style.maxHeight = body.scrollHeight + 'px'

            te = ->
              body.style.maxHeight = 'none'
              body.removeEventListener 'transitionend', te
              return

            body.addEventListener 'transitionend', te
          return

        bar.querySelector('.moe-code-fold').addEventListener 'click', ->
          setCollapsed !pre.classList.contains('moe-code-collapsed'), true
          return
        # 超过阈值默认收起
        if foldLine > 0 and lineN > foldLine
          setCollapsed true, false
        return
      # 正文长图折叠（高度超过设定值）
      if foldImgH > 0
        content.querySelectorAll('img').forEach (img) ->
          if img.dataset.moeImgFold
            return
          img.dataset.moeImgFold = '1'

          check = ->
            if img.closest('.moe-img-fold-wrap')
              return
            if img.offsetHeight <= foldImgH
              return
            target = img.closest('a') or img
            # 若灯箱已包了 <a> 就包住它
            wrap = document.createElement('div')
            wrap.className = 'moe-img-fold-wrap moe-img-fold'
            wrap.style.maxHeight = foldImgH + 'px'
            target.parentNode.insertBefore wrap, target
            wrap.appendChild target
            iexp = document.createElement('button')
            iexp.className = 'moe-fold-btn moe-img-fold-btn'
            iexp.type = 'button'
            iexp.textContent = '展开长图 ▾'
            iexp.addEventListener 'click', (e) ->
              e.preventDefault()
              folded = wrap.classList.toggle('moe-img-fold')
              wrap.style.maxHeight = if folded then foldImgH + 'px' else 'none'
              iexp.textContent = if folded then '展开长图 ▾' else '收起长图 ▴'
              return
            wrap.appendChild iexp
            return

          if img.complete and img.naturalHeight
            check()
          else
            img.addEventListener 'load', check
          return
      # 自包含图片灯箱：点击正文图片放大（不再依赖 Fancybox/CDN）
      if mcfg.enableLightbox != false and window.MoesoraLightbox
        lbImgs = []
        content.querySelectorAll('img').forEach (im) ->
          if im.closest('a')
            return
          # 用户自己加的链接图不拦截
          lbImgs.push im
          return
        lbImgs.forEach (im) ->
          if im.dataset.moeLb
            return
          im.dataset.moeLb = '1'
          im.style.cursor = 'zoom-in'
          im.addEventListener 'click', (e) ->
            e.preventDefault()
            window.MoesoraLightbox.open lbImgs, im
            return
          return
      # 视频播放器增强：接管正文 <video>（本地/外链 mp4/m3u8）
      if window.MoesoraVideo
        window.MoesoraVideo content
      # 音频播放器增强：接管正文 <audio>
      if window.MoesoraAudio
        window.MoesoraAudio content
    return
  # 恋爱墙在一起时长
  do ->

    tick = ->
      diff = Date.now() - start.getTime()
      if diff < 0
        diff = 0
      d = Math.floor(diff / 86400000)
      h = Math.floor(diff % 86400000 / 3600000)
      m = Math.floor(diff % 3600000 / 60000)
      s = Math.floor(diff % 60000 / 1000)
      el.textContent = '已经在一起 ' + d + ' 天 ' + h + ' 时 ' + m + ' 分 ' + s + ' 秒 ♡'
      return

    if window.__moeLoveTimer
      clearInterval window.__moeLoveTimer
      window.__moeLoveTimer = null
    el = document.getElementById('moe-love-time')
    if !el
      return
    startStr = el.getAttribute('data-start')
    if !startStr
      return
    start = new Date(startStr.replace(/-/g, '/'))
    if isNaN(start.getTime())
      return
    tick()
    window.__moeLoveTimer = setInterval(tick, 1000)
    return
  # 第三方库（高亮 / 公式 / 灯箱）对新正文重新生效
  # 评论：原生懒加载 / Twikoo / Waline（全部按需）
  do ->
    # Moesora 内置评论：moe-comment.js 暴露 window.MoesoraComment（幂等扫描 #moe-comment[data-name]，可被 Pjax 重复调用）
    if window.MoesoraComment
      try
        window.MoesoraComment()
      catch e

    # Moesora 留言墙：moe-wishes.js 暴露 window.MoesoraWishes（幂等扫描 #moe-wishes[data-name]，可被 Pjax 重复调用）
    if window.MoesoraWishes
      try
        window.MoesoraWishes()
      catch e

    loadScript = (src, cb) ->
      if !src
        return
      ex = document.querySelector('script[data-moe-cmt="' + src + '"]')
      if ex
        if ex.dataset.loaded
          cb and cb()
        else
          ex.addEventListener 'load', ->
            cb and cb()
            return
        return
      s = document.createElement('script')
      s.src = src
      s.setAttribute 'data-moe-cmt', src

      s.onload = ->
        s.dataset.loaded = '1'
        cb and cb()
        return

      document.body.appendChild s
      return

    tw = document.getElementById('tcomment')
    if tw and !tw.dataset.init
      tw.dataset.init = '1'
      twenv = tw.getAttribute('data-env')
      loadScript tw.getAttribute('data-js'), ->
        if window.twikoo and twenv
          try
            window.twikoo.init
              envId: twenv
              el: '#tcomment'
          catch e
        return
    wl = document.getElementById('waline')
    if wl and !wl.dataset.init
      wl.dataset.init = '1'
      wcss = wl.getAttribute('data-css')
      wsrv = wl.getAttribute('data-server')
      wjs = wl.getAttribute('data-js')
      if wcss and !document.querySelector('link[data-moe-cmt="' + wcss + '"]')
        l = document.createElement('link')
        l.rel = 'stylesheet'
        l.href = wcss
        l.setAttribute 'data-moe-cmt', wcss
        document.head.appendChild l
      if wjs and wsrv
        `import(wjs)`.then((W) ->
          initFn = W.init or W.default and W.default.init
          if initFn
            try
              initFn
                el: '#waline'
                serverURL: wsrv
            catch e
          return
        ).catch ->
    return
  # 相册分组标签 / 瞬间时间轴（点赞 + 评论）
  if typeof window.MoesoraFeed == 'function'
    window.MoesoraFeed()
  # 文章封面视差（滚动时封面背景轻微位移）
  do ->

    update = ->
      rect = hero.getBoundingClientRect()
      shift = Math.max(-40, Math.min(40, -rect.top * 0.12))
      hero.style.setProperty '--hero-shift', shift.toFixed(1) + 'px'
      ticking = false
      return

    if window.__moeHeroParallax
      window.removeEventListener 'scroll', window.__moeHeroParallax
      window.__moeHeroParallax = null
    hero = document.getElementById('moe-hero')
    if !hero
      return
    ticking = false

    onScroll = ->
      if !ticking
        ticking = true
        requestAnimationFrame update
      return

    window.addEventListener 'scroll', onScroll, passive: true
    window.__moeHeroParallax = onScroll
    update()
    return
  if typeof window.MoesoraLibsInit == 'function'
    window.MoesoraLibsInit()
  if typeof window.MoesoraTextDiagramInit == 'function'
    window.MoesoraTextDiagramInit()
  return

# 首次加载执行一次
do ->

  ready = (fn) ->
    if document.readyState != 'loading'
      fn()
    else
      document.addEventListener 'DOMContentLoaded', fn
    return

  ready ->
    window.MoesoraInitPage()
    return
  return
# ---- 第③步：二次元特效（原创实现） ----
do ->
  cfg = window.MoesoraConfig or {}
  reduce = window.matchMedia and window.matchMedia('(prefers-reduced-motion: reduce)').matches
  # ⚠ 这些共享变量必须在所有函数定义【之前】赋值。否则 CoffeeScript 会因为
  # 它们在 makeCanvas/resize 等函数体内的赋值早于 do-> 顶层赋值，而把它们
  # 局部化(shadow) —— 导致 ctx/canvas/W/H 写不进共享变量，frame() 里 ctx 永远
  # 为空、三种背景特效全部失效。务必保持在此处初始化。
  bg = cfg.effectsBg or 'none'
  mode = cfg.effectsBgMode or 'all'
  canvas = null
  ctx = null
  raf = null
  parts = []
  W = 0
  H = 0
  running = false

  shouldShow = ->
    if bg == 'none' or reduce
      return false
    dark = document.documentElement.classList.contains('dark')
    if mode == 'light'
      return !dark
    if mode == 'dark'
      return dark
    true

  resize = ->
    if canvas
      W = canvas.width = innerWidth
      H = canvas.height = innerHeight
    return

  makeCanvas = ->
    canvas = document.createElement('canvas')
    canvas.id = 'moe-fx'
    canvas.style.cssText = 'position:fixed;inset:0;width:100%;height:100%;pointer-events:none;z-index:-1'
    document.body.appendChild canvas
    ctx = canvas.getContext('2d')
    resize()
    window.addEventListener 'resize', resize
    return

  spawn = (initial) ->
    if bg == 'universe'
      return {
        x: Math.random() * W
        y: Math.random() * H
        r: Math.random() * 1.4 + 0.3
        a: Math.random() * 6.28
        tw: Math.random() * 0.04 + 0.01
      }
    {
      x: Math.random() * W
      y: if initial then Math.random() * H else -10
      r: if bg == 'snow' then Math.random() * 3 + 1 else Math.random() * 6 + 4
      sp: Math.random() * 1 + 0.6
      sw: Math.random() * 0.6 + 0.2
      ph: Math.random() * 6.28
      rot: Math.random() * 3.14
    }

  initParts = ->
    parts = []
    n = if bg == 'universe' then 140 else 60
    i = 0
    while i < n
      parts.push spawn(true)
      i++
    return

  frame = ->
    if !ctx
      return
    ctx.clearRect 0, 0, W, H
    dk = document.documentElement.classList.contains('dark')
    i = undefined
    p = undefined
    if bg == 'universe'
      i = 0
      while i < parts.length
        p = parts[i]
        p.a += p.tw
        al = (Math.sin(p.a) + 1) / 2
        ctx.beginPath()
        ctx.fillStyle = (if dk then 'rgba(255,255,255,' else 'rgba(120,100,190,') + (0.2 + al * 0.8) + ')'
        ctx.arc p.x, p.y, p.r, 0, 6.2832
        ctx.fill()
        i++
    else
      i = 0
      while i < parts.length
        p = parts[i]
        p.y += p.sp
        p.ph += 0.02
        p.x += Math.sin(p.ph) * p.sw
        p.rot += 0.01
        if bg == 'snow'
          ctx.beginPath()
          ctx.fillStyle = if dk then 'rgba(255,255,255,0.9)' else 'rgba(150,180,230,0.9)'
          ctx.arc p.x, p.y, p.r, 0, 6.2832
          ctx.fill()
        else
          ctx.save()
          ctx.translate p.x, p.y
          ctx.rotate p.rot
          ctx.fillStyle = 'rgba(249,168,212,0.85)'
          ctx.beginPath()
          ctx.ellipse 0, 0, p.r, p.r * 0.6, 0, 0, 6.2832
          ctx.fill()
          ctx.restore()
        if p.y > H + 10
          parts[i] = spawn(false)
        i++
    raf = requestAnimationFrame(frame)
    return

  start = ->
    if running
      return
    if !canvas
      makeCanvas()
    initParts()
    running = true
    frame()
    return

  stop = ->
    running = false
    if raf
      cancelAnimationFrame raf
    if ctx
      ctx.clearRect 0, 0, W, H
    return

  evaluate = ->
    if shouldShow()
      start()
    else
      stop()
    return

  heart = (x, y) ->
    el = document.createElement('span')
    el.textContent = '❤'
    el.style.cssText = 'position:fixed;left:' + x + 'px;top:' + y + 'px;transform:translate(-50%,-50%);color:#ff5a8a;font-size:' + (14 + Math.random() * 10) + 'px;pointer-events:none;z-index:9998;transition:all .8s ease-out;opacity:1'
    document.body.appendChild el
    requestAnimationFrame ->
      el.style.top = y - 60 + 'px'
      el.style.opacity = '0'
      return
    setTimeout (->
      el.remove()
      return
    ), 850
    return

  firework = (x, y) ->
    colors = [
      '#f9a8d4'
      '#c8a8ff'
      '#ffd86f'
      '#7fdfff'
      '#ff8fb0'
    ]
    i = 0
    while i < 12
      do (i) ->
        dot = document.createElement('span')
        ang = 6.2832 / 12 * i
        dist = 30 + Math.random() * 24
        dot.style.cssText = 'position:fixed;left:' + x + 'px;top:' + y + 'px;width:6px;height:6px;border-radius:50%;background:' + colors[i % colors.length] + ';pointer-events:none;z-index:9998;transition:all .6s ease-out;opacity:1'
        document.body.appendChild dot
        requestAnimationFrame ->
          dot.style.left = x + Math.cos(ang) * dist + 'px'
          dot.style.top = y + Math.sin(ang) * dist + 'px'
          dot.style.opacity = '0'
          return
        setTimeout (->
          dot.remove()
          return
        ), 650
        return
      i++
    return

  trailDot = (x, y) ->
    d = document.createElement('span')
    size = 6 + Math.random() * 6
    d.style.cssText = 'position:fixed;left:' + x + 'px;top:' + y + 'px;width:' + size + 'px;height:' + size + 'px;border-radius:50%;background:var(--moe-theme);transform:translate(-50%,-50%);pointer-events:none;z-index:9997;transition:all .7s ease-out;opacity:.85'
    document.body.appendChild d
    requestAnimationFrame ->
      d.style.top = y + 16 + Math.random() * 10 + 'px'
      d.style.opacity = '0'
      d.style.transform = 'translate(-50%,-50%) scale(.3)'
      return
    setTimeout (->
      d.remove()
      return
    ), 720
    return

  trailSakura = (x, y) ->
    s = document.createElement('span')
    s.textContent = '🌸'
    size = 10 + Math.random() * 8
    drift = (Math.random() - 0.5) * 40
    s.style.cssText = 'position:fixed;left:' + x + 'px;top:' + y + 'px;font-size:' + size + 'px;transform:translate(-50%,-50%);pointer-events:none;z-index:9997;transition:all 1.1s ease-out;opacity:.9'
    document.body.appendChild s
    requestAnimationFrame ->
      s.style.top = y + 50 + Math.random() * 30 + 'px'
      s.style.left = x + drift + 'px'
      s.style.opacity = '0'
      s.style.transform = 'translate(-50%,-50%) rotate(' + Math.random() * 360 + 'deg)'
      return
    setTimeout (->
      s.remove()
      return
    ), 1150
    return

  trailSnow = (x, y) ->
    s = document.createElement('span')
    s.textContent = '❅'
    size = 10 + Math.random() * 8
    drift = (Math.random() - 0.5) * 36
    s.style.cssText = 'position:fixed;left:' + x + 'px;top:' + y + 'px;font-size:' + size + 'px;color:#bcdcff;text-shadow:0 0 3px rgba(120,170,230,.5);transform:translate(-50%,-50%);pointer-events:none;z-index:9997;transition:all 1.2s ease-out;opacity:.95'
    document.body.appendChild s
    requestAnimationFrame ->
      s.style.top = y + 55 + Math.random() * 30 + 'px'
      s.style.left = x + drift + 'px'
      s.style.opacity = '0'
      s.style.transform = 'translate(-50%,-50%) rotate(' + Math.random() * 300 + 'deg)'
      return
    setTimeout (->
      s.remove()
      return
    ), 1250
    return

  if cfg.cursorStyle and cfg.cursorStyle != 'default'
    hotMap = { 'Pink-Paper': '0 0', 'Sakura': '16 16' }
    hs = hotMap[cfg.cursorStyle] or '6 4'
    url = '/themes/moesora/assets/dist/cursor/' + cfg.cursorStyle + '.png'
    cs = document.createElement('style')
    cs.textContent = 'html,body{cursor:url(' + url + ') ' + hs + ',auto}a,button,.moe-icon-btn,.moe-stat,.moe-chip{cursor:url(' + url + ') ' + hs + ',pointer}'
    document.head.appendChild cs
  # 背景特效（共享变量已在顶部初始化，切勿在此重复声明，否则又会触发 shadow）
  if bg != 'none' and !reduce
    evaluate()
    new MutationObserver(evaluate).observe document.documentElement,
      attributes: true
      attributeFilter: [ 'class' ]
    document.addEventListener 'visibilitychange', ->
      if document.hidden
        stop()
      else
        evaluate()
      return
  # 点击特效
  click = cfg.effectsClick or 'none'
  if click != 'none' and !reduce
    document.addEventListener 'click', (e) ->
      if click == 'heart'
        heart e.clientX, e.clientY
      else if click == 'firework'
        firework e.clientX, e.clientY
      return
  # 鼠标移动拖尾
  move = cfg.effectsMove or 'none'
  if move != 'none' and !reduce
    lastT = 0
    document.addEventListener 'mousemove', ((e) ->
      now = Date.now()
      if now - lastT < 40
        return
      lastT = now
      if move == 'dot'
        trailDot e.clientX, e.clientY
      else if move == 'sakura'
        trailSakura e.clientX, e.clientY
      else if move == 'snow'
        trailSnow e.clientX, e.clientY
      return
    ), passive: true
  return
# ---- Pjax 无刷新加载（默认关闭，由后台设置开启；只替换 #moe-pjax）----
do ->
  cfg = window.MoesoraConfig or {}

  barStart = ->
    if !bar
      return
    bar.style.transition = 'none'
    bar.style.width = '0'
    bar.style.opacity = '1'
    requestAnimationFrame ->
      bar.style.transition = 'width .5s ease'
      bar.style.width = '80%'
      return
    return

  barDone = ->
    if !bar
      return
    bar.style.width = '100%'
    setTimeout (->
      bar.style.opacity = '0'
      bar.style.transition = 'opacity .3s ease'
      bar.style.width = '0'
      return
    ), 250
    return

  isInternal = (a) ->
    if !a or !a.getAttribute
      return false
    if a.target and a.target != '_self'
      return false
    if a.hasAttribute('download') or a.hasAttribute('data-no-pjax')
      return false
    if a.getAttribute('rel') == 'external'
      return false
    href = a.getAttribute('href')
    if !href or href.charAt(0) == '#'
      return false
    if /^(mailto:|tel:|javascript:)/i.test(href)
      return false
    if a.origin != location.origin
      return false
    true

  # 把刚插入的 <script> 重新执行（innerHTML 不会自动执行脚本）

  runScripts = (root) ->
    olds = root.querySelectorAll('script')
    Array::forEach.call olds, (old) ->
      s = document.createElement('script')
      i = 0
      while i < old.attributes.length
        s.setAttribute old.attributes[i].name, old.attributes[i].value
        i++
      if !old.src
        s.textContent = old.textContent
      old.parentNode.replaceChild s, old
      return
    return

  setActive = ->
    document.querySelectorAll('.moe-nav-link').forEach (a) ->
      a.classList.toggle 'is-active', a.href == location.href
      return
    return

  load = (url, push) ->
    if loading
      return
    loading = true
    barStart()
    fetch(url,
      headers: 'X-Requested-With': 'Pjax'
      credentials: 'same-origin').then((r) ->
      if !r.ok
        throw new Error('bad')
      r.text()
    ).then((html) ->
      doc = (new DOMParser).parseFromString(html, 'text/html')
      nu = doc.querySelector(SEL)
      cur = document.querySelector(SEL)
      if !nu or !cur
        window.location.href = url
        return
      document.title = doc.title or document.title
      cur.innerHTML = nu.innerHTML
      runScripts cur
      if push
        history.pushState { moePjax: true }, '', url
      window.scrollTo 0, 0
      if typeof window.MoesoraInitPage == 'function'
        try
          window.MoesoraInitPage()
        catch e
      if typeof window.MoesoraNavState == 'function'
        try
          window.MoesoraNavState()
        catch e
      setActive()
      nav = document.querySelector('.moe-navbar')
      if nav
        nav.classList.remove 'nav-open'
      barDone()
      loading = false
      return
    ).catch ->
      window.location.href = url
      return
    return

  if !cfg.pjax
    return
  if !window.history or !history.pushState or !window.fetch or !window.DOMParser
    return
  SEL = '#moe-pjax'
  bar = document.getElementById('moe-pjax-bar')
  loading = false
  document.addEventListener 'click', (e) ->
    if e.metaKey or e.ctrlKey or e.shiftKey or e.altKey or e.button != 0
      return
    a = if e.target.closest then e.target.closest('a') else null
    if !isInternal(a)
      return
    e.preventDefault()
    if a.href == location.href
      return
    load a.href, true
    return
  window.addEventListener 'popstate', ->
    load location.href, false
    return
  history.replaceState { moePjax: true }, '', location.href
  return

# ===== 站外链接跳转确认页（点击正文站外链接 -> 倒计时确认） =====
do ->
  mcfg = window.MoesoraConfig or {}
  er = mcfg.extRedirect or {}
  return unless er.on
  rawDelay = parseInt(er.delay, 10)
  delay = if isNaN(rawDelay) then 9 else Math.max(0, rawDelay)
  siteName = mcfg.siteName or location.hostname
  whitelist = String(er.whitelist or '').split(/[,\n]/).map((s) -> s.trim().toLowerCase()).filter((s) -> s.length > 0)
  CONTENT_SEL = '.moe-post-content, .moe-moment-body'

  isExternal = (a) ->
    href = a.getAttribute('href') or ''
    return false unless /^https?:\/\//i.test(href)
    try
      u = new URL(a.href)
    catch e
      return false
    return false if u.hostname == location.hostname
    for w in whitelist
      return false if w and u.hostname.indexOf(w) != -1
    true

  ov = null; fillEl = null; countEl = null; pctEl = null; urlEl = null; goBtn = null
  timer = null; curUrl = ''; curNewTab = false

  stop = ->
    if timer then clearInterval(timer); timer = null
    return
  hide = ->
    stop()
    ov.setAttribute('hidden', '') if ov
    return
  doGo = ->
    return if goBtn.disabled
    url = curUrl; nt = curNewTab; hide()
    if nt then window.open(url, '_blank', 'noopener') else location.href = url
    return

  esc = (s) -> String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;')
  build = ->
    ov = document.createElement 'div'
    ov.className = 'moe-extlink-mask'
    ov.setAttribute 'hidden', ''
    ov.innerHTML = '<div class="moe-extlink" role="dialog" aria-modal="true">' +
      '<h2 class="moe-extlink-title">外部链接跳转</h2>' +
      '<p class="moe-extlink-sub">在您继续前往之前，请确认下方的链接</p>' +
      '<div class="moe-extlink-card">' +
        '<div class="moe-extlink-warn"><svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 3l7 3v6c0 4-3 7-7 9-4-2-7-5-7-9V6z"/></svg><span>您即将离开 ' + esc(siteName) + '</span></div>' +
        '<div class="moe-extlink-label">您将会被跳转到：</div>' +
        '<div class="moe-extlink-url"><span data-role="url"></span><svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 4h6v6"/><path d="M20 4l-9 9"/><path d="M19 14v5a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1V6a1 1 0 0 1 1-1h5"/></svg></div>' +
        '<div class="moe-extlink-bar"><div class="moe-extlink-fill" data-role="fill"></div></div>' +
        '<div class="moe-extlink-meta"><span data-role="count"></span><span data-role="pct">0%</span></div>' +
      '</div>' +
      '<div class="moe-extlink-btns"><button type="button" class="moe-extlink-cancel" data-role="cancel">取消</button><button type="button" class="moe-extlink-go" data-role="go" disabled>点击跳转</button></div>' +
    '</div>'
    document.body.appendChild ov
    fillEl = ov.querySelector('[data-role="fill"]')
    countEl = ov.querySelector('[data-role="count"]')
    pctEl = ov.querySelector('[data-role="pct"]')
    urlEl = ov.querySelector('[data-role="url"]')
    goBtn = ov.querySelector('[data-role="go"]')
    ov.querySelector('[data-role="cancel"]').addEventListener 'click', hide
    goBtn.addEventListener 'click', doGo
    ov.addEventListener 'click', (e) -> hide() if e.target == ov
    document.addEventListener 'keydown', (e) -> hide() if e.key == 'Escape' and ov and not ov.hasAttribute('hidden')
    return

  show = (url, newTab) ->
    build() unless ov
    curUrl = url; curNewTab = newTab
    urlEl.textContent = url
    goBtn.disabled = true
    fillEl.style.width = '0%'
    pctEl.textContent = '0%'
    countEl.textContent = delay + ' 秒后可跳转'
    ov.removeAttribute 'hidden'
    if delay <= 0
      fillEl.style.width = '100%'
      pctEl.textContent = '100%'
      countEl.textContent = '现在可以跳转'
      goBtn.disabled = false
      stop()
      return
    remain = delay
    stop()
    timer = setInterval (->
      remain -= 1
      pct = Math.round((delay - remain) / delay * 100)
      fillEl.style.width = pct + '%'
      pctEl.textContent = pct + '%'
      if remain <= 0
        countEl.textContent = '现在可以跳转'
        goBtn.disabled = false
        stop()
      else
        countEl.textContent = remain + ' 秒后可跳转'
      return), 1000
    return

  document.addEventListener 'click', (e) ->
    return unless e.target and e.target.closest
    a = e.target.closest('a[href]')
    return unless a
    return unless a.closest(CONTENT_SEL)
    return if a.hasAttribute('data-no-redirect')
    return unless isExternal(a)
    e.preventDefault()
    show a.href, (a.target == '_blank')
    return
  return
