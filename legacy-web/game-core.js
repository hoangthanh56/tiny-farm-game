(function (root) {
  'use strict';
  const CROPS = {
    carrot: { name: 'Cà rốt', icon: '🥕', seconds: 20, buy: 5, sell: 12 },
    wheat: { name: 'Lúa mì', icon: '🌾', seconds: 35, buy: 8, sell: 20 },
    tomato: { name: 'Cà chua', icon: '🍅', seconds: 60, buy: 15, sell: 38 },
    pumpkin: { name: 'Bí ngô', icon: '🎃', seconds: 90, buy: 25, sell: 65 }
  };
  const ids = Object.keys(CROPS);
  const counts = () => Object.fromEntries(ids.map(id => [id, 0]));
  const initial = () => ({ version: 1, money: 80, unlocked: 12, harvested: 0,
    seeds: { carrot: 6, wheat: 3, tomato: 0, pumpkin: 0 }, inventory: counts(), plots: Array(24).fill(null) });
  const ready = (plot, now) => !!plot && plot.wateredAt !== null && now - plot.wateredAt >= CROPS[plot.crop].seconds * 1000;
  const value = state => ids.reduce((sum, id) => sum + state.inventory[id] * CROPS[id].sell, 0);
  function valid(state) {
    const count = n => Number.isSafeInteger(n) && n >= 0;
    return !!state && state.version === 1 && count(state.money) && count(state.harvested)
      && [12, 16, 20, 24].includes(state.unlocked)
      && [state.seeds, state.inventory].every(bag => bag && ids.every(id => count(bag[id])))
      && Array.isArray(state.plots) && state.plots.length === 24
      && state.plots.every((p, i) => p === null || (i < state.unlocked && p && ids.includes(p.crop)
        && (p.wateredAt === null || (Number.isFinite(p.wateredAt) && p.wateredAt >= 0))));
  }
  function act(state, action, now = Date.now()) {
    const crop = CROPS[action.crop];
    if (action.type === 'buy') {
      if (!crop) return 'Hạt giống không hợp lệ.';
      if (state.money < crop.buy) return 'Bạn chưa đủ xu. Hãy thu hoạch và bán nông sản nhé!';
      state.money -= crop.buy; state.seeds[action.crop]++;
      return `Đã mua 1 hạt ${crop.name.toLowerCase()} · −${crop.buy} xu.`;
    }
    if (action.type === 'sell') {
      const total = value(state);
      if (!total) return 'Giỏ đang trống. Hãy thu hoạch cây đã chín nhé!';
      state.money += total; state.inventory = counts();
      return `Đã bán nông sản · +${total} xu!`;
    }
    if (action.type === 'expand') {
      if (state.unlocked === 24) return 'Bạn đã mở toàn bộ khu vườn!';
      const price = 100 + (state.unlocked - 12) * 10;
      if (state.money < price) return `Cần ${price} xu để mở thêm 4 ô đất.`;
      state.money -= price; state.unlocked += 4;
      return 'Khu vườn đã có thêm 4 ô đất mới!';
    }
    const index = action.index;
    if (!Number.isInteger(index) || index < 0 || index >= state.unlocked) return 'Hãy mở rộng khu vườn để sử dụng ô đất này.';
    const plot = state.plots[index];
    if (action.type === 'plant') {
      if (plot) return 'Ô đất này đã có cây. Hãy tưới nước hoặc thu hoạch nhé!';
      if (!crop || !state.seeds[action.crop]) return 'Bạn đã hết hạt giống loại này. Mua thêm trong hộp hạt giống nhé!';
      state.seeds[action.crop]--; state.plots[index] = { crop: action.crop, wateredAt: null };
      return `Đã gieo ${crop.name.toLowerCase()}. Nhớ chọn 💧 để tưới nước!`;
    }
    if (!plot) return 'Ô đất còn trống. Hãy gieo hạt trước nhé!';
    if (action.type === 'water') {
      if (plot.wateredAt !== null) return ready(plot, now) ? 'Cây đã chín, hãy thu hoạch!' : 'Cây đã đủ nước và đang lớn lên.';
      plot.wateredAt = now;
      return `Đã tưới nước! ${CROPS[plot.crop].name} sẽ chín sau ${CROPS[plot.crop].seconds} giây.`;
    }
    if (action.type === 'harvest') {
      if (!ready(plot, now)) return plot.wateredAt === null ? 'Cây cần được tưới nước trước khi lớn.' : 'Cây chưa chín. Chờ thêm một chút nhé!';
      state.inventory[plot.crop]++; state.harvested++; state.plots[index] = null;
      return `Đã thu hoạch ${CROPS[plot.crop].icon} ${CROPS[plot.crop].name.toLowerCase()}! Bán trong giỏ để nhận xu.`;
    }
    return 'Hãy chọn công cụ để chăm sóc vườn.';
  }
  const api = { CROPS, initial, ready, value, valid, act };
  if (typeof module !== 'undefined' && module.exports) module.exports = api;
  else root.Farm = api;
})(typeof globalThis !== 'undefined' ? globalThis : this);
