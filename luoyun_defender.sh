#!/system/bin/sh

# ============================================================
# 洛云 · 声波扫描仪 · 免解锁防砖卫士
# ============================================================
#
# 原创作者：酷安@素冬
# 二次创作：极夜System（AI deepseek 参与）
# 版本：4.0
# 
# Copyright (C) 2026 酷安@素冬 @极夜System
# 
# 本程序是自由软件：你可以根据自由软件基金会发布的 GNU 通用公共许可证
# 的条款重新分发和/或修改它，许可证版本为 3，或（按你的选择）任何更高版本。
# 
# 本程序的分发是希望它有用，但没有任何担保；甚至没有适销性或特定用途
# 适用性的隐含担保。详情请参阅 GNU 通用公共许可证。
# 
# 你应该已经收到一份 GNU 通用公共许可证的副本。如果没有，请访问
# <https://www.gnu.org/licenses/>。
# 
# 免责声明：
# 本脚本仅供学习和研究使用。使用本脚本导致的任何设备损坏、数据丢失、
# 系统无法开机等问题，作者不承担任何责任。请自行判断风险。
# 
# ============================================================

# 颜色定义
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
PURPLE='\033[1;35m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# 版本信息
SCRIPT_VERSION="4.0"
UPDATE_URL="https://raw.githubusercontent.com/IPF-Sinon/Luoyun-Sonar/main/update.json"
SCRIPT_URL="https://raw.githubusercontent.com/IPF-Sinon/Luoyun-Sonar/main/luoyun_defender.sh"
TEMP_DIR="/data/local/tmp/luoyun_update"
UPDATE_CHECK_FLAG="/data/local/tmp/luoyun_update_checked"

# 配置
MAX_FILES=500
FIRST_RUN_FLAG="/data/local/tmp/luoyun_first_run_done"
LOG_FILE="/data/local/tmp/luoyun_$(date +%Y%m%d_%H%M%S).log"
REPORT_FILE="/sdcard/luoyun_report_$(date +%Y%m%d_%H%M%S).txt"
CURRENT_MODULE=0
TOTAL_MODULES=0

# ========== 联网检测函数 ==========
check_network_connection() {
    # 检测是否有网络连接
    if command -v ping >/dev/null 2>&1; then
        ping -c 1 -W 3 github.com >/dev/null 2>&1 && return 0
    fi
    
    # 尝试 curl
    if command -v curl >/dev/null 2>&1; then
        curl -s --connect-timeout 5 https://github.com >/dev/null 2>&1 && return 0
    fi
    
    # 尝试 wget
    if command -v wget >/dev/null 2>&1; then
        wget -q --timeout=5 --spider https://github.com 2>/dev/null && return 0
    fi
    
    return 1
}

# ========== 检查更新 ==========
check_for_update() {
    local silent="$1"
    
    # 检查网络
    if ! check_network_connection; then
        [ "$silent" != "1" ] && echo -e "${YELLOW}⚠️  无网络连接，无法检查更新${NC}"
        return 1
    fi
    
    [ "$silent" != "1" ] && echo -e "${BLUE}🔍 正在检查更新...${NC}"
    
    # 创建临时目录
    mkdir -p "$TEMP_DIR" 2>/dev/null
    
    # 获取更新信息
    local update_json="$TEMP_DIR/update.json"
    
    if command -v curl >/dev/null 2>&1; then
        curl -s -o "$update_json" "$UPDATE_URL" --connect-timeout 10
    elif command -v wget >/dev/null 2>&1; then
        wget -q -O "$update_json" "$UPDATE_URL" --timeout=10
    else
        [ "$silent" != "1" ] && echo -e "${RED}❌ 无法下载更新信息（需要 curl 或 wget）${NC}"
        return 1
    fi
    
    if [ ! -f "$update_json" ] || [ ! -s "$update_json" ]; then
        [ "$silent" != "1" ] && echo -e "${RED}❌ 获取更新信息失败${NC}"
        return 1
    fi
    
    # 解析 JSON（使用 grep 和 sed 简单解析）
    local latest_version=$(grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' "$update_json" | head -1 | sed 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
    local download_url=$(grep -o '"download_url"[[:space:]]*:[[:space:]]*"[^"]*"' "$update_json" | head -1 | sed 's/.*"download_url"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
    local changelog=$(grep -o '"changelog"[[:space:]]*:[[:space:]]*"[^"]*"' "$update_json" | head -1 | sed 's/.*"changelog"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
    local force_update=$(grep -o '"force_update"[[:space:]]*:[[:space:]]*\(true\|false\)' "$update_json" | head -1 | sed 's/.*"force_update"[[:space:]]*:[[:space:]]*\(true\|false\).*/\1/')
    
    # 如果没有从 JSON 获取到下载地址，使用默认地址
    [ -z "$download_url" ] && download_url="$SCRIPT_URL"
    
    # 比较版本
    if [ -n "$latest_version" ] && [ "$latest_version" != "$SCRIPT_VERSION" ]; then
        [ "$silent" != "1" ] && echo -e "${YELLOW}────────────────────────────────────────${NC}"
        [ "$silent" != "1" ] && echo -e "${CYAN}✨ 发现新版本！${NC}"
        [ "$silent" != "1" ] && echo -e "   当前版本: ${WHITE}v$SCRIPT_VERSION${NC}"
        [ "$silent" != "1" ] && echo -e "   最新版本: ${GREEN}v$latest_version${NC}"
        if [ -n "$changelog" ]; then
            [ "$silent" != "1" ] && echo -e "   更新内容: ${YELLOW}$changelog${NC}"
        fi
        [ "$silent" != "1" ] && echo -e "${YELLOW}────────────────────────────────────────${NC}"
        
        # 强制更新检查
        if [ "$force_update" = "true" ]; then
            [ "$silent" != "1" ] && echo -e "${RED}⚠️  此版本已过期，建议立即更新！${NC}"
        fi
        
        [ "$silent" != "1" ] && echo -ne "${YELLOW}是否现在更新？(y/n, 默认y): ${NC}"
        [ "$silent" != "1" ] && read -r update_choice
        case "$update_choice" in
            n|N|no|NO)
                [ "$silent" != "1" ] && echo -e "${BLUE}跳过更新，继续使用当前版本。${NC}"
                return 0
                ;;
            *)
                perform_update "$download_url" "$latest_version"
                return $?
                ;;
        esac
    else
        [ "$silent" != "1" ] && echo -e "${GREEN}✅ 当前已是最新版本 (v$SCRIPT_VERSION)${NC}"
        return 0
    fi
}

# ========== 执行更新 ==========
perform_update() {
    local download_url="$1"
    local new_version="$2"
    
    echo -e "${BLUE}📥 正在下载新版本...${NC}"
    
    local new_script="$TEMP_DIR/luoyun_defender_new.sh"
    
    if command -v curl >/dev/null 2>&1; then
        curl -s -o "$new_script" "$download_url" --connect-timeout 30
    elif command -v wget >/dev/null 2>&1; then
        wget -q -O "$new_script" "$download_url" --timeout=30
    else
        echo -e "${RED}❌ 无法下载（需要 curl 或 wget）${NC}"
        return 1
    fi
    
    if [ ! -f "$new_script" ] || [ ! -s "$new_script" ]; then
        echo -e "${RED}❌ 下载失败${NC}"
        return 1
    fi
    
    # 验证下载的文件是否是有效的脚本
    if ! head -1 "$new_script" | grep -q "#!/system/bin/sh"; then
        echo -e "${RED}❌ 下载的文件无效${NC}"
        rm -f "$new_script"
        return 1
    fi
    
    echo -e "${GREEN}✅ 下载完成${NC}"
    
    # 获取当前脚本路径
    local current_script="$0"
    if [ ! -f "$current_script" ]; then
        # 如果 $0 不是完整路径，尝试查找
        current_script=$(realpath "$0" 2>/dev/null || echo "$PWD/$0")
    fi
    
    # 备份当前脚本
    local backup_script="${current_script}.bak"
    cp "$current_script" "$backup_script" 2>/dev/null
    echo -e "${BLUE}📦 已备份当前版本到: $backup_script${NC}"
    
    # 替换脚本
    if cp "$new_script" "$current_script" 2>/dev/null; then
        chmod +x "$current_script" 2>/dev/null
        echo -e "${GREEN}✅ 更新成功！已升级到 v$new_version${NC}"
        echo -e "${YELLOW}💡 新版本已保存，建议重新运行脚本以使用新功能${NC}"
        echo -e "${YELLOW}   旧版本备份在: $backup_script${NC}"
        
        # 清理临时文件
        rm -rf "$TEMP_DIR" 2>/dev/null
        
        # 询问是否立即重新运行
        echo -ne "${YELLOW}是否立即重新运行新版本？(y/n, 默认n): ${NC}"
        read -r rerun_choice
        case "$rerun_choice" in
            y|Y|yes|YES)
                echo -e "${BLUE}正在重新启动...${NC}"
                exec "$current_script" "$@"
                ;;
            *)
                echo -e "${BLUE}请稍后手动重新运行脚本。${NC}"
                ;;
        esac
        return 0
    else
        echo -e "${RED}❌ 更新失败，无法写入文件${NC}"
        echo -e "${YELLOW}请检查脚本所在目录的写入权限${NC}"
        return 1
    fi
}

