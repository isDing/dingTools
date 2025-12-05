#!/system/bin/sh

################################################################################
# 自动巡护脚本
# 功能：每天11点后开始检测是否已执行，当天未执行则随机延迟150-1950秒后执行一次
################################################################################

ROOT_DIR="/data/local/tmp/xunshan"
LOG_FILE="$ROOT_DIR/xunshan.log"
STATE_FILE="$ROOT_DIR/auto_xunshan_state"
UI_XML="$ROOT_DIR/ui.xml"
UI_LINES="$ROOT_DIR/ui_lines.txt"

mkdir -p "$ROOT_DIR"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >> "$LOG_FILE"
}

# 计算并返回“当前时间 + 指定秒数”的目标时间字符串
# 优先使用支持 -d 的 date；无法格式化时回退输出 epoch 值
target_time_str() {
    _sec="$1"
    _now=$(date +%s)
    _target=$((_now + _sec))
    if date -d "@$_target" "+%Y-%m-%d %H:%M:%S" >/dev/null 2>&1; then
        date -d "@$_target" "+%Y-%m-%d %H:%M:%S"
    elif command -v busybox >/dev/null 2>&1; then
        busybox date -D %s -d "$_target" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "epoch=$_target"
    else
        echo "epoch=$_target"
    fi
}

# 返回桌面
home() {
    input keyevent KEYCODE_HOME
    input keyevent KEYCODE_HOME
    sleep 1
}

# 清理后台任务
# 参数：要删除的应用个数（默认1个）
clear_app() {
    _count="${1:-1}"
    input keyevent KEYCODE_APP_SWITCH
    sleep 1

    _i=0
    while [ $_i -lt $_count ]; do
        input swipe 330 1340 800 1340 200
        sleep 0.5
        _i=$((_i + 1))
    done

    sleep 1
    input keyevent KEYCODE_HOME
}

# UI 验证
verify_ui() {
    _text="$1"
    _retries="${2:-2}"
    _i=0
    while [ $_i -lt $_retries ]; do
        uiautomator dump "$UI_XML" 2>/dev/null
        grep -q "$_text" "$UI_XML" 2>/dev/null && return 0
        _i=$((_i + 1))
        sleep 2
    done
    return 1
}

# 通过文本点击按钮（从ui.xml解析坐标）
tap_by_text() {
    _text="$1"

    # 确保ui.xml是最新的
    uiautomator dump "$UI_XML" 2>/dev/null

    # 提取包含指定文本的完整节点，然后获取bounds
    # 使用 grep -o 提取 text="xxx"...bounds="[...]" 的完整模式
    _node=$(grep -o "text=\"$_text\"[^>]*" "$UI_XML" | head -1)

    if [ -z "$_node" ]; then
        log "ERROR: 未找到按钮文本 $_text"
        return 1
    fi

    # 从节点中提取bounds
    _bounds=$(echo "$_node" | sed 's/.*bounds="\([^"]*\)".*/\1/')

    if [ -z "$_bounds" ]; then
        log "ERROR: 无法提取坐标"
        return 1
    fi

    # 提取四个坐标值: [x1,y1][x2,y2] -> x1 y1 x2 y2
    _coords=$(echo "$_bounds" | sed 's/\[\([0-9]*\),\([0-9]*\)\]\[\([0-9]*\),\([0-9]*\)\]/\1 \2 \3 \4/')
    _x1=$(echo $_coords | awk '{print $1}')
    _y1=$(echo $_coords | awk '{print $2}')
    _x2=$(echo $_coords | awk '{print $3}')
    _y2=$(echo $_coords | awk '{print $4}')

    # 计算中心点
    _center_x=$(((_x1 + _x2) / 2))
    _center_y=$(((_y1 + _y2) / 2))

    log "点击按钮 '$_text' 坐标: [$_x1,$_y1][$_x2,$_y2] 中心点 ($_center_x, $_center_y)"
    input tap $_center_x $_center_y
    return 0
}

# 判断 resource-id 是否存在（可重试）
verify_id() {
    _id="$1"
    _retries="${2:-2}"
    _i=0
    while [ $_i -lt $_retries ]; do
        uiautomator dump "$UI_XML" 2>/dev/null
        # 使用固定字符串匹配，避免正则特殊字符影响
        grep -qF "resource-id=\"$_id\"" "$UI_XML" 2>/dev/null && return 0
        _i=$((_i + 1))
        sleep 2
    done
    return 1
}

