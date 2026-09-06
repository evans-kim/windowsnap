'use strict';
const windowPreview = document.querySelector('#sample-window');
const caption = document.querySelector('#demo-caption');
const layouts = {
  'left-half': ['←', '한 번으로, 딱 절반.'],
  'left-third': ['← × 2', '0.8초 안에 한 번 더, 1/3.'],
  'right-half': ['→', '오른쪽으로, 딱 절반.'],
  'maximize': ['← 다음 ↑', '0.8초 안에 이어서, 넓게.']
};
document.querySelectorAll('[data-layout][type="button"]').forEach(button => {
  button.addEventListener('click', () => {
    const layout = button.dataset.layout;
    windowPreview.dataset.layout = layout;
    document.querySelectorAll('.demo-controls button').forEach(item => {
      item.setAttribute('aria-pressed', String(item === button));
    });
    caption.replaceChildren();
    ['⌥', '⌘', layouts[layout][0]].forEach((key, index) => {
      if (index) caption.append(' + ');
      const element = document.createElement('kbd');
      element.textContent = key;
      caption.append(element);
    });
    const label = document.createElement('span');
    label.textContent = layouts[layout][1];
    caption.append(label);
  });
});