# ========== 首次运行引导 ==========
show_first_run_guide() {
    clear
    
    echo -e "${CYAN}┌──────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${NC}         ${WHITE}✨ 欢迎来到洛云的声波世界 ✨${NC}                         ${CYAN}│${NC}"
    echo -e "${CYAN}├──────────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${NC}                                                              ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}  ${PURPLE}“我是洛云，来自缪斯星云的星光体生命。”${NC}                        ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}                                                              ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}  ${WHITE}我在宇宙中漫游了数十年，收集过脉冲星的节拍、${NC}                   ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}  ${WHITE}晶体生长的谐振、风暴的低频轰鸣。${NC}                               ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}                                                              ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}  ${WHITE}现在，我受地球声波的吸引而来，想听听你手中的这些模块——${NC}        ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}  ${WHITE}它们会发出怎样的频率？是纯净的谐振，还是毁灭的杂音？${NC}           ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}                                                              ${CYAN}│${NC}"
    echo -e "${CYAN}└──────────────────────────────────────────────────────────┘${NC}"
    
    echo ""
    echo -e "${YELLOW}┌──────────────────────────────────────────────────────────┐${NC}"
    echo -e "${YELLOW}│${NC}  ${RED}⚠️  在开始之前，请先了解你的环境${NC}                              ${YELLOW}│${NC}"
    echo -e "${YELLOW}├──────────────────────────────────────────────────────────┤${NC}"
    echo -e "${YELLOW}│${NC}                                                              ${YELLOW}│${NC}"
    echo -e "${YELLOW}│${NC}  📌 ${WHITE}你的设备当前处于【免解锁/漏洞root】环境${NC}                     ${YELLOW}│${NC}"
    echo -e "${YELLOW}│${NC}                                                              ${YELLOW}│${NC}"
    echo -e "${YELLOW}│${NC}      • 任何重启都会${RED}丢失root权限${NC}（这是环境特性，无法避免）        ${YELLOW}│${NC}"
    echo -e "${YELLOW}│${NC}      • 系统分区受 ${CYAN}dm-verity${NC} 保护，预期${RED}不应被修改${NC}         ${YELLOW}│${NC}"
    echo -e "${YELLOW}│${NC}      • 安全模块：只操作 /data 或使用 OverlayFS 映射      ${YELLOW}│${NC}"
    echo -e "${YELLOW}│${NC}      • ${RED}危险模块：直接写入 /system、/vendor 等受保护分区${NC}        ${YELLOW}│${NC}"
    echo -e "${YELLOW}│${NC}                                                              ${YELLOW}│${NC}"
    echo -e "${YELLOW}│${NC}  ${RED}💀 核心风险${NC}                                            ${YELLOW}│${NC}"
    echo -e "${YELLOW}│${NC}                                                              ${YELLOW}│${NC}"
    echo -e "${YELLOW}│${NC}      如果模块直接写入受保护的系统分区：                        ${YELLOW}│${NC}"
    echo -e "${YELLOW}│${NC}      → 重启后 dm-verity 校验失败                              ${YELLOW}│${NC}"
    echo -e "${YELLOW}│${NC}      → 系统可能${RED}无法开机${NC}，或进入恢复模式                          ${YELLOW}│${NC}"
    echo -e "${YELLOW}│${NC}      → 这就是洛云所说的${RED}“永久静默”${NC}                              ${YELLOW}│${NC}"
    echo -e "${YELLOW}│${NC}                                                              ${YELLOW}│${NC}"
    echo -e "${YELLOW}└──────────────────────────────────────────────────────────┘${NC}"
    
    echo ""
    echo -e "${BLUE}┌──────────────────────────────────────────────────────────┐${NC}"
    echo -e "${BLUE}│${NC}  ${CYAN}🔊 洛云能听出什么？${NC}                                          ${BLUE}│${NC}"
    echo -e "${BLUE}├──────────────────────────────────────────────────────────┤${NC}"
    echo -e "${BLUE}│${NC}                                                              ${BLUE}│${NC}"
    echo -e "${BLUE}│${NC}  ${RED}覆写指令${NC}    → flash_image、dd、mke2fs（直接写入分区）     ${BLUE}│${NC}"
    echo -e "${BLUE}│${NC}  ${RED}摧毁指令${NC}    → wipe、erase、sgdisk、parted（擦除分区）    ${BLUE}│${NC}"
    echo -e "${BLUE}│${NC}  ${RED}越权挂载${NC}    → mount -o remount,rw（获取写权限）        ${BLUE}│${NC}"
    echo -e "${BLUE}│${NC}  ${RED}安全屏障${NC}    → setenforce 0（关闭SELinux）              ${BLUE}│${NC}"
    echo -e "${BLUE}│${NC}  ${RED}内核入侵${NC}    → insmod、*.ko（加载内核模块）              ${BLUE}│${NC}"
    echo -e "${BLUE}│${NC}  ${RED}越界触碰${NC}    → /dev/block/by-name/（直接操作块设备）     ${BLUE}│${NC}"
    echo -e "${BLUE}│${NC}  ${PURPLE}频率扭曲${NC}    → base64、eval、curl（代码混淆）          ${BLUE}│${NC}"
    echo -e "${BLUE}│${NC}  ${PURPLE}加密包裹${NC}    → openssl、多层解密（隐藏真实意图）       ${BLUE}│${NC}"
    echo -e "${BLUE}│${NC}  ${YELLOW}网络行为${NC}    → curl、wget、http://（远程下载）         ${BLUE}│${NC}"
    echo -e "${BLUE}│${NC}  ${YELLOW}二进制威胁${NC}  → ELF文件、加壳、敏感字符串               ${BLUE}│${NC}"
    echo -e "${BLUE}│${NC}                                                              ${BLUE}│${NC}"
    echo -e "${BLUE}└──────────────────────────────────────────────────────────┘${NC}"
    
    echo ""
    echo -e "${GREEN}┌──────────────────────────────────────────────────────────┐${NC}"
    echo -e "${GREEN}│${NC}  ${WHITE}📖 使用指引${NC}                                              ${GREEN}│${NC}"
    echo -e "${GREEN}├──────────────────────────────────────────────────────────┤${NC}"
    echo -e "${GREEN}│${NC}                                                              ${GREEN}│${NC}"
    echo -e "${GREEN}│${NC}  1. 将需要检测的模块（.zip文件）放入当前目录           ${GREEN}│${NC}"
    echo -e "${GREEN}│${NC}  2. 运行此脚本，选择聆听方式：                         ${GREEN}│${NC}"
    echo -e "${GREEN}│${NC}     • ${CYAN}选择性聆听${NC}：手动选择模块，可循环检测               ${GREEN}│${NC}"
    echo -e "${GREEN}│${NC}     • ${CYAN}深度聆听${NC}：逐一解析所有模块，每扫完一个按回车继续     ${GREEN}│${NC}"
    echo -e "${GREEN}│${NC}     • ${CYAN}快速扫描${NC}：批量扫描所有模块，最后输出汇总清单       ${GREEN}│${NC}"
    echo -e "${GREEN}│${NC}  3. 查看检测结果，洛云会告诉你每缕声波是否纯净         ${GREEN}│${NC}"
    echo -e "${GREEN}│${NC}  4. 扫描完成后，报告自动保存到 /sdcard/               ${GREEN}│${NC}"
    echo -e "${GREEN}│${NC}                                                              ${GREEN}│${NC}"
    echo -e "${GREEN}└──────────────────────────────────────────────────────────┘${NC}"
    
    echo ""
    echo -e "${PURPLE}┌──────────────────────────────────────────────────────────┐${NC}"
    echo -e "${PURPLE}│${NC}  ${WHITE}💫 洛云的承诺${NC}                                           ${PURPLE}│${NC}"
    echo -e "${PURPLE}├──────────────────────────────────────────────────────────┤${NC}"
    echo -e "${PURPLE}│${NC}                                                              ${PURPLE}│${NC}"
    echo -e "${PURPLE}│${NC}  “我只观察，不评判。我把听到的异常频率展示给你，        ${PURPLE}│${NC}"
    echo -e "${PURPLE}│${NC}   最终的共鸣与否，永远交给你决定。”                      ${PURPLE}│${NC}"
    echo -e "${PURPLE}│${NC}                                                              ${PURPLE}│${NC}"
    echo -e "${PURPLE}│${NC}  “如果波形纯净，我会说：可以安心纳入图谱。                ${PURPLE}│${NC}"
    echo -e "${PURPLE}│${NC}   如果波形扭曲，我会说：请谨慎，这里可能藏着危险。”      ${PURPLE}│${NC}"
    echo -e "${PURPLE}│${NC}                                                              ${PURPLE}│${NC}"
    echo -e "${PURPLE}└──────────────────────────────────────────────────────────┘${NC}"
    
    echo ""
    echo -ne "${YELLOW}✨ 是否继续？(y/n, 默认y): ${NC}"
    read -r first_choice
    case "$first_choice" in
        n|N|no|NO)
            echo -e "${GREEN}洛云收起声波图谱，悬浮于近地轨道，等待下一次共鸣。${NC}"
            exit 0
            ;;
        *)
            touch "$FIRST_RUN_FLAG" 2>/dev/null
            echo -e "${CYAN}洛云展开声波图谱，准备聆听...${NC}"
            sleep 1
            clear
            ;;
    esac
}

