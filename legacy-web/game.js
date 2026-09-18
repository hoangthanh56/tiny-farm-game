'use strict';
const { CROPS, initial, ready, value, valid, act } = Farm;
const SAVE_KEY = 'tiny-farm-save-v1';
let state = initial();
let tool = 'plant';
let selected = 'carrot';
let toastTimer;
let loadNotice = '';
const $ = selector => document.querySelector(selector);
try {
  const raw = localStorage.getItem(SAVE_KEY);
  if (raw) {
    const saved = JSON.parse(raw);
    if (!valid(saved)) throw new Error('Invalid save');
    state = saved;
  }
} catch {
  loadNotice = 'Không đọc được bản lưu. Bạn đang chơi một nông trại mới.';
}
function save() {
  try {
    localStorage.setItem(SAVE_KEY, JSON.stringify(state));
    $('#save-status').textContent = 'Đã lưu tự động · Cây vẫn lớn khi bạn đóng game.';
  } catch {
    $('#save-status').textContent = 'Trình duyệt không cho lưu. Tiến trình chỉ giữ trong phiên này.';
  }
}
function toast(message) {
  $('#toast').textContent = message;
  $('#toast').classList.add('visible');
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => $('#toast').classList.remove('visible'), 3600);
}
const field = $('#field');
for (let index = 0; index < state.plots.length; index++) {
  const button = document.createElement('button');
  button.className = 'plot';
  button.innerHTML = '<span class="plot-icon" aria-hidden="true"></span><span class="plot-label"></span><span class="progress"></span>';
  button.addEventListener('click', () => perform({ type: tool, crop: selected, index }));
  field.append(button);
}
for (const [id, crop] of Object.entries(CROPS)) {
  const row = document.createElement('div');
  row.className = 'seed-row';
  row.dataset.crop = id;
  row.innerHTML = `<button class="seed-select" aria-label="Chọn hạt ${crop.name}"><span class="seed-icon">${crop.icon}</span><span><span class="seed-name">${crop.name}</span><span class="seed-detail"></span></span></button><button class="buy" title="Mua 1 hạt ${crop.name}">+ ${crop.buy} xu</button>`;
  row.querySelector('.seed-select').addEventListener('click', () => { selected = id; selectTool('plant'); render(); });
  row.querySelector('.buy').addEventListener('click', () => perform({ type: 'buy', crop: id }));
  $('#seeds').append(row);
}
function renderField() {
  const now = Date.now();
  state.plots.forEach((plot, index) => {
    const button = field.children[index];
    const locked = index >= state.unlocked;
    const grown = ready(plot, now);
    const wet = !!plot && plot.wateredAt !== null;
    const progress = wet ? Math.max(0, Math.min(1, (now - plot.wateredAt) / (CROPS[plot.crop].seconds * 1000))) : 0;
    const icon = locked ? '🔒' : !plot ? '+' : grown ? CROPS[plot.crop].icon : progress > .5 ? '🌿' : '🌱';
    const label = locked ? 'Chưa mở' : !plot ? 'Đất trống' : grown ? 'Thu hoạch ngay' : !wet ? 'Cần nước 💧' : `${Math.ceil((1 - progress) * CROPS[plot.crop].seconds)} giây`;
    button.className = `plot${locked ? ' locked' : ''}${wet ? ' wet' : ''}${grown ? ' ready' : ''}`;
    button.querySelector('.plot-icon').textContent = icon;
    button.querySelector('.plot-label').textContent = label;
    button.querySelector('.progress').style.width = `${progress * 100}%`;
    button.setAttribute('aria-label', `Ô ${index + 1}${plot ? ', ' + CROPS[plot.crop].name : ''}: ${label}`);
    button.title = plot ? `${CROPS[plot.crop].name} · ${label}` : label;
  });
}
function render() {
  $('#money').textContent = state.money.toLocaleString('vi-VN');
  $('#plot-count').textContent = `${state.unlocked} ô đất`;
  $('#harvest-count').textContent = `Đã thu hoạch: ${state.harvested} cây`;
  $('#expand').textContent = state.unlocked === 24 ? 'Đã mở toàn bộ khu vườn ✓' : `Mở thêm 4 ô · ${100 + (state.unlocked - 12) * 10} xu ↗`;
  $('#expand').disabled = state.unlocked === 24;
  document.querySelectorAll('.seed-row').forEach(row => {
    const id = row.dataset.crop;
    row.classList.toggle('selected', id === selected);
    row.querySelector('.seed-select').setAttribute('aria-pressed', String(id === selected));
    row.querySelector('.seed-detail').textContent = `${CROPS[id].seconds}s · Còn ${state.seeds[id]} hạt`;
    row.querySelector('.buy').disabled = state.money < CROPS[id].buy;
  });
  $('#inventory').innerHTML = Object.entries(CROPS).filter(([id]) => state.inventory[id]).map(([id, crop]) => `<div class="inventory-row"><span>${crop.icon} ${crop.name} × ${state.inventory[id]}</span><strong>${state.inventory[id] * crop.sell} xu</strong></div>`).join('') || '<p class="empty-basket">Giỏ của bạn đang trống.<br>Mùa thu hoạch đang chờ phía trước!</p>';
  $('#sell').textContent = `Bán tất cả · ${value(state)} xu`;
  $('#sell').disabled = value(state) === 0;
  renderField();
}
function perform(action) { toast(act(state, action)); save(); render(); }
function selectTool(next) {
  tool = next;
  document.querySelectorAll('[data-tool]').forEach(button => {
    button.classList.toggle('active', button.dataset.tool === tool);
    button.setAttribute('aria-pressed', String(button.dataset.tool === tool));
  });
  $('#tool-hint').textContent = { plant: 'Chọn hạt giống trong hộp, rồi bấm vào ô đất trống.', water: 'Bấm vào cây cần nước. Mỗi cây chỉ cần tưới một lần.', harvest: 'Bấm vào cây đã chín để đưa nông sản vào giỏ.' }[tool];
}
document.querySelectorAll('[data-tool]').forEach(button => button.addEventListener('click', () => selectTool(button.dataset.tool)));
$('#sell').addEventListener('click', () => perform({ type: 'sell' }));
$('#expand').addEventListener('click', () => perform({ type: 'expand' }));
$('#reset').addEventListener('click', () => $('#reset-dialog').showModal());
$('#cancel-reset').addEventListener('click', () => $('#reset-dialog').close());
$('#confirm-reset').addEventListener('click', () => {
  state = initial(); selected = 'carrot'; selectTool('plant'); save(); render();
  $('#reset-dialog').close(); toast('Một mùa vụ mới bắt đầu. Chúc bạn thu hoạch thật nhiều!');
});
window.addEventListener('storage', event => {
  if (event.key !== SAVE_KEY || !event.newValue) return;
  try { const incoming = JSON.parse(event.newValue); if (valid(incoming)) { state = incoming; render(); } } catch { /* Keep current state if another tab writes invalid data. */ }
});
document.addEventListener('visibilitychange', () => { if (!document.hidden) renderField(); });
render();
setInterval(renderField, 500);
if (loadNotice) toast(loadNotice);
