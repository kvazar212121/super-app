(function () {
  'use strict';

  const slides = Array.from(document.querySelectorAll('.slide'));
  const total = slides.length;
  let current = 0;

  const progressBar = document.getElementById('progressBar');
  const curNum = document.getElementById('curNum');
  const totNum = document.getElementById('totNum');
  const dotsWrap = document.getElementById('dots');

  totNum.textContent = total;

  // Nuqtalar (slayd indikatori)
  slides.forEach((s, i) => {
    const b = document.createElement('button');
    b.className = 'dot' + (i === 0 ? ' on' : '');
    b.title = s.dataset.title || ('Slayd ' + (i + 1));
    b.addEventListener('click', () => go(i));
    dotsWrap.appendChild(b);
  });
  const dots = Array.from(dotsWrap.children);

  function go(index) {
    if (index < 0 || index >= total || index === current) return;
    const prev = current;
    current = index;

    slides.forEach((s, i) => {
      s.classList.toggle('is-active', i === current);
      s.classList.toggle('is-prev', i === prev && i !== current);
    });
    dots.forEach((d, i) => d.classList.toggle('on', i === current));

    progressBar.style.width = (((current + 1) / total) * 100) + '%';
    curNum.textContent = current + 1;
  }

  function next() { go(current + 1); }
  function prev() { go(current - 1); }

  document.getElementById('nextBtn').addEventListener('click', next);
  document.getElementById('prevBtn').addEventListener('click', prev);

  // Klaviatura
  document.addEventListener('keydown', (e) => {
    switch (e.key) {
      case 'ArrowRight':
      case 'ArrowDown':
      case ' ':
      case 'PageDown':
        e.preventDefault(); next(); break;
      case 'ArrowLeft':
      case 'ArrowUp':
      case 'PageUp':
        e.preventDefault(); prev(); break;
      case 'Home': e.preventDefault(); go(0); break;
      case 'End': e.preventDefault(); go(total - 1); break;
      case 'f': case 'F':
        if (document.fullscreenElement) document.exitFullscreen();
        else document.documentElement.requestFullscreen();
        break;
    }
  });

  // G'ildirak bilan (debounce)
  let wheelLock = false;
  window.addEventListener('wheel', (e) => {
    if (wheelLock) return;
    if (Math.abs(e.deltaY) < 30) return;
    wheelLock = true;
    if (e.deltaY > 0) next(); else prev();
    setTimeout(() => { wheelLock = false; }, 700);
  }, { passive: true });

  // Touch (mobil)
  let touchX = null, touchY = null;
  window.addEventListener('touchstart', (e) => {
    touchX = e.touches[0].clientX; touchY = e.touches[0].clientY;
  }, { passive: true });
  window.addEventListener('touchend', (e) => {
    if (touchX === null) return;
    const dx = e.changedTouches[0].clientX - touchX;
    const dy = e.changedTouches[0].clientY - touchY;
    if (Math.abs(dx) > 60 && Math.abs(dx) > Math.abs(dy)) {
      if (dx < 0) next(); else prev();
    }
    touchX = touchY = null;
  }, { passive: true });

  // Boshlang'ich holat
  go(0);
})();