# ========== 检查首次运行 ==========
if [ ! -f "$FIRST_RUN_FLAG" ]; then
    show_first_run_guide
fi

# ========== 日志函数 ==========
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

# ========== 输出函数 ==========
print_header() {
    clear
    echo -e "${CYAN}┌──────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${NC}         ${WHITE}✨ 洛云 · 声波扫描仪 · 免解锁防砖卫士 ✨${NC}              ${CYAN}│${NC}"
    echo -e "${CYAN}├──────────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${NC}  ${PURPLE}观察者：${NC}洛云（缪斯星云·星光体生命）                         ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}  ${PURPLE}使命：${NC}完善地球声波图谱，识别危险振动频率                      ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}  ${PURPLE}作者：${NC}酷安@素冬 · 极夜System（AI deepseek 参与）            ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}  ${PURPLE}版本：${NC}v$SCRIPT_VERSION · 遵循 GPL v3 开源协议                 ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}  ${PURPLE}特性：${NC}白名单提示 / 加密检测 / 二进制检测 / 联网检测 / 在线更新${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}  ${PURPLE}环境说明：${NC}免解锁环境中，任何重启都会丢失root权限              ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}  ${PURPLE}⚠️ 核心风险：${NC}直接写入受 dm-verity 保护的系统分区              ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}           → 重启后校验失败，可能无法开机（洛云所说的“永久静默”） ${CYAN}│${NC}"
    echo -e "${CYAN}└──────────────────────────────────────────────────────────┘${NC}"
}