# 通过 resource-id 点击（从 ui.xml 解析 bounds 坐标）
tap_by_id() {
    _id="$1"

    # 确保 ui.xml 最新
    uiautomator dump "$UI_XML" 2>/dev/null

    # 精准提取包含该 resource-id 的 <node ...> 起始标签（单行XML也可用）
    # 说明：<node[^>]*resource-id="..."[^>]*> 会截取到下一个 '>' 为止，恰为起始标签
    _node=$(grep -o "<node[^>]*resource-id=\"$_id\"[^>]*>" "$UI_XML" | head -1)
    if [ -z "$_node" ]; then
        log "ERROR: 未找到 resource-id $_id"
        return 1
    fi

    # 从起始标签中提取 bounds
    _bounds=$(echo "$_node" | sed -n 's/.*bounds="\([^"]*\)".*/\1/p')
    if [ -z "$_bounds" ]; then
        log "ERROR: 未在节点中找到 bounds (resource-id: $_id)"
        return 1
    fi

    # 校验坐标格式并解析为四元组
    if ! echo "$_bounds" | grep -qE '^\[[0-9]+,[0-9]+\]\[[0-9]+,[0-9]+\]$'; then
        log "ERROR: bounds 格式非法: $_bounds (resource-id: $_id)"
        return 1
    fi

    _coords=$(echo "$_bounds" | sed 's/\[\([0-9]*\),\([0-9]*\)\]\[\([0-9]*\),\([0-9]*\)\]/\1 \2 \3 \4/')
    _x1=$(echo $_coords | awk '{print $1}')
    _y1=$(echo $_coords | awk '{print $2}')
    _x2=$(echo $_coords | awk '{print $3}')
    _y2=$(echo $_coords | awk '{print $4}')

    # 计算中心点
    _center_x=$(((_x1 + _x2) / 2))
    _center_y=$(((_y1 + _y2) / 2))

    log "点击 resource-id '$_id' 坐标: [$_x1,$_y1][$_x2,$_y2] 中心点 ($_center_x, $_center_y)"
    input tap $_center_x $_center_y
    return 0
}

# QQ 消息发送（通用函数）
send_qq_message_internal() {
    _msg_type="$1"  # Error 或 Notice
    _msg_content="$2"

    am start -n com.tencent.mobileqq/.activity.SplashActivity
    sleep 2

    input tap 315 336  # 搜索
    sleep 1
    input text "907905997"
    input keyevent KEYCODE_ENTER
    sleep 2

    input tap 590 470  # 点击好友
    sleep 2
    input tap 480 2200  # 输入框
    sleep 1

    # 组装类型行
    _type_line="AutoScript ${_msg_type}:"
    _type_encoded=$(echo "$_type_line" | sed -e 's/[^ -~]/?/g' -e 's/ /%s/g')

    # 展开字面量 "\n" 为实际换行，并逐行输入内容
    _msg_expanded=$(printf "%s" "$_msg_content" | awk '{gsub(/\\n/,"\n"); printf "%s", $0}')

    # 输入类型行并换行
    input text "$_type_encoded"
    input keyevent KEYCODE_ENTER
    sleep 0.3

    # 按行输入内容，每行后发送一次 ENTER 形成换行
    printf "%s" "$_msg_expanded" | while IFS= read -r _line || [ -n "$_line" ]; do
        _line_norm=$(printf "%s" "$_line" | sed -e 's/[^-a-zA-Z0-9 _\.,:!()]/?/g')
        _line_encoded=$(printf "%s" "$_line_norm" | sed -e 's/ /%s/g')
        if [ -n "$_line_encoded" ]; then
            input text "$_line_encoded"
        fi
        input keyevent KEYCODE_ENTER
        sleep 0.3
    done
    sleep 0.5
    input tap 928 973  # 发送
    sleep 2

    input keyevent KEYCODE_BACK
    input keyevent KEYCODE_BACK
    input keyevent KEYCODE_BACK

    # 清理QQ后台任务
    input keyevent KEYCODE_APP_SWITCH
    sleep 1
    input swipe 330 1340 800 1340 200
    sleep 1
    input tap 330 1340
    sleep 2
}

# QQ 错误通知并退出
send_qq_error() {
    log "ERROR: $1"
    send_qq_message_internal "Error" "$1"
    log "脚本退出"
    input keyevent KEYCODE_SLEEP
    exit 1
}

# QQ 通知（不退出）
send_qq_notice() {
    log "NOTICE: $1"
    send_qq_message_internal "Notice" "$1"
    log "通知已发送，继续执行"
}

