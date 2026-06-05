
# ============================================================
# AI 规则自动部署脚本
# 支持: Kimi Code CLI + Claude Code for VS Code
# 支持多项目批量部署
# ============================================================

# 获取当前脚本路径（兼容 -File 和 dot-sourcing 方式调用）
$scriptPath = $PSCommandPath
if (-not $scriptPath) {
    $scriptPath = $MyInvocation.MyCommand.Path
}

$scriptDir = Split-Path -Parent $scriptPath
$configPath = Join-Path $scriptDir "setup-ai-rules.json"

# ---------- 读取配置 ----------
if (-not (Test-Path $configPath)) {
    Write-Host "[错误] 配置文件不存在: $configPath" -ForegroundColor Red
    Read-Host "按 Enter 退出"
    exit 1
}

$config = Get-Content -Raw $configPath -Encoding UTF8 | ConvertFrom-Json
$sourceRepo         = $config.sourceRepoPath
$targetProjectPaths = $config.targetProjectPaths
$aiTools            = $config.aiTools
$defaultRule        = $config.defaultRule

# ---------- 验证配置 ----------
if (-not $targetProjectPaths -or $targetProjectPaths.Count -eq 0) {
    Write-Host "[错误] targetProjectPaths 为空，请至少配置一个目标项目路径" -ForegroundColor Red
    Read-Host "按 Enter 退出"
    exit 1
}

# sourceRepoPath 如果不存在或为空，则使用当前脚本所在目录
if (-not $sourceRepo -or -not (Test-Path $sourceRepo)) {
    if ($sourceRepo) {
        Write-Host "[警告] sourceRepoPath 不存在: $sourceRepo，回退为脚本所在目录" -ForegroundColor Yellow
    } else {
        Write-Host "[提示] sourceRepoPath 未配置，使用脚本所在目录作为源仓库" -ForegroundColor Yellow
    }
    $sourceRepo = $scriptDir
}

# ---------- 查找所有 mini.md ----------
$miniFiles = Get-ChildItem -Path $sourceRepo -Recurse -Filter "*.mini.md"
if (-not $miniFiles) {
    Write-Host "[错误] 在源仓库中找不到任何 .mini.md 文件" -ForegroundColor Red
    Read-Host "按 Enter 退出"
    exit 1
}

# ---------- Skill 元数据（中文名 + 描述） ----------
$skillMeta = @{
    "a-philosophy-of-software-design.mini.md" = @{
        Name = "游戏系统模块拆分"
        Description = "John Ousterhout《A Philosophy of Software Design》。适用于拆分战斗/背包/任务等游戏系统、API 设计、信息隐藏和消除浅层抽象。"
    }
    "clean-architecture.mini.md" = @{
        Name = "游戏架构分层设计"
        Description = "Robert C. Martin《Clean Architecture》。适用于 UI层/逻辑层/数据层/网络层的依赖规则、分层边界、业务策略与技术细节分离。"
    }
    "clean-code.mini.md" = @{
        Name = "代码命名与整洁规范"
        Description = "Robert C. Martin《Clean Code》。适用于日常编码、命名规范、函数设计、代码审查和保持可读性。"
    }
    "code-complete.mini.md" = @{
        Name = "函数设计与防御编程"
        Description = "Steve McConnell《Code Complete》。适用于例程设计、变量管理、防御式编程和防崩溃实现决策。"
    }
    "designing-data-intensive-applications.mini.md" = @{
        Name = "游戏数据一致性设计"
        Description = "Martin Kleppmann《Designing Data-Intensive Applications》。适用于玩家存档、排行榜、大量在线数据、事件流、一致性语义和 schema 演进。"
    }
    "domain-driven-design.mini.md" = @{
        Name = "按游戏业务建模"
        Description = "Eric Evans《Domain-Driven Design》。适用于按游戏业务（战斗/经济/任务/社交）建模、统一团队语言、划分系统边界和战略设计。"
    }
    "domain-driven-design-distilled.mini.md" = @{
        Name = "轻量游戏模块拆分"
        Description = "Vaughn Vernon《Domain-Driven Design Distilled》。适用于轻量级游戏系统拆分、子域划分、上下文映射和基础战术模式。"
    }
    "implementing-domain-driven-design.mini.md" = @{
        Name = "实现游戏领域代码"
        Description = "Vaughn Vernon《Implementing Domain-Driven Design》。适用于实现游戏实体、聚合根、领域事件、系统集成和应用架构落地。"
    }
    "patterns-of-enterprise-application-architecture.mini.md" = @{
        Name = "服务端分层架构"
        Description = "Martin Fowler《Patterns of Enterprise Application Architecture》。适用于游戏后端架构选型、数据持久化、事务、服务层和避免意外混合职责。"
    }
    "refactoring.mini.md" = @{
        Name = "老代码安全重构"
        Description = "Martin Fowler《Refactoring》。适用于安全改善老代码结构、识别代码坏味道、保持重构与功能变更分离。"
    }
    "refactoring-guru.mini.md" = @{
        Name = "重构具体手法"
        Description = "Refactoring.Guru。适用于诊断代码异味、选择安全重构手法、保留行为、避免失控的重新设计。"
    }
    "release-it.mini.md" = @{
        Name = "上线稳定性与故障防护"
        Description = "Michael T. Nygard《Release It!》。适用于游戏服务器发布、生产环境稳定性、熔断、舱壁、背压、可观测性和部署行为。"
    }
    "the-pragmatic-programmer.mini.md" = @{
        Name = "技术决策与工程实践"
        Description = "Andrew Hunt & David Thomas《The Pragmatic Programmer》。适用于技术选型、通用工程实践、DRY、正交性、快速反馈和可适应性。"
    }
    "working-effectively-with-legacy-code.mini.md" = @{
        Name = "遗留代码安全改造"
        Description = "Michael Feathers《Working Effectively with Legacy Code》。适用于接手老项目、改造遗留代码、编写特征测试、打破依赖和逐步重获控制权。"
    }
}