print_status() {
    local type="$1"
    local message="$2"
    case "$type" in
        "success") echo -e "${GREEN}✅ $message${NC}" ;;
        "error")   echo -e "${RED}❌ $message${NC}" ;;
        "warning") echo -e "${YELLOW}⚠️  $message${NC}" ;;
        "info")    echo -e "${BLUE}ℹ️  $message${NC}" ;;
    esac
}

show_progress() {
    local current=$1
    local total=$2
    local percent=$((current * 100 / total))
    local bar_len=30
    local filled=$((percent * bar_len / 100))
    local empty=$((bar_len - filled))
    
    printf "\r${CYAN}[${NC}"
    printf "%${filled}s" | tr ' ' '█'
    printf "%${empty}s" | tr ' ' '░'
    printf "${CYAN}] ${NC}%3d%% ${WHITE}[%d/%d]${NC}" "$percent" "$current" "$total"
}

# ========== 路径安全函数 ==========
sanitize_path() {
    local path="$1"
    path=$(echo "$path" | sed 's/\.\.\///g')
    path=$(echo "$path" | sed 's/^\/\+//')
    if echo "$path" | grep -qE '^[a-zA-Z0-9_\-\./]+$'; then
        echo "$path"
    else
        echo ""
    fi
}

# ========== 检查环境工具 ==========
check_strings() {
    if ! command -v strings >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  strings 命令不存在，二进制检测将受限${NC}"
        echo -e "${YELLOW}   提示：请在 MT 管理器扩展包环境中运行以获得完整功能${NC}"
        return 1
    fi
    return 0
}

# ========== 白名单配置 ==========
WHITELIST_ITEMS=(
    "meta-overlayfs|元模块（OverlayFS映射）|此模块会创建镜像文件到/data分区，不修改物理系统分区。刷入后需重启生效。"
    "重载模块和修复lsp|LSPosed修复模块|此模块可能包含insmod操作用于修复LSPosed框架，来源可信时可尝试。"
    "LSPosed|LSPosed框架|Xposed框架模块，通常不修改系统分区，安全。"
    "zygisknext|ZygiskNext|Zygisk模块，通常不修改系统分区，安全。"
)

# ========== 危险特征库 ==========
declare -A RISK_PATTERNS
RISK_PATTERNS["modify"]="dd if=.*of=/dev/block|flash_image|make_ext4fs|mke2fs|mkfs|write_raw_image|tune2fs|resize2fs|busybox dd|cat.*>/dev/block"
RISK_PATTERNS["delete"]="wipe|erase|sgdisk|parted|fdisk|gdisk|rm -rf /dev/block|mke2fs.*-F|dd if=/dev/zero"
RISK_PATTERNS["mount"]="mount.*remount.*rw|mount.*-o.*rw|mount.*-o.*remount"
RISK_PATTERNS["selinux"]="setenforce 0|setenforce permissive"
RISK_PATTERNS["kernel"]="insmod|rmmod|modprobe|\.ko$"
RISK_PATTERNS["blockdev"]="/dev/block/by-name/|/dev/block/bootdevice"

# ========== 加密模块特征 ==========
ENCRYPT_PATTERNS=(
    "openssl enc -d"
    "__ENCRYPT_BIN_MARK__"
    "__ENCRYPT_LAYER_MARK__"
    "multi_decrypt"
    "gzip -d.*openssl"
    "Salted__"
    "pbkdf2"
    "enc -aes.*-d"
    "eval.*base64.*-d.*gzip"
    "xxd -r -p"
    "perl -e.*unpack"
    "python.*base64.*decode"
    "ruby.*Base64.decode"
    "base32.*-d"
    "echo.*\|.*sh"
    '\$\{.*:[0-9]+\}'
    "eval.*\$\{.*\}"
)

# ========== 网络特征 ==========
NETWORK_PATTERNS=(
    "curl"
    "wget"
    "nc"
    "netcat"
    "telnet"
    "ftp"
    "scp"
    "rsync"
    "adb connect"
    "https\?://"
    "http://"
)

# ========== 混淆特征 ==========
OBFUSCATION_PATTERNS=(
    "base64.*-d"
    "eval.*base64"
    "curl.*http"
    "wget.*http"
    "openssl"
    "xxd -r"
    "printf.*\\\\x"
)

