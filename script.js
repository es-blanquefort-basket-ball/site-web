
document.addEventListener('DOMContentLoaded',()=>{
  const burger=document.querySelector('.burger');
  const nav=document.querySelector('.navlinks');
  if(burger&&nav){burger.addEventListener('click',()=>nav.classList.toggle('open'))}
  const els=document.querySelectorAll('.reveal,.card,.stat');
  const io=new IntersectionObserver((entries)=>{entries.forEach(e=>{if(e.isIntersecting)e.target.classList.add('in')})},{threshold:.12});
  els.forEach(el=>io.observe(el));
});


// Compteur animé des chiffres clés
(() => {
  const counters = document.querySelectorAll('[data-count]');
  if (!counters.length) return;
  const animate = (el) => {
    if (el.dataset.done) return;
    el.dataset.done = '1';
    const target = parseInt(el.dataset.count, 10) || 0;
    const suffix = el.dataset.suffix || '';
    const duration = 1100;
    const start = performance.now();
    const step = (now) => {
      const progress = Math.min((now - start) / duration, 1);
      const eased = 1 - Math.pow(1 - progress, 3);
      el.textContent = Math.round(target * eased) + suffix;
      if (progress < 1) requestAnimationFrame(step);
    };
    requestAnimationFrame(step);
  };
  const io = new IntersectionObserver((entries) => {
    entries.forEach(entry => { if (entry.isIntersecting) animate(entry.target); });
  }, { threshold: .35 });
  counters.forEach(el => io.observe(el));
})();
