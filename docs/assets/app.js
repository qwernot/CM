const root = document.documentElement;
const pageRoot = document.body.dataset.root || '';

function setTheme(light) {
  root.classList.toggle('light', light);
  localStorage.setItem('cm-theme', light ? 'light' : 'dark');
  const button = document.getElementById('theme');
  if (button) button.textContent = light ? '☾' : '☀';
}
setTheme(localStorage.getItem('cm-theme') === 'light');
document.getElementById('theme')?.addEventListener('click', () => setTheme(!root.classList.contains('light')));

const mobile = document.getElementById('mobile');
const overlay = document.getElementById('overlay');
function menuOpen(open) {
  mobile?.classList.toggle('open', open);
  overlay?.classList.toggle('open', open);
}
document.getElementById('menu')?.addEventListener('click', () => menuOpen(true));
document.getElementById('close')?.addEventListener('click', () => menuOpen(false));
overlay?.addEventListener('click', () => menuOpen(false));

document.querySelectorAll('.copy').forEach(button => button.addEventListener('click', async () => {
  const value = button.nextElementSibling?.innerText || '';
  try {
    await navigator.clipboard.writeText(value);
  } catch (_) {
    const area = document.createElement('textarea');
    area.value = value;
    document.body.appendChild(area);
    area.select();
    document.execCommand('copy');
    area.remove();
  }
  button.textContent = '已复制';
  setTimeout(() => { button.textContent = '复制'; }, 1200);
}));

const pages = [
  ['快速开始', '安装方式、默认端口与首次配置', 'guide.html'],
  ['Linux 原生部署', 'systemd 一键安装与维护', 'deploy/native.html'],
  ['Docker Compose', '多架构镜像与 macvlan 独立 IP', 'deploy/docker.html'],
  ['RouterOS 部署', '容器、veth、DNS 与按设备分流', 'deploy/routeros.html'],
  ['功能使用', '订阅、节点、DNS、控制台和系统设置', 'user/guide.html'],
  ['分流与规则', '筛选组、路由规则、DNS 模式和示例', 'user/routing.html'],
  ['回家配置', 'Hysteria2 回家服务配置', 'user/backhome.html'],
  ['常见问题', '订阅、代理、DNS 与容器排障', 'user/faq.html']
];
const modal = document.createElement('div');
modal.className = 'search-modal';
modal.innerHTML = '<div class="search-box"><input aria-label="搜索文档" placeholder="搜索文档…"><div class="search-results"></div></div>';
document.body.appendChild(modal);
const searchInput = modal.querySelector('input');
const searchResults = modal.querySelector('.search-results');
function renderSearch(term = '') {
  const needle = term.trim().toLowerCase();
  const matches = pages.filter(item => !needle || `${item[0]} ${item[1]}`.toLowerCase().includes(needle));
  searchResults.innerHTML = matches.map(item => `<a href="${pageRoot}${item[2]}"><strong>${item[0]}</strong><br><small>${item[1]}</small></a>`).join('') || '<a>没有找到相关页面</a>';
}
function searchOpen(open) {
  modal.classList.toggle('open', open);
  if (open) { renderSearch(''); setTimeout(() => searchInput.focus(), 0); }
}
document.getElementById('search')?.addEventListener('click', () => searchOpen(true));
searchInput.addEventListener('input', event => renderSearch(event.target.value));
modal.addEventListener('click', event => { if (event.target === modal) searchOpen(false); });
document.addEventListener('keydown', event => {
  if (event.key === 'Escape') searchOpen(false);
  if ((event.key === '/' && !/INPUT|TEXTAREA/.test(document.activeElement?.tagName)) || ((event.ctrlKey || event.metaKey) && event.key.toLowerCase() === 'k')) {
    event.preventDefault(); searchOpen(true);
  }
});