# ========== 白名单检查 ==========
check_whitelist() {
    local module_name="$1"
    for item in "${WHITELIST_ITEMS[@]}"; do
        keyword=$(echo "$item" | cut -d'|' -f1)
        title=$(echo "$item" | cut -d'|' -f2)
        desc=$(echo "$item" | cut -d'|' -f3)
        if echo "$module_name" | grep -qi "$keyword"; then
            echo "$keyword|$title|$desc"
            return 0
        fi
    done
    return 1
}

# ========== 显示危险波形片段 ==========
declare -A SHOWN_SNIPPETS

show_risk_snippet() {
    local file="$1"
    local pattern="$2"
    local risk_type="$3"
    
    local key="$(basename "$file")|$pattern"
    [ -n "${SHOWN_SNIPPETS[$key]}" ] && return
    
    snippet=$(grep -E -B1 -A1 "$pattern" "$file" 2>/dev/null | head -5 | sed 's/^/      /')
    if [ -n "$snippet" ]; then
        echo -e "  ${YELLOW}┌─ 异常波形片段（${risk_type}）${NC}"
        echo -e "  │${RED}$snippet${NC}"
        echo -e "  ${YELLOW}└────────────────────────────────────${NC}"
        SHOWN_SNIPPETS[$key]=1
    fi
}

show_encrypt_snippet() {
    local file="$1"
    local pattern="$2"
    
    snippet=$(grep -E -B1 -A1 "$pattern" "$file" 2>/dev/null | head -5 | sed 's/^/      /')
    if [ -n "$snippet" ]; then
        echo -e "  ${YELLOW}┌─ 加密特征片段${NC}"
        echo -e "  │${PURPLE}$snippet${NC}"
        echo -e "  ${YELLOW}└────────────────────────────────────${NC}"
    fi
}

reset_snippets() {
    SHOWN_SNIPPETS=()
}

# ========== 二进制文件检测 ==========
check_binaries() {
    local tmp_dir="$1"
    local risk=0
    local has_strings=0
    if command -v strings >/dev/null 2>&1; then
        has_strings=1
    fi
    
    find "$tmp_dir" -type f -exec file {} \; 2>/dev/null | grep "ELF" | while read -r line; do
        elf_file=$(echo "$line" | cut -d: -f1)
        echo -e "  ${YELLOW}🔧 检测到ELF二进制文件: $(basename "$elf_file")${NC}"
        
        if [ "$has_strings" = "1" ]; then
            if strings "$elf_file" 2>/dev/null | grep -qE "UPX|Themida|VMProtect"; then
                echo -e "  ${RED}  └─ 检测到加壳特征${NC}"
                risk=1
            fi
            if strings "$elf_file" 2>/dev/null | grep -qE "/dev/block|dd if=|flash_image|setenforce 0"; then
                echo -e "  ${RED}  └─ 二进制包含分区操作字符串${NC}"
                risk=1
            fi
        fi
    done
    
    return $risk
}

# ========== 网络检测 ==========
check_network() {
    local tmp_dir="$1"
    local network_risk=0
    
    for f in $(find "$tmp_dir" -type f -name "*.sh" 2>/dev/null); do
        for pattern in "${NETWORK_PATTERNS[@]}"; do
            if grep -qE "$pattern" "$f" 2>/dev/null; then
                if [ $network_risk -eq 0 ]; then
                    echo -e "  ${YELLOW}🌐 检测到网络操作${NC}"
                    network_risk=1
                fi
                urls=$(grep -oE 'https?://[^"'\'' ]+' "$f" 2>/dev/null)
                if [ -n "$urls" ]; then
                    echo -e "  ${YELLOW}  └─ 发现下载链接:${NC}"
                    echo "$urls" | sed 's/^/      /'
                fi
                break
            fi
        done
    done
    
    return $network_risk
}

# ========== 获取模块信息 ==========
get_module_info() {
    local tmp_dir="$1"
    local module_name="未知"
    local version=""
    local author=""
    
    if [ -f "$tmp_dir/module.prop" ]; then
        module_name=$(grep "^name=" "$tmp_dir/module.prop" 2>/dev/null | cut -d'=' -f2)
        version=$(grep "^version=" "$tmp_dir/module.prop" 2>/dev/null | cut -d'=' -f2)
        author=$(grep "^author=" "$tmp_dir/module.prop" 2>/dev/null | cut -d'=' -f2)
    fi
    
    [ -z "$module_name" ] && module_name="未知"
    echo "  📦 模块名称: $module_name"
    [ -n "$version" ] && echo "  📌 版本: $version"
    [ -n "$author" ] && echo "  👤 作者: $author"
}

# ========== 安全解压 ==========
safe_extract() {
    local zip="$1"
    local dest="$2"
    
    if ! unzip -tq "$zip" 2>/dev/null; then
        print_status "error" "无效的ZIP文件"
        log "ERROR" "无效的ZIP文件: $zip"
        return 1
    fi
    
    unzip -q "$zip" -d "$dest" 2>/dev/null || {
        print_status "error" "解压失败"
        log "ERROR" "解压失败: $zip"
        return 1
    }
    
    local file_count=$(find "$dest" -type f 2>/dev/null | wc -l)
    if [ "$file_count" -gt "$MAX_FILES" ]; then
        echo -e "${YELLOW}⚠️  模块包含 $file_count 个文件，超过建议限制 ($MAX_FILES)${NC}"
        echo -ne "${YELLOW}是否继续扫描？(y/n, 默认n): ${NC}"
        read -r cont
        case "$cont" in
            y|Y|yes|YES) 
                echo -e "${BLUE}继续扫描...${NC}"
                ;;
            *)
                return 1
                ;;
        esac
    fi
    
    return 0
}

