#!/system/bin/sh

################################################################################
# 自动巡护脚本
# 功能：每天10点后开始检测是否已执行，当天未执行则随机延迟0-60分钟后执行一次
################################################################################

LOG_FILE="/data/local/tmp/xunshan.log"
STATE_FILE="/data/local/tmp/auto_xunshan_state"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >> "$LOG_FILE"
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
        uiautomator dump /data/local/tmp/ui.xml 2>/dev/null
        grep -q "$_text" /data/local/tmp/ui.xml 2>/dev/null && return 0
        _i=$((_i + 1))
        sleep 2
    done
    return 1
}

# 通过文本点击按钮（从ui.xml解析坐标）
tap_by_text() {
    _text="$1"

    # 确保ui.xml是最新的
    uiautomator dump /data/local/tmp/ui.xml 2>/dev/null

    # 提取包含指定文本的完整节点，然后获取bounds
    # 使用 grep -o 提取 text="xxx"...bounds="[...]" 的完整模式
    _node=$(grep -o "text=\"$_text\"[^>]*" /data/local/tmp/ui.xml | head -1)

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

    # 移除非ASCII字符，避免 input text 报错
    _msg=$(echo "$_msg_content" | sed 's/[^a-zA-Z0-9_\-\.]//g')
    input text "AutoScript_${_msg_type}:$_msg"
    sleep 1
    input tap 970 895  # 发送
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
        send_qq_notice "FakeLocation_Update_Available"
    fi

    input tap 85 185    # 菜单
    sleep 1
    input tap 282 826   # 选择位置
    sleep 1
    input tap 190 1111  # 开始模拟
    sleep 6

    # 验证启动
    verify_ui "停止模拟" 2 || send_qq_error "FakeLocation_Start_Failed"

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
                send_qq_error "Data_Upload_Pending_After_40Min"
            fi

            log "第三次检查通过，待上传数据已清除"
        else
            log "第二次检查通过，待上传数据已清除"
        fi
    else
        log "无待上传数据，继续执行"
    fi
}

# 检查“我的巡护记录”列表中第一条记录日期是否为今天
# 不满足则通过 QQ 发送提醒，但不退出脚本
check_first_record_date_today_or_notify() {
    log "检查巡护记录第一条日期"

    # 导出当前界面到 ui.xml
    uiautomator dump /data/local/tmp/ui.xml 2>/dev/null

    # 从第一个日期节点提取文本（形如 2025-12-02 13:25:32）
    _line=$(grep -o 'text="[^\"]*"[^>]*resource-id="cn.piesat.hnly.fcs:id/tv_date"' /data/local/tmp/ui.xml | head -1)
    if [ -z "$_line" ]; then
        log "WARN: 未找到记录日期节点 tv_date"
        send_qq_notice "Record_Date_NotFound"
        return 1
    fi

    _full_datetime=$(echo "$_line" | sed 's/.*text="\([^"]*\)".*/\1/')
    _date_part=$(echo "$_full_datetime" | awk '{print $1}')
    _today=$(date '+%Y-%m-%d')

    if [ "$_date_part" != "$_today" ]; then
        log "WARN: 第一条记录日期($_date_part) != 今天($_today)"
        # 仅提醒，不退出
        send_qq_notice "First_Record_Not_Today_$_date_part"
    else
        log "第一条记录日期为今天: $_today"
        send_qq_notice "The task has been completed today!"
    fi

    return 0
}

# 执行巡护流程
run_patrol() {
    log "======== 开始巡护 ========"

    # 亮屏
    input keyevent KEYCODE_WAKEUP
    home

    # 启动 Fake Location
    start_fake_location

    # 开始时提示
    send_qq_notice "begin task!"
    home
    sleep 10

    # 打开巡护应用
    log "打开巡护应用"
    input tap 692 1820
    sleep 1
    input tap 500 1600
    sleep 4

    # 下拉刷新
    input swipe 500 300 500 1200 200
    sleep 2

    # 检查是否有待上传数据
    check_pending_upload

    # 开始巡护
    log "开始巡护"
    input tap 550 550
    sleep 2

    # 随机巡护时长：70-90分钟
    _duration=$((RANDOM % 1200 + 4200))
    log "巡护 $_duration 秒 ($((_duration/60)) 分钟)"
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
    # 校验第一条记录日期是否为今天（不符合仅提醒，不退出）
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
    log "==== 脚本启动 ===="

    while true; do
        _hour=$(date +%H)

        # 简化策略：从大于10点开始检测，若当日未执行，则随机延迟150-1950秒后执行一次
        if [ "$_hour" -gt 10 ]; then
            if ! has_triggered_today; then
                log "触发时间到达，准备执行"

                # 随机延迟 150-1950 秒
                _delay=$((RANDOM % 1800 + 150))
                log "随机延迟 $_delay 秒"
                sleep $_delay

                # 执行巡护（失败会自动退出）
                run_patrol
                log "巡护成功"
                mark_triggered
            fi
        fi

        # 每5分钟检查一次
        sleep 300
    done
}

main