# 启动 Fake Location
start_fake_location() {
    log "启动 Fake Location"

    # 启动 Magisk
    am start -n com.topjohnwu.magisk/.ui.MainActivity
    sleep 4
    home

    # 打开 Fake Location
    am start -n com.lerist.fakelocation/.ui.activity.MainActivity
    sleep 5

    # 检查是否有更新弹窗
    if verify_ui "暂不更新" 1; then
        log "检测到更新弹窗，点击暂不更新"
        tap_by_text "暂不更新"
        sleep 1
        send_qq_notice "FakeLocation update available."
    fi

    input tap 85 185    # 菜单
    sleep 1
    input tap 282 826   # 选择位置
    sleep 1
    input tap 190 1111  # 开始模拟
    sleep 6

    # 验证启动
    verify_ui "停止模拟" 2 || send_qq_error "FakeLocation start failed."

    log "Fake Location 启动成功"
    input tap 500 900
    sleep 5
    home
}

# 检查待上传数据（最多3次，间隔10分钟和30分钟）
check_pending_upload() {
    log "检查是否有待上传数据"

    # 第一次检查
    if verify_ui "待上传" 1; then
        log "发现待上传数据，等待10分钟后重新检查"
        sleep 600

        # 第二次检查前下拉刷新
        input swipe 500 300 500 1200 200
        sleep 2

        if verify_ui "待上传" 1; then
            log "仍有待上传数据，等待30分钟后重新检查"
            sleep 1800

            # 第三次检查前下拉刷新
            input swipe 500 300 500 1200 200
            sleep 2

            if verify_ui "待上传" 1; then
                send_qq_error "Data upload pending after 40Min."
            fi

            log "第三次检查通过，待上传数据已清除"
        else
            log "第二次检查通过，待上传数据已清除"
        fi
    else
        log "无待上传数据，继续执行"
    fi
}

# 重新定义：检查第一条记录是否为“今天且有效(无 iv_valid)”
check_first_record_date_today_or_notify() {
    log "检查巡护记录第一条日期与有效性"
    # 导出 XML 并按标签断行
    uiautomator dump "$UI_XML" 2>/dev/null
    sed 's/></>\n</g' "$UI_XML" > "$UI_LINES"

    # 定位列表容器
    _rv_line=$(grep -n 'resource-id="cn.piesat.hnly.fcs:id/recyclerView"' "$UI_LINES" | head -1 | cut -d: -f1)
    if [ -z "$_rv_line" ]; then
        log "ERROR: 未找到 recyclerView 容器"
        send_qq_error "validity check: RecyclerView not found."
    fi

    # 找到容器后的第一条 tv_date（即第一条记录）
    _date_line_no=$(awk -v s="$_rv_line" 'NR>s && /resource-id="cn.piesat.hnly.fcs:id\/tv_date"/ {print NR; exit}' "$UI_LINES")
    if [ -z "$_date_line_no" ]; then
        log "ERROR: 未找到第一条记录日期(tv_date)"
        send_qq_error "validity check: First record date not found."
    fi

    _date_line=$(sed -n "${_date_line_no}p" "$UI_LINES")
    _full_datetime=$(echo "$_date_line" | sed -n 's/.*text="\([^"]*\)".*/\1/p')
    _date_part=$(echo "$_full_datetime" | awk '{print $1}')
    _today=$(date '+%Y-%m-%d')
    if [ -z "$_full_datetime" ]; then
        log "ERROR: 第一条记录日期文本缺失"
        send_qq_error "validity check: First record date text missing."
    fi

    # 先判定日期是否为今天，不符合直接错误退出
    if [ "$_date_part" != "$_today" ]; then
        log "ERROR: 第一条记录日期($_date_part) != 今天($_today)"
        send_qq_error "validity check: The first record is $_date_part not today. Please try again!"
    fi

    # 再检查是否存在 iv_valid 无效图标
    # 找到第一条记录所属的 ViewGroup 的结束位置
    # 方法：从 tv_date 所在行开始向下找到下一个 index="1" 的 ViewGroup（第二条记录的开始）
    _first_record_end=$_date_line_no
    _line_count=$(wc -l < "$UI_LINES")
    _i=$((_date_line_no + 1))

    # 向下搜索，找到第二条记录的开始位置（包含 index="1" 的 ViewGroup）
    while [ $_i -le $_line_count ]; do
        _line=$(sed -n "${_i}p" "$UI_LINES")
        # 检查是否是第二条记录的 ViewGroup（index="1" 且 class="android.view.ViewGroup"）
        if echo "$_line" | grep -q 'class="android.view.ViewGroup"' && echo "$_line" | grep -q 'index="1"'; then
            _first_record_end=$((_i - 1))
            break
        fi
        _i=$((_i + 1))
    done

    # 在第一条记录的范围内查找 iv_valid
    # 从第一条记录的 ViewGroup 开始位置到结束位置
    _first_record_start=$((_rv_line + 1))
    if sed -n "${_first_record_start},${_first_record_end}p" "$UI_LINES" | grep -q 'resource-id="cn.piesat.hnly.fcs:id/iv_valid"'; then
        log "ERROR: 第一条记录存在 iv_valid 无效标识 (行范围: $_first_record_start-$_first_record_end)"
        send_qq_error "validity check: The first record invalid! Please try again!"
    fi

    # 到这里表示为“今天且有效”
    log "第一条记录为今天且无无效图标: $_full_datetime"
    send_qq_notice "The task has been completed today!\nDate:${_full_datetime}"
    return 0
}