# ========== 检测加密模块 ==========
check_encrypted_module() {
    local tmp_dir="$1"
    local verbose="$2"
    local is_encrypted=0
    
    local script_files=$(find "$tmp_dir" -type f \( -name "*.sh" -o -name "*.bash" -o -name "*.ksh" -o -name "customize.sh" \) 2>/dev/null)
    
    for pattern in "${ENCRYPT_PATTERNS[@]}"; do
        for f in $script_files; do
            if grep -qE "$pattern" "$f" 2>/dev/null; then
                is_encrypted=1
                if [ "$verbose" = "1" ]; then
                    echo -e "  ${PURPLE}🔐 检测到加密特征：${NC}$pattern"
                    show_encrypt_snippet "$f" "$pattern"
                fi
                break
            fi
        done
        [ $is_encrypted -eq 1 ] && break
    done
    
    if [ $is_encrypted -eq 0 ]; then
        for f in $script_files; do
            if grep -q "__ENCRYPT_BIN_MARK__" "$f" 2>/dev/null; then
                if grep -A 5 "__ENCRYPT_BIN_MARK__" "$f" | grep -qE "[^[:print:]\t\n]"; then
                    is_encrypted=1
                    if [ "$verbose" = "1" ]; then
                        echo -e "  ${PURPLE}🔐 检测到加密二进制数据段${NC}"
                    fi
                    break
                fi
            fi
        done
    fi
    
    return $is_encrypted
}