# ---------- 生成带 frontmatter 的 SKILL.md 内容 ----------
function New-SkillContent($sourceFile, $meta) {
    $original = Get-Content -Raw $sourceFile -Encoding UTF8
    $frontmatter = "---`nname: $($meta.Name)`ndescription: $($meta.Description)`n---`n`n"
    return $frontmatter + $original
}

# ---------- 清理旧 Skill（避免改名后残留） ----------
function Clear-ManagedSkills($skillsRoot) {
    if (-not (Test-Path $skillsRoot)) { return }
    Get-ChildItem -Path $skillsRoot -Directory -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force
    Write-Host "    [清理] 已清空 $skillsRoot" -ForegroundColor DarkGray
}

# ---------- Kimi 全局 Skills 路径 (C盘通用) ----------
$kimiGlobalSkills = "C:\Users\$env:USERNAME\AppData\Roaming\Code\User\globalStorage\moonshot-ai.kimi-code\bin\kimi\_internal\kimi_cli\skills"

# ---------- 打印信息 ----------
Write-Host ""
Write-Host "========== AI 规则自动部署工具 ==========" -ForegroundColor Green
Write-Host "源仓库:     $sourceRepo"
Write-Host "目标项目:   $($targetProjectPaths -join ', ')"
Write-Host "AI工具:     $($aiTools -join ', ')"
Write-Host "默认规则:   $defaultRule"
Write-Host "=========================================" -ForegroundColor Green
Write-Host ""

# ---------- 查找默认规则 ----------
$defaultFile = $miniFiles | Where-Object { $_.Name -eq $defaultRule } | Select-Object -First 1
if (-not $defaultFile) {
    Write-Host "[错误] 找不到默认规则文件: $defaultRule" -ForegroundColor Red
    Read-Host "按 Enter 退出"
    exit 1
}

# ============================================================
# 0. 部署 Kimi 全局 Skills (只需一次，所有项目共享)
# ============================================================
Write-Host "---------- 部署 Kimi 全局 Skills ----------" -ForegroundColor DarkCyan
Write-Host ""

