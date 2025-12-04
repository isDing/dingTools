async function fetchJSON(url, opts={}) {
  const res = await fetch(url, opts);
  const txt = await res.text();
  try { return JSON.parse(txt); } catch { return { ok:false, raw: txt }; }
}

async function fetchText(url) {
  const res = await fetch(url);
  return await res.text();
}

async function refresh() {
  const statusEl = document.getElementById('status');
  const btnStart = document.getElementById('btn-start');
  const btnStop = document.getElementById('btn-stop');

  try {
    const st = await fetchJSON('/cgi-bin/status.sh');
    if (st && st.running) {
      statusEl.textContent = `运行中 PID: ${st.pids || ''}`;
      statusEl.className = 'status running';
      btnStart.classList.add('hidden');
      btnStop.classList.remove('hidden');
      btnStop.disabled = false;
    } else {
      statusEl.textContent = '未运行';
      statusEl.className = 'status stopped';
      btnStart.classList.remove('hidden');
      btnStop.classList.add('hidden');
      btnStart.disabled = false;
    }
  } catch (e) {
    statusEl.textContent = '状态获取失败';
    statusEl.className = 'status';
    btnStart.classList.remove('hidden');
    btnStop.classList.add('hidden');
    btnStart.disabled = false;
  }

  try {
    const log = await fetchText('/cgi-bin/log.sh');
    document.getElementById('log').value = log;
  } catch (e) {
    document.getElementById('log').value = '日志获取失败';
  }
}

async function startScript() {
  const statusEl = document.getElementById('status');
  const btnStart = document.getElementById('btn-start');
  btnStart.disabled = true;
  statusEl.textContent = '启动中...';
  statusEl.className = 'status';
  try {
    const r = await fetchJSON('/cgi-bin/start.sh');
    if (r && r.ok) {
      statusEl.textContent = r.already_running ? '已在运行' : `已启动 PID: ${r.pids || ''}`;
    } else {
      statusEl.textContent = `启动失败 ${r && r.error ? '('+r.error+')' : ''}`;
      btnStart.disabled = false;
    }
  } catch (e) {
    statusEl.textContent = '启动失败';
    btnStart.disabled = false;
  }
  setTimeout(refresh, 1000);
}

async function stopScript() {
  const statusEl = document.getElementById('status');
  const btnStop = document.getElementById('btn-stop');
  btnStop.disabled = true;
  statusEl.textContent = '停止中...';
  statusEl.className = 'status';
  try {
    const r = await fetchJSON('/cgi-bin/stop.sh');
    if (r && r.ok) {
      statusEl.textContent = r.force_killed ? '已强制停止' : '已停止';
    } else {
      statusEl.textContent = `停止失败 ${r && r.error ? '('+r.error+')' : ''}`;
      btnStop.disabled = false;
    }
  } catch (e) {
    statusEl.textContent = '停止失败';
    btnStop.disabled = false;
  }
  setTimeout(refresh, 1000);
}

async function clearLog() {
  const btnClear = document.getElementById('btn-clear-log');
  const logEl = document.getElementById('log');

  if (!confirm('确定要清空日志文件吗？')) {
    return;
  }

  btnClear.disabled = true;
  const originalText = btnClear.textContent;
  btnClear.textContent = '清空中...';

  try {
    const r = await fetchJSON('/cgi-bin/clear_log.sh');
    if (r && r.ok) {
      logEl.value = '日志已清空';
      btnClear.textContent = '已清空';
      setTimeout(() => {
        btnClear.textContent = originalText;
        btnClear.disabled = false;
        refresh();
      }, 1500);
    } else {
      alert(`清空失败: ${r && r.error ? r.error : '未知错误'}`);
      btnClear.textContent = originalText;
      btnClear.disabled = false;
    }
  } catch (e) {
    alert('清空失败，请重试');
    btnClear.textContent = originalText;
    btnClear.disabled = false;
  }
}

window.addEventListener('DOMContentLoaded', () => {
  document.getElementById('btn-refresh').addEventListener('click', refresh);
  document.getElementById('btn-start').addEventListener('click', startScript);
  document.getElementById('btn-stop').addEventListener('click', stopScript);
  document.getElementById('btn-clear-log').addEventListener('click', clearLog);
  refresh();
  // 自动刷新
  setInterval(refresh, 10000);
});