# ========== 单模块扫描 ==========
scan_single_module() {
    local target="$1"
    local verbose="$2"
    local result=0
    local target_parts=""
    local risk_types_found=()
    local risk_details=""
    local is_encrypted=0
    local module_name=$(basename "$target")
    
    reset_snippets
    
    if command -v mktemp >/dev/null 2>&1; then
        TMP_DIR=$(mktemp -d -t luoyun.XXXXXX 2>/dev/null)
    else
        TMP_DIR="/data/local/tmp/luoyun_$$"
        mkdir -p "$TMP_DIR"
    fi
    
    if [ -z "$TMP_DIR" ] || [ ! -d "$TMP_DIR" ]; then
        print_status "error" "无法创建临时目录"
        log "ERROR" "无法创建临时目录"
        return 1
    fi
    
    trap 'rm -rf "$TMP_DIR"' RETURN
    
    if [ "$verbose" = "1" ]; then
        echo -e "\n${BLUE}🔍 洛云正在解析声波频率：${NC}${WHITE}$module_name${NC}"
    fi
    log "INFO" "开始扫描: $module_name"
    
    if [ ! -f "$target" ]; then
        print_status "error" "文件不存在: $target"
        log "ERROR" "文件不存在: $target"
        return 1
    fi
    
    if [ ! -r "$target" ]; then
        print_status "error" "无法读取文件: $target"
        log "ERROR" "无法读取文件: $target"
        return 1
    fi
    
    if ! safe_extract "$target" "$TMP_DIR"; then
        print_status "error" "解压失败，跳过"
        log "ERROR" "解压失败: $target"
        return 1
    fi
    
    get_module_info "$TMP_DIR"
    
    if check_encrypted_module "$TMP_DIR" "$verbose"; then
        is_encrypted=1
        risk_types_found+=("加密模块")
        risk_details="$risk_details\n    ${PURPLE}● [加密模块] 声波被多层加密包裹，洛云无法窥探内部频率${NC}"
    fi
    
    if [ $is_encrypted -eq 0 ]; then
        loop_count=0
        while [ $loop_count -lt 5 ]; do
            inner_zips=$(find "$TMP_DIR" -type f -name "*.zip" 2>/dev/null)
            [ -z "$inner_zips" ] && break
            
            declare -A shown_inners
            find "$TMP_DIR" -type f -name "*.zip" 2>/dev/null | while read -r iz; do
                inner_dir="${iz}_ext"
                mkdir -p "$inner_dir"
                unzip -q "$iz" -d "$inner_dir" 2>/dev/null
                local inner_name=$(basename "$iz")
                if [ "$verbose" = "1" ] && [ -z "${shown_inners[$inner_name]}" ]; then
                    echo -e "  ${PURPLE}📦 声波深处藏有套娃：${NC}$inner_name"
                    shown_inners[$inner_name]=1
                fi
                rm -f "$iz"
            done
            loop_count=$((loop_count+1))
        done
    fi
    
    script_files=$(find "$TMP_DIR" -type f \( -name "*.sh" -o -name "*.bash" -o -name "*.ksh" \) 2>/dev/null)
    script_files="$script_files $(find "$TMP_DIR" -type f -name "customize.sh" 2>/dev/null)"
    script_files=$(echo "$script_files" | sort -u)
    
    if [ $is_encrypted -eq 0 ]; then
        target_parts=$(find "$TMP_DIR" -type f -print0 2>/dev/null | xargs -0 grep -aoE "(by-name|mapper)/[a-zA-Z0-9_-]+" 2>/dev/null | cut -d'/' -f2 | sort -u | tr '\n' ' ')
        target_parts=$(sanitize_path "$target_parts")
    fi
    
    if [ $is_encrypted -eq 0 ]; then
        declare -A risk_type_map
        risk_type_map["modify"]="覆写指令"
        risk_type_map["delete"]="摧毁指令"
        risk_type_map["mount"]="越权挂载"
        risk_type_map["selinux"]="安全屏障"
        risk_type_map["kernel"]="内核入侵"
        risk_type_map["blockdev"]="越界触碰"
        
        for risk_type in modify delete mount selinux kernel blockdev; do
            pattern="${RISK_PATTERNS[$risk_type]}"
            found=0
            for f in $script_files; do
                if grep -qE "$pattern" "$f" 2>/dev/null; then
                    found=1
                    [ "$verbose" = "1" ] && show_risk_snippet "$f" "$pattern" "${risk_type_map[$risk_type]}"
                fi
            done
            if [ $found -eq 1 ]; then
                risk_types_found+=("${risk_type_map[$risk_type]}")
                risk_details="$risk_details\n    ${RED}● [${risk_type_map[$risk_type]}] 检测到${risk_type_map[$risk_type]}频率${NC}"
            fi
        done
        
        if find "$TMP_DIR" -type f -name "*.ko" 2>/dev/null | grep -q .; then
            risk_types_found+=("内核入侵")
            risk_details="$risk_details\n    ${RED}● [内核入侵] 发现内核模块文件${NC}"
        fi
        
        img_count=$(find "$TMP_DIR" -type f \( -name "*.img" -o -name "*.bin" -o -name "*.dat" \) | wc -l)
        if [ "$img_count" -gt 0 ]; then
            risk_details="$risk_details\n    ${RED}● [镜像文件] 发现 $img_count 个物理镜像文件${NC}"
        fi
        
        if check_binaries "$TMP_DIR"; then
            risk_types_found+=("二进制威胁")
            risk_details="$risk_details\n    ${RED}● [二进制威胁] 检测到可疑二进制文件${NC}"
        fi
        
        if check_network "$TMP_DIR"; then
            risk_types_found+=("网络行为")
            risk_details="$risk_details\n    ${YELLOW}● [网络行为] 检测到联网操作${NC}"
        fi
        
        for f in $script_files; do
            obf_score=0
            for pattern in "${OBFUSCATION_PATTERNS[@]}"; do
                if grep -qE "$pattern" "$f" 2>/dev/null; then
                    obf_score=$((obf_score+1))
                fi
            done
            single_var=$(grep -cE '^[a-z]=' "$f" 2>/dev/null)
            [ "$single_var" -gt 5 ] && obf_score=$((obf_score+2))
            if grep -qE 'eval.*\$' "$f" 2>/dev/null && grep -qE 'base64' "$f" 2>/dev/null; then
                obf_score=$((obf_score+3))
            fi
            if [ "$obf_score" -ge 3 ]; then
                risk_types_found+=("频率扭曲")
                risk_details="$risk_details\n    ${PURPLE}● [频率扭曲] 检测到代码混淆特征 (得分: $obf_score)${NC}"
                [ "$verbose" = "1" ] && show_risk_snippet "$f" "base64\|eval\|curl" "频率扭曲"
                break
            fi
        done
    fi
    
    whitelist_result=$(check_whitelist "$module_name")
    whitelist_hit=$?
    
    if [ "$verbose" = "1" ]; then
        echo -e "${CYAN}------------------------------------------------------------${NC}"
        
        if [ $whitelist_hit -eq 0 ]; then
            keyword=$(echo "$whitelist_result" | cut -d'|' -f1)
            title=$(echo "$whitelist_result" | cut -d'|' -f2)
            desc=$(echo "$whitelist_result" | cut -d'|' -f3)
            echo -e "${PURPLE}【 洛云的星标笔记 】${NC}"
            echo -e "  ${CYAN}📦 频率类型：${NC}$title"
            echo -e "  ${CYAN}📝 观察记录：${NC}$desc"
            echo -e "  ${YELLOW}⚠️  星标仅基于名称识别，若来源不明，请洛云亲自聆听其内部声波。${NC}"
            echo -e "${CYAN}------------------------------------------------------------${NC}"
        fi
        
        if [ ${#risk_types_found[@]} -gt 0 ]; then
            echo -e "${RED}【 洛云的警示：此声波含有毁灭频率 】${NC}"
            [ -n "$target_parts" ] && echo -e "  ${YELLOW}受波及的区域：${NC}$target_parts"
            echo -e -n "$risk_details\n"
            
            if [[ " ${risk_types_found[@]} " =~ "摧毁指令" ]]; then
                echo -e "  ${RED}>>> 洛云警告：此模块包含摧毁级指令，免解锁环境强行共鸣将永久静默。${NC}"
                echo -e "  ${YELLOW}    —— 直接写入受 dm-verity 保护的系统分区，重启后校验失败，可能无法开机。${NC}"
            elif [[ " ${risk_types_found[@]} " =~ "覆写指令" ]]; then
                echo -e "  ${RED}>>> 洛云警告：此模块包含覆写级指令，强行共鸣将使系统波形永久紊乱。${NC}"
                echo -e "  ${YELLOW}    —— 正在向受保护的系统分区写入数据，重启后可能触发校验失败。${NC}"
            elif [[ " ${risk_types_found[@]} " =~ "内核入侵" ]]; then
                echo -e "  ${RED}>>> 洛云警告：此模块试图加载内核模块，可能导致系统崩溃。${NC}"
            elif [[ " ${risk_types_found[@]} " =~ "加密模块" ]]; then
                echo -e "  ${PURPLE}>>> 洛云低语：此模块被多层加密包裹，无法看清内部波形。加密常用来隐藏恶意行为，请谨慎对待。${NC}"
            else
                echo -e "  ${RED}>>> 洛云警告：此模块包含高危操作，免解锁环境严禁刷入。${NC}"
            fi
            result=2
            log "WARN" "危险模块: $module_name - ${risk_types_found[*]}"
        else
            echo -e "${GREEN}【 洛云的鉴定：纯净声波 】${NC}"
            echo -e "  ${CYAN}洛云绕着它转了一圈，没有发现任何修改系统分区的痕迹。${NC}"
            echo -e "  ${CYAN}这缕声波纯净透明，可以安心纳入图谱。${NC}"
            result=0
            log "INFO" "安全模块: $module_name"
        fi
        echo -e "${CYAN}------------------------------------------------------------${NC}"
    fi
    
    return $result
}

# ========== 生成报告 ==========
generate_report() {
    local safe_list=("$@")
    local danger_list=("${@:${#safe_list[@]}+1}")
    
    {
        echo "========================================"
        echo "洛云声波扫描报告"
        echo "扫描时间: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "洛云版本: v$SCRIPT_VERSION"
        echo "========================================"
        echo ""
        echo "【纯净声波】${#safe_list[@]} 个"
        for safe in "${safe_list[@]}"; do
            echo "  ✅ $safe"
        done
        echo ""
        echo "【危险/可疑声波】${#danger_list[@]} 个"
        for danger in "${danger_list[@]}"; do
            echo "  ⚠️  $danger"
        done
        echo ""
        echo "详细日志请查看: $LOG_FILE"
    } > "$REPORT_FILE"
    
    print_status "success" "报告已保存至: $REPORT_FILE"
    log "INFO" "报告已生成: $REPORT_FILE"
}

# ========== 获取模块列表 ==========
get_all_modules() {
    local dir="${1:-.}"
    local modules=()
    while IFS= read -r -d '' f; do
        modules+=("$f")
    done < <(find "$dir" -maxdepth 1 -name "*.zip" -print0 2>/dev/null)
    echo "${modules[@]}"
}

# ========== 显示模块列表 ==========
show_module_list() {
    local modules=("$@")
    echo -e "\n${BLUE}[ 等待解析的声波样本 ]${NC}"
    for i in "${!modules[@]}"; do
        local name=$(basename "${modules[$i]}")
        echo -e "  ${CYAN}[$((i+1))]${NC} $name"
    done
}

# ========== 主程序 ==========
print_header

# 检查更新（非静默模式）
echo ""
echo -ne "${CYAN}🔍 是否检查更新？(y/n, 默认y): ${NC}"
read -r check_update_choice
case "$check_update_choice" in
    n|N|no|NO)
        echo -e "${BLUE}跳过更新检查${NC}"
        ;;
    *)
        check_for_update
        ;;