if (Test-Path (Split-Path $kimiGlobalSkills -Parent)) {
    Clear-ManagedSkills $kimiGlobalSkills
    foreach ($file in $miniFiles) {
        $meta = $skillMeta[$file.Name]
        if (-not $meta) { $meta = @{ Name = $file.BaseName; Description = "AI coding skill based on $($file.BaseName)" } }
        $skillDir = Join-Path $kimiGlobalSkills $meta.Name
        $skillMdPath = Join-Path $skillDir "SKILL.md"
        try {
            New-Item -ItemType Directory -Path $skillDir -Force | Out-Null
            $content = New-SkillContent $file.FullName $meta
            Set-Content -Path $skillMdPath -Value $content -Encoding UTF8
            Write-Host "[Kimi全局] $($meta.Name)" -ForegroundColor DarkCyan
        } catch {
            Write-Host "[Kimi全局] $($meta.Name) 失败: $_" -ForegroundColor Red
        }
    }
} else {
    Write-Host "[Kimi全局] 跳过 (找不到全局skills目录)" -ForegroundColor DarkGray
}

Write-Host ""

# ============================================================
# 逐个部署目标项目
# ============================================================
foreach ($targetProject in $targetProjectPaths) {

    if (-not (Test-Path $targetProject)) {
        New-Item -ItemType Directory -Path $targetProject -Force | Out-Null
        Write-Host "[提示] 已创建目标项目目录: $targetProject" -ForegroundColor Yellow
    }

    Write-Host "=========================================" -ForegroundColor Green
    Write-Host "  正在部署项目: $targetProject" -ForegroundColor Green
    Write-Host "=========================================" -ForegroundColor Green
    Write-Host ""

    # ---------- 1. 注入默认规则到 AGENTS.md ----------
    $agentsMdPath = Join-Path $targetProject "AGENTS.md"
    $defaultContent = Get-Content -Raw $defaultFile.FullName -Encoding UTF8
    # 取 defaultRule 内容中第一行 "# " 开头的标题作为指纹，用于检测是否已包含
    $fingerprint = ($defaultContent -split "`n" | Where-Object { $_ -match '^#\s+' } | Select-Object -First 1).Trim()

    if (-not (Test-Path $agentsMdPath)) {
        # 文件不存在，直接创建
        Set-Content -Path $agentsMdPath -Value $defaultContent -Encoding UTF8
        Write-Host "[OK] AGENTS.md 已创建，注入默认规则: $defaultRule" -ForegroundColor Green
    } else {
        # 文件已存在，检测是否已包含默认规则的核心内容（用标题指纹匹配）
        $existingAgents = Get-Content -Raw $agentsMdPath -Encoding UTF8
        if ($fingerprint -and $existingAgents -match [regex]::Escape($fingerprint)) {
            Write-Host "[跳过] AGENTS.md 已包含默认规则内容，不处理" -ForegroundColor Yellow
        } else {
            # 内容不存在，追加到文件顶部
            $newAgents = $defaultContent + "`n`n" + $existingAgents
            Set-Content -Path $agentsMdPath -Value $newAgents -Encoding UTF8
            Write-Host "[OK] AGENTS.md 已存在，默认规则已追加到顶部" -ForegroundColor Green
        }
    }

    # ---------- 2. Claude Code: 创建/更新 CLAUDE.md ----------
    if ($aiTools -contains "claude") {
        $claudeMdPath = Join-Path $targetProject "CLAUDE.md"
        $claudeContent = "@AGENTS.md`n`n## Claude Code`n`n- Use skills for long procedures and checklists.`n- Use scoped rules for subsystem-specific guidance."

        if (-not (Test-Path $claudeMdPath)) {
            # 文件不存在，直接创建
            Set-Content -Path $claudeMdPath -Value $claudeContent -Encoding UTF8
            Write-Host "[OK] CLAUDE.md 已创建 (引用 AGENTS.md)" -ForegroundColor Green
        } else {
            # 文件已存在，检测是否已引用 AGENTS.md
            $existingClaude = Get-Content -Raw $claudeMdPath -Encoding UTF8
            if ($existingClaude -match '@AGENTS\.md') {
                Write-Host "[跳过] CLAUDE.md 已包含 @AGENTS.md 引用，不处理" -ForegroundColor Yellow
            } else {
                # 不存在则追加到文件顶部
                $newClaude = $claudeContent + "`n`n" + $existingClaude
                Set-Content -Path $claudeMdPath -Value $newClaude -Encoding UTF8
                Write-Host "[OK] CLAUDE.md 已存在，@AGENTS.md 引用已追加到顶部" -ForegroundColor Green
            }
        }
    }

    # ---------- 3. 部署项目级 Skills ----------
    Write-Host ""
    Write-Host "  正在部署项目 Skills..." -ForegroundColor Cyan
    Write-Host ""

    if ($aiTools -contains "kimi") {
        $kimiProjectSkills = Join-Path $targetProject ".agents\skills"
        Clear-ManagedSkills $kimiProjectSkills
    }
    if ($aiTools -contains "claude") {
        $claudeProjectSkills = Join-Path $targetProject ".claude\skills"
        Clear-ManagedSkills $claudeProjectSkills
    }

    foreach ($file in $miniFiles) {
        $meta = $skillMeta[$file.Name]
        if (-not $meta) { $meta = @{ Name = $file.BaseName; Description = "AI coding skill based on $($file.BaseName)" } }

        # --- Kimi 项目级 Skills ---
        if ($aiTools -contains "kimi") {
            $skillDir = Join-Path $targetProject ".agents\skills\$($meta.Name)"
            $skillMdPath = Join-Path $skillDir "SKILL.md"
            try {
                New-Item -ItemType Directory -Path $skillDir -Force | Out-Null
                $content = New-SkillContent $file.FullName $meta
                Set-Content -Path $skillMdPath -Value $content -Encoding UTF8
                Write-Host "  [Kimi项目] $($meta.Name)" -ForegroundColor Cyan
            } catch {
                Write-Host "  [Kimi项目] $($meta.Name) 失败: $_" -ForegroundColor Red
            }
        }

        # --- Claude 项目级 Skills ---
        if ($aiTools -contains "claude") {
            $skillDir = Join-Path $targetProject ".claude\skills\$($meta.Name)"
            $skillMdPath = Join-Path $skillDir "SKILL.md"
            try {
                New-Item -ItemType Directory -Path $skillDir -Force | Out-Null
                $content = New-SkillContent $file.FullName $meta
                Set-Content -Path $skillMdPath -Value $content -Encoding UTF8
                Write-Host "  [Claude项目] $($meta.Name)" -ForegroundColor Magenta
            } catch {
                Write-Host "  [Claude项目] $($meta.Name) 失败: $_" -ForegroundColor Red
            }
        }
    }

    Write-Host ""
    Write-Host "  项目 [$targetProject] 部署完成" -ForegroundColor Green
    Write-Host ""
}

