@echo off
chcp 65001 >nul 2>&1
title Claude Code 环境检测工具
setlocal enabledelayedexpansion

echo.
echo  ============================================
echo    Claude Code 国内安装环境检测 v1.0
echo    帮你 3 分钟定位问题，省 3 小时排错
echo  ============================================
echo.

set PASS=0
set FAIL=0
set WARN=0

:: ── 1. Node.js ──
echo  [1/7] 检测 Node.js ...
where node >nul 2>&1
if %errorlevel%==0 (
    for /f "tokens=*" %%i in ('node -v 2^>^&1') do set NODE_VER=%%i
    echo    ✅ Node.js 已安装: !NODE_VER!
    set /a PASS+=1

    :: Check version >= 18
    for /f "tokens=1,2,3 delims=v." %%a in ("!NODE_VER!") do (
        if %%a LSS 18 (
            echo    ⚠️  Node.js 版本过低，请升级到 v18 或以上
            echo    👉 下载: https://nodejs.org
            set /a WARN+=1
        )
    )
) else (
    echo    ❌ Node.js 未安装
    echo    👉 下载: https://nodejs.org 选 LTS 版本
    echo    👉 安装时勾选 "Add to PATH"
    set /a FAIL+=1
)
echo.

:: ── 2. Python ──
echo  [2/7] 检测 Python ...
where python >nul 2>&1
if %errorlevel%==0 (
    for /f "tokens=*" %%i in ('python --version 2^>^&1') do set PY_VER=%%i
    echo    ✅ Python 已安装: !PY_VER!
    set /a PASS+=1
) else (
    where python3 >nul 2>&1
    if !errorlevel!==0 (
        for /f "tokens=*" %%i in ('python3 --version 2^>^&1') do set PY_VER=%%i
        echo    ✅ Python3 已安装: !PY_VER!
        set /a PASS+=1
    ) else (
        echo    ❌ Python 未安装
        echo    👉 下载: https://www.python.org/downloads/
        echo    👉 安装时勾选 "Add python.exe to PATH"
        set /a FAIL+=1
    )
)
echo.

:: ── 3. npm ──
echo  [3/7] 检测 npm ...
where npm >nul 2>&1
if %errorlevel%==0 (
    for /f "tokens=*" %%i in ('npm -v 2^>^&1') do set NPM_VER=%%i
    echo    ✅ npm 已安装: v!NPM_VER!
    set /a PASS+=1
) else (
    echo    ❌ npm 未安装（通常随 Node.js 一起安装）
    set /a FAIL+=1
)
echo.

:: ── 4. Claude Code ──
echo  [4/7] 检测 Claude Code ...
where claude >nul 2>&1
if %errorlevel%==0 (
    for /f "tokens=*" %%i in ('claude --version 2^>^&1') do set CLAUDE_VER=%%i
    echo    ✅ Claude Code 已安装: !CLAUDE_VER!
    set /a PASS+=1
    goto :check_claude_done
)
:: Try direct paths
if exist "%APPDATA%\npm\claude.cmd" (
    echo    ⚠️  Claude Code 已安装但 PATH 未配置
    echo    👉 把此路径加入系统 PATH: %APPDATA%\npm
    set /a WARN+=1
    goto :check_claude_done
)
if exist "%APPDATA%\npm\node_modules\@anthropic-ai\claude-code\bin\claude.exe" (
    echo    ⚠️  Claude Code 已安装但 claude.cmd 不在 PATH
    echo    👉 运行: npm install -g @anthropic-ai/claude-code
    set /a WARN+=1
    goto :check_claude_done
)
echo    ❌ Claude Code 未安装
echo    👉 安装命令: npm install -g @anthropic-ai/claude-code
set /a FAIL+=1
:check_claude_done
echo.