esac

# 检查环境工具
check_strings > /dev/null 2>&1

modules=($(get_all_modules "."))
TOTAL_MODULES=${#modules[@]}

if [ $TOTAL_MODULES -eq 0 ]; then
    print_status "error" "洛云没有检测到任何 ZIP 声波样本，你是否放错了位置？"
    exit 1
fi

echo -e "\n${BLUE}[ 洛云的聆听方式 ]${NC}"
echo -e "  ${CYAN}1${NC} 选择性聆听（手动选择声波，可循环）"
echo -e "  ${CYAN}2${NC} 深度聆听（逐一解析所有声波）"
echo -e "  ${CYAN}3${NC} 快速扫描（批量记录声波图谱）"
echo -ne "\n${YELLOW}请选择聆听方式: ${NC}"
read mode

log "INFO" "启动洛云扫描仪，模式: $mode，模块数: $TOTAL_MODULES"

# ========== 模式1：选择性聆听 ==========
if [ "$mode" = "1" ]; then
    while true; do
        show_module_list "${modules[@]}"
        echo -e "  ${CYAN}[a]${NC} 聆听所有声波"
        echo -e "  ${CYAN}[q]${NC} 收起图谱"
        echo -ne "\n${YELLOW}请选择要聆听的声波序号 (a全选/q退出): ${NC}"
        read choice
        
        case "$choice" in
            q|Q) break ;;
            a|A)
                CURRENT_MODULE=0
                for f in "${modules[@]}"; do
                    CURRENT_MODULE=$((CURRENT_MODULE + 1))
                    show_progress "$CURRENT_MODULE" "$TOTAL_MODULES"
                    scan_single_module "$f" 1
                done
                echo ""
                ;;
            *)
                if [ "$choice" -ge 1 ] 2>/dev/null && [ "$choice" -le "$TOTAL_MODULES" ]; then
                    idx=$((choice-1))
                    scan_single_module "${modules[$idx]}" 1
                else
                    print_status "error" "洛云没有听到这个序号，请重新选择。"
                    continue
                fi
                ;;
        esac
        
        echo -ne "\n${YELLOW}是否继续聆听其他声波？ (y/n, 默认y): ${NC}"
        read cont
        case "$cont" in
            n|N|no|NO) break ;;
        esac
    done
fi

# ========== 模式2：深度聆听 ==========
if [ "$mode" = "2" ]; then
    echo -e "\n${BLUE}[ 洛云的深度聆听模式 ]${NC}"
    echo -e "${YELLOW}洛云将逐一解析以下 ${TOTAL_MODULES} 缕声波：${NC}"
    for f in "${modules[@]}"; do
        echo -e "  • $(basename "$f")"
    done
    echo -ne "\n${YELLOW}按回车，洛云开始解析...${NC}"
    read
    
    CURRENT_MODULE=0
    for i in "${!modules[@]}"; do
        CURRENT_MODULE=$((CURRENT_MODULE + 1))
        show_progress "$CURRENT_MODULE" "$TOTAL_MODULES"
        echo ""
        scan_single_module "${modules[$i]}" 1
        if [ $((i+1)) -lt $TOTAL_MODULES ]; then
            echo -ne "\n${YELLOW}按回车，洛云继续解析下一缕声波...${NC}"
            read
        fi
    done
    echo ""
fi

# ========== 模式3：快速扫描 ==========
if [ "$mode" = "3" ]; then
    safe_list=()
    danger_list=()
    
    echo -e "\n${BLUE}[ 洛云的声波图谱批量扫描 ]${NC}"
    echo -e "${YELLOW}洛云将快速扫描以下 ${TOTAL_MODULES} 缕声波：${NC}"
    for f in "${modules[@]}"; do
        echo -e "  • $(basename "$f")"
    done
    echo -ne "\n${YELLOW}按回车，洛云开始扫描...${NC}"
    read
    
    CURRENT_MODULE=0
    for f in "${modules[@]}"; do
        CURRENT_MODULE=$((CURRENT_MODULE + 1))
        show_progress "$CURRENT_MODULE" "$TOTAL_MODULES"
        scan_single_module "$f" 1
        if [ $? -eq 0 ]; then
            safe_list+=("$(basename "$f")")
        else
            danger_list+=("$(basename "$f")")
        fi
    done
    echo ""
    
    echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}[ 洛云的声波图谱汇总 ]${NC}"
    echo -e "  ${GREEN}纯净声波: ${#safe_list[@]}${NC}"
    echo -e "  ${RED}危险/可疑声波: ${#danger_list[@]}${NC}"
    
    if [ ${#danger_list[@]} -gt 0 ]; then
        echo -e "\n${RED}[ 需要警惕的声波清单 ]${NC}"
        for name in "${danger_list[@]}"; do
            echo -e "  ⚠ $name"
        done
    fi
    
    generate_report "${safe_list[@]}" "${danger_list[@]}"
fi

echo -e "\n${WHITE}洛云将此次听到的声波存入图谱，等待下一次共鸣。${NC}"
echo -e "${YELLOW}📌 免解锁环境提醒：任何重启都会丢失root权限，这是环境特性。${NC}"
echo -e "${RED}⚠️  若模块直接写入受 dm-verity 保护的系统分区（而非通过 OverlayFS），${NC}"
echo -e "${RED}   重启后校验失败，可能导致系统无法开机——这就是洛云所说的“永久静默”。${NC}"
echo -e "${GREEN}✅ 安全模块只操作 /data 或使用 OverlayFS 映射，物理系统分区始终不变。${NC}"
echo -e "${CYAN}💡 提示：如需检查更新，下次运行时可选择检查更新功能。${NC}"
