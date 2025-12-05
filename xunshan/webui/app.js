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

// 标签页切换
function switchTab(tabName) {
  console.log('Switching to tab:', tabName);

  // 切换标签页激活状态
  document.querySelectorAll('.tab').forEach(tab => {
    if (tab.dataset.tab === tabName) {
      tab.classList.add('active');
    } else {
      tab.classList.remove('active');
    }
  });

  // 切换内容区域
  document.querySelectorAll('.tab-content').forEach(content => {
    content.classList.remove('active');
  });
  document.getElementById(`tab-${tabName}`).classList.add('active');

  // 如果切换到编辑器标签页，加载脚本内容
  if (tabName === 'editor') {
    loadScript();
  }
}

// 加载脚本内容
async function loadScript() {
  const editorEl = document.getElementById('script-editor');
  editorEl.value = '加载中...';
  editorEl.disabled = true;

  try {
    const r = await fetchJSON('/cgi-bin/read_script.sh');
    if (r && r.ok) {
      // 优先使用 base64 解码（修复中文乱码）
      if (r.content_base64) {
        // 正确解码 UTF-8 中文字符
        const binaryString = atob(r.content_base64);
        const bytes = new Uint8Array(binaryString.length);
        for (let i = 0; i < binaryString.length; i++) {
          bytes[i] = binaryString.charCodeAt(i);
        }
        const decoder = new TextDecoder('utf-8');
        editorEl.value = decoder.decode(bytes);
      } else if (r.content) {
        // 处理转义的换行符
        editorEl.value = r.content.replace(/\\n/g, '\n').replace(/\\"/g, '"').replace(/\\\\/g, '\\');
      } else {
        editorEl.value = '脚本内容为空';
      }
      editorEl.disabled = false;
    } else {
      editorEl.value = `加载失败: ${r && r.error ? r.error : '未知错误'}`;
      editorEl.disabled = true;
    }
  } catch (e) {
    editorEl.value = '加载失败，请重试: ' + e.message;
    editorEl.disabled = true;
  }
}

// 保存脚本
async function saveScript() {
  const editorEl = document.getElementById('script-editor');
  const btnSave = document.getElementById('btn-save-script');
  const content = editorEl.value;

  if (!content.trim()) {
    alert('脚本内容不能为空');
    return;
  }

  if (!confirm('确定要保存脚本吗？\n保存前会自动备份原文件到 autoClickForXunShan.sh.bak')) {
    return;
  }

  btnSave.disabled = true;
  const originalText = btnSave.textContent;
  btnSave.textContent = '保存中...';

  try {
    // 使用 base64 编码避免 URL 编码问题
    const encoder = new TextEncoder();
    const bytes = encoder.encode(content);
    let binary = '';
    for (let i = 0; i < bytes.length; i++) {
      binary += String.fromCharCode(bytes[i]);
    }
    const base64Content = btoa(binary);

    const formData = 'content_base64=' + base64Content;
    const res = await fetch('/cgi-bin/save_script.sh', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: formData
    });
    const txt = await res.text();
    const r = JSON.parse(txt);

    if (r && r.ok) {
      btnSave.textContent = '保存成功';
      setTimeout(() => {
        btnSave.textContent = originalText;
        btnSave.disabled = false;
      }, 1500);

      let msg = `脚本保存成功！\n文件大小: ${r.size} 字节`;
      if (r.permissions) {
        msg += `\n文件权限: ${r.permissions}`;
      }
      alert(msg);
    } else {
      const errorMessages = {
        'content_empty': '脚本内容为空',
        'backup_failed': '备份原文件失败',
        'write_failed': '写入文件失败（需要 root 权限）',
        'chmod_failed': '设置执行权限失败',
        'file_not_found': '保存后文件未找到',
        'not_executable': '文件不可执行',
        'decode_failed': 'Base64 解码失败'
      };

      const errorMsg = r && r.error ? (errorMessages[r.error] || r.error) : '未知错误';
      alert(`保存失败: ${errorMsg}`);
      btnSave.textContent = originalText;
      btnSave.disabled = false;
    }
  } catch (e) {
    alert('保存失败，请重试: ' + e.message);
    btnSave.textContent = originalText;
    btnSave.disabled = false;
  }
}

window.addEventListener('DOMContentLoaded', () => {
  console.log('DOM loaded, initializing...');

  document.getElementById('btn-refresh').addEventListener('click', refresh);
  document.getElementById('btn-start').addEventListener('click', startScript);
  document.getElementById('btn-stop').addEventListener('click', stopScript);
  document.getElementById('btn-clear-log').addEventListener('click', clearLog);
  document.getElementById('btn-save-script').addEventListener('click', saveScript);
  document.getElementById('btn-reload-script').addEventListener('click', loadScript);

  // 标签页切换
  const tabs = document.querySelectorAll('.tab');
  console.log('Found tabs:', tabs.length);
  tabs.forEach(tab => {
    console.log('Adding click listener to tab:', tab.dataset.tab);
    tab.addEventListener('click', () => {
      console.log('Tab clicked:', tab.dataset.tab);
      switchTab(tab.dataset.tab);
    });
  });

  refresh();
  // 自动刷新
  setInterval(refresh, 10000);

  console.log('Initialization complete');
});