:: ── 5. PROXY ──
echo  [5/7] 检测代理配置 ...
:: Check environment variables
if not "%HTTP_PROXY%"=="" (
    echo    ✅ HTTP_PROXY: %HTTP_PROXY%
    set /a PASS+=1
    goto :proxy_done
)
if not "%HTTPS_PROXY%"=="" (
    echo    ✅ HTTPS_PROXY: %HTTPS_PROXY%
    set /a PASS+=1
    goto :proxy_done
)
if not "%http_proxy%"=="" (
    echo    ✅ http_proxy: %http_proxy%
    set /a PASS+=1
    goto :proxy_done
)
:: Check git proxy
git config --global http.proxy >nul 2>&1
if %errorlevel%==0 (
    for /f "tokens=*" %%i in ('git config --global http.proxy 2^>^&1') do (
        if not "%%i"=="" (
            echo    ✅ Git 代理: %%i
            set /a PASS+=1
            goto :proxy_done
        )
    )
)
:: Check common local proxy ports
for %%p in (7890 7891 7897 10809 1080 8118 8888 8080) do (
    netstat -ano 2>nul | findstr "127.0.0.1:%%p" >nul 2>&1
    if !errorlevel!==0 (
        echo    ✅ 检测到本地代理端口: 127.0.0.1:%%p
        echo    👉 终端里执行这个激活代理:
        echo       set HTTP_PROXY=http://127.0.0.1:%%p
        echo       set HTTPS_PROXY=http://127.0.0.1:%%p
        set /a PASS+=1
        goto :proxy_done
    )
)
echo    ⚠️  未检测到代理（国内访问 GitHub 可能不通）
echo    👉 如果你有用 Clash/V2Ray，确保它开着
echo    👉 终端代理设置: set HTTP_PROXY=http://127.0.0.1:你的端口
set /a WARN+=1
:proxy_done
echo.

:: ── 6. GitHub Connectivity ──
echo  [6/7] 检测 GitHub 连通性 ...
curl -s -o nul -w "%%{http_code}" --connect-timeout 5 https://github.com >nul 2>&1
if %errorlevel%==0 (
    echo    ✅ GitHub 可访问
    set /a PASS+=1
) else (
    curl -s -o nul -w "%%{http_code}" --connect-timeout 5 https://github.com --proxy http://127.0.0.1:7897 >nul 2>&1
    if !errorlevel!==0 (
        echo    ✅ GitHub 通过 127.0.0.1:7897 可访问
        echo    👉 你需要在终端设置代理后再用 Claude Code
        set /a PASS+=1
    ) else (
        curl -s -o nul -w "%%{http_code}" --connect-timeout 5 https://github.com --proxy http://127.0.0.1:7890 >nul 2>&1
        if !errorlevel!==0 (
            echo    ✅ GitHub 通过 127.0.0.1:7890 可访问
            set /a PASS+=1
        ) else (
            echo    ❌ GitHub 无法访问（被墙）
            echo    👉 解决方案:
            echo       1. 打开 Clash/V2Ray/加速器
            echo       2. 终端执行: set HTTP_PROXY=http://127.0.0.1:你的代理端口
            echo       3. 或者配置 Git 代理: git config --global http.proxy http://127.0.0.1:端口
            set /a FAIL+=1
        )
    )
)
echo.

:: ── 7. Git ──
echo  [7/7] 检测 Git ...
where git >nul 2>&1
if %errorlevel%==0 (
    for /f "tokens=*" %%i in ('git --version 2^>^&1') do set GIT_VER=%%i
    echo    ✅ Git 已安装: !GIT_VER!
    set /a PASS+=1
) else (
    echo    ❌ Git 未安装
    echo    👉 下载: https://git-scm.com/download/win
    set /a FAIL+=1
)
echo.

:: ── Report ──
echo  ============================================
echo               检测报告
echo  ============================================
echo    ✅ 通过: !PASS! 项
echo    ❌ 失败: !FAIL! 项
echo    ⚠️  警告: !WARN! 项
echo.
if !FAIL! EQU 0 (
    if !WARN! EQU 0 (
        echo  🎉 环境完美！你的 Claude Code 应该可以正常使用
        echo    如果还有问题，可能是 API Key 或账号问题
    ) else (
        echo  🔧 基本可用，但有 !WARN! 个警告需要处理
        echo    解决上面标注 👉 的步骤即可
    )
) else (
    echo  🛠️  有 !FAIL! 个问题需要修复
    echo    按上面 👉 的提示操作
    echo    如果不想自己折腾 → 远程代装 ¥99
    echo    微信: [你的微信号]
)
echo.
echo  ============================================
echo   需要帮助？评论区找我 / 私信
echo  ============================================
pause