# 执行巡护流程
run_patrol() {
    _duration="$1"
    log "======== 开始巡护 ========"

    # 亮屏
    input keyevent KEYCODE_WAKEUP
    home

    # 启动 Fake Location
    start_fake_location
    sleep 2

    # 打开巡护应用
    log "打开巡护应用"
    input tap 692 1820
    sleep 1
    input tap 500 1600
    sleep 6

    # 下拉刷新
    input swipe 500 300 500 1200 200
    sleep 2

    # 盲判断升级弹窗出现时，开始巡护按钮会被遮挡?
    if ! verify_id "cn.piesat.hnly.fcs:id/btn_patrol"; then
        send_qq_error "The start patrol button is blocked."
    fi

    # 检查是否有待上传数据
    check_pending_upload

    # 开始巡护
    log "开始巡护"
    input tap 550 550
    sleep 2

    # 巡护时长：由 main 传入（单位：秒）
    log "巡护 $_duration 秒 ($((_duration/60)) 分钟)，目标结束时间: $(target_time_str $_duration)"
    sleep $_duration

    # 结束巡护
    log "结束巡护"
    input swipe 550 2115 550 1750 200
    sleep 1
    input tap 800 1590  # 结束按钮
    sleep 1
    input tap 750 1350  # 确认
    sleep 1

    # 刷新任务
    input swipe 520 930 520 1730 300
    sleep 2

    # 检查结果
    tap_by_text "我的巡护记录"
    sleep 2
    # 校验第一条记录日期是否为今天；若检查失败会在函数内直接退出；成功则继续执行清理
    check_first_record_date_today_or_notify

    # 返回并锁屏
    input keyevent KEYCODE_BACK
    input keyevent KEYCODE_BACK
    input keyevent KEYCODE_BACK
    home
    clear_app 2
    input keyevent KEYCODE_SLEEP

    log "======== 巡护完成 ========"
}

# 检查今天是否已触发
has_triggered_today() {
    [ -f "$STATE_FILE" ] || return 1
    _last_date=$(cat "$STATE_FILE" 2>/dev/null)
    [ "$_last_date" = "$(date '+%Y-%m-%d')" ]
}

# 标记今天已触发
mark_triggered() {
    date '+%Y-%m-%d' > "$STATE_FILE"
}

# 主循环
main() {
    log "==== 脚本启动2 ===="

    sleep 120

    while true; do
        _hour=$(date +%H)

        # 简化策略：从大于11点开始检测，若当日未执行，则随机延迟150-1950秒后执行一次
        if [ "$_hour" -ge 11 ]; then
            if ! has_triggered_today; then
                log "触发时间到达，准备执行"

                # 随机延迟 150-1950 秒
                _delay=$((RANDOM % 1800 + 150))

                # 在 main 中定义本次巡护时长（70-90 分钟随机，单位：秒）
                _duration=$((RANDOM % 1200 + 4200))

                # 计算开始/结束时间：
                # - 开始时间 = 当前时间 + 随机延时（目标执行时间）
                # - 结束时间 = 开始时间 + 持续时长
                _start_ts_str=$(target_time_str $_delay)
                _end_ts_str=$(target_time_str $((_delay + _duration)))
                _dur_min=$((_duration/60))

                # 在执行巡护前发送 QQ 通知：开始时间、结束时间、持续时间
                input keyevent KEYCODE_WAKEUP
                home
                send_qq_notice "------\nToday task:\nStart:${_start_ts_str}\nEnd:${_end_ts_str}\nDuration:${_duration}s (${_dur_min}min)"
                home
                input keyevent KEYCODE_SLEEP

                # 发送通知后再进行随机延时
                log "随机延迟 $_delay 秒，目标执行时间: ${_start_ts_str}"
                sleep $_delay

                # 执行巡护（失败会自动退出）
                run_patrol "$_duration"
                log "巡护成功"
                mark_triggered
            fi
        fi

        # 每5分钟检查一次
        sleep 300
    done
}

main