# ============================================================
# 完成汇总
# ============================================================
Write-Host "========== 全部部署完成 ==========" -ForegroundColor Green
Write-Host ""

if (Test-Path (Split-Path $kimiGlobalSkills -Parent)) {
    Write-Host "Kimi Code 全局 Skills (所有项目可用):" -ForegroundColor Green
    Write-Host "  $kimiGlobalSkills" -ForegroundColor DarkGray
    Write-Host ""
}

foreach ($targetProject in $targetProjectPaths) {
    if ($aiTools -contains "kimi") {
        Write-Host "Kimi Code 项目配置 [$targetProject]:" -ForegroundColor Green
        Write-Host "  AGENTS.md    -> $targetProject" -ForegroundColor DarkGray
        Write-Host "  Skills       -> $(Join-Path $targetProject '.agents\skills')" -ForegroundColor DarkGray
    }
    if ($aiTools -contains "claude") {
        Write-Host "Claude Code 项目配置 [$targetProject]:" -ForegroundColor Green
        Write-Host "  AGENTS.md    -> $targetProject" -ForegroundColor DarkGray
        Write-Host "  CLAUDE.md    -> $targetProject" -ForegroundColor DarkGray
        Write-Host "  Skills       -> $(Join-Path $targetProject '.claude\skills')" -ForegroundColor DarkGray
    }
    Write-Host ""
}

Write-Host "提示: 如果 Claude Code 仍未显示 Skills，请尝试:" -ForegroundColor Yellow
Write-Host "  1. 在 VS Code 中按 Ctrl+Shift+P -> 'Developer: Reload Window'" -ForegroundColor Yellow
Write-Host "  2. 或重启 Claude Code 扩展" -ForegroundColor Yellow
Write-Host ""

Read-Host "按 Enter 退出"
